from faster_whisper import WhisperModel

from ..config import ASR_COMPUTE_TYPE, ASR_MODEL_SIZE


MODEL_NAME = "baseline_faster_whisper"

_model = None


def get_model() -> WhisperModel:
    global _model
    if _model is None:
        _model = WhisperModel(
            ASR_MODEL_SIZE,
            device="cpu",
            compute_type=ASR_COMPUTE_TYPE,
        )
    return _model


def transcribe_audio(file_path: str) -> dict:
    model = get_model()

    segments, info = model.transcribe(
        file_path,
        vad_filter=True,
        beam_size=5,
        task="transcribe",
    )

    text = " ".join(segment.text.strip() for segment in segments).strip()
    return {
        "text": text,
        "language": getattr(info, "language", None),
        "duration": getattr(info, "duration", None),
        "model_name": MODEL_NAME,
    }
