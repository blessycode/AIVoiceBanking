import logging
import threading
from dataclasses import dataclass


logger = logging.getLogger(__name__)

_warmup_lock = threading.Lock()
_warmup_state = "not_started"


class ASRServiceError(RuntimeError):
    """Raised when the ASR integration cannot process an audio file."""


@dataclass
class ASRResult:
    transcript: str
    language: str
    normalized_audio_path: str | None = None
    model_name: str | None = None


def _load_runtime():
    try:
        from ..asr_runtime.transcribe_baseline import get_model
        from ..asr_runtime.transcribe_mobile import transcribe_mobile_audio
    except Exception as exc:  # pragma: no cover - import failure depends on env
        raise ASRServiceError(f"Unable to import ASR runtime: {exc}") from exc

    return transcribe_mobile_audio, get_model


def warmup_asr_async() -> None:
    global _warmup_state

    with _warmup_lock:
        if _warmup_state in {"in_progress", "ready"}:
            return
        _warmup_state = "in_progress"

    def _runner() -> None:
        global _warmup_state

        try:
            _, get_model = _load_runtime()
            get_model()
        except Exception:  # pragma: no cover - depends on runtime env
            logger.exception("ASR warmup failed")
            with _warmup_lock:
                _warmup_state = "failed"
            return

        logger.info("ASR warmup completed")
        with _warmup_lock:
            _warmup_state = "ready"

    thread = threading.Thread(
        target=_runner,
        name="asr-warmup",
        daemon=True,
    )
    thread.start()


def transcribe_audio_file(audio_file_path: str) -> ASRResult:
    transcribe_mobile_audio, _ = _load_runtime()

    try:
        result = transcribe_mobile_audio(audio_file_path, source="backend_voice_agent")
    except FileNotFoundError as exc:
        raise ASRServiceError(f"Audio file does not exist: {audio_file_path}") from exc
    except Exception as exc:  # pragma: no cover - runtime depends on model/ffmpeg env
        logger.exception("ASR transcription failed for %s", audio_file_path)
        return ASRResult(transcript="", language="en")

    transcript = (result.get("text") or "").strip()
    language = result.get("language") or "en"
    normalized_path = result.get("normalized_path")
    model_name = result.get("model_name")

    logger.info(
        "ASR completed",
        extra={
            "audio_file_path": audio_file_path,
            "normalized_audio_path": normalized_path,
            "language": language,
            "transcript": transcript,
            "model_name": model_name,
        },
    )

    return ASRResult(
        transcript=transcript,
        language=language,
        normalized_audio_path=normalized_path,
        model_name=model_name,
    )
