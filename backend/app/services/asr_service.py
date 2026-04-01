import logging
import sys
from dataclasses import dataclass
from pathlib import Path


logger = logging.getLogger(__name__)


class ASRServiceError(RuntimeError):
    """Raised when the ASR integration cannot process an audio file."""


@dataclass
class ASRResult:
    transcript: str
    language: str
    normalized_audio_path: str | None = None
    model_name: str | None = None


def _resolve_asr_root() -> Path:
    repo_root = Path(__file__).resolve().parents[3]
    candidates = [repo_root / "ASR ", repo_root / "ASR"]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise ASRServiceError("ASR module directory was not found.")


def _load_transcriber():
    asr_root = _resolve_asr_root()
    asr_root_str = str(asr_root)
    if asr_root_str not in sys.path:
        sys.path.insert(0, asr_root_str)

    try:
        from inference.transcribe_mobile import transcribe_mobile_audio
    except Exception as exc:  # pragma: no cover - import failure depends on env
        raise ASRServiceError(f"Unable to import ASR module: {exc}") from exc

    return transcribe_mobile_audio


def transcribe_audio_file(audio_file_path: str) -> ASRResult:
    transcribe_mobile_audio = _load_transcriber()

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
