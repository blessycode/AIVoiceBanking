import csv
from datetime import datetime

from ..config import ASR_LOG_FILE


def log_asr_result(
    audio_path: str,
    normalized_path: str,
    predicted_transcript: str,
    language: str,
    model_name: str,
    source: str,
) -> None:
    ASR_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    exists = ASR_LOG_FILE.exists()

    with ASR_LOG_FILE.open("a", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        if not exists:
            writer.writerow(
                [
                    "timestamp",
                    "audio_path",
                    "normalized_path",
                    "predicted_transcript",
                    "corrected_transcript",
                    "language",
                    "model_name",
                    "source",
                ]
            )

        writer.writerow(
            [
                datetime.utcnow().isoformat(),
                audio_path,
                normalized_path,
                predicted_transcript,
                "",
                language,
                model_name,
                source,
            ]
        )
