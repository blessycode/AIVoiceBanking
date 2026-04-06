from pathlib import Path

from ..config import ASR_NORMALIZED_ROOT
from .audio_utils import normalize_audio
from .log_utils import log_asr_result
from .transcribe_baseline import transcribe_audio


def transcribe_mobile_audio(raw_file_path: str, source: str = "backend_voice_agent") -> dict:
    normalized_path = ASR_NORMALIZED_ROOT / f"{Path(raw_file_path).stem}_mobile.wav"
    normalize_audio(raw_file_path, str(normalized_path))

    result = transcribe_audio(str(normalized_path))

    log_asr_result(
        audio_path=raw_file_path,
        normalized_path=str(normalized_path),
        predicted_transcript=result["text"],
        language=result["language"] or "",
        model_name=result["model_name"],
        source=source,
    )

    result["normalized_path"] = str(normalized_path)
    return result
