import logging
from dataclasses import dataclass


logger = logging.getLogger(__name__)


class ASRServiceError(RuntimeError):
    """Raised when the ASR integration cannot process an audio file."""


@dataclass
class ASRResult:
    transcript: str
    language: str
    normalized_audio_path: str | None = None
    model_name: str | None = None


def transcribe_audio_file(audio_file_path: str) -> ASRResult:
    try:
        from ..asr_runtime.transcribe_mobile import transcribe_mobile_audio
    except Exception as exc:  # pragma: no cover - import failure depends on env
        raise ASRServiceError(f"Unable to import ASR runtime: {exc}") from exc

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
