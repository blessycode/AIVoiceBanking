import csv
import logging
from pathlib import Path

from sqlalchemy.orm import Session

from ..config import ASR_MIN_CORRECTIONS_FOR_RETRAIN, ASR_RETRAIN_MANIFEST
from ..database.models import VoiceLog


logger = logging.getLogger(__name__)


def log_voice_turn(
    db: Session,
    *,
    session_id: str,
    user_id: int | None,
    audio_file_path: str | None,
    normalized_audio_path: str | None,
    transcript: str,
    language: str,
    agent_state: str,
    response_text: str,
    asr_model_name: str | None = None,
    transaction_result: str | None = None,
) -> VoiceLog:
    record = VoiceLog(
        session_id=session_id,
        user_id=user_id,
        audio_file_path=audio_file_path,
        normalized_audio_path=normalized_audio_path,
        transcript=transcript,
        language=language,
        agent_state=agent_state,
        response_text=response_text,
        asr_model_name=asr_model_name,
        transaction_result=transaction_result,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    logger.info(
        "Voice turn logged",
        extra={
            "session_id": session_id,
            "agent_state": agent_state,
            "language": language,
            "audio_file_path": audio_file_path,
        },
    )
    return record


def get_voice_log(db: Session, voice_log_id: int) -> VoiceLog | None:
    return db.get(VoiceLog, voice_log_id)


def apply_transcript_correction(
    db: Session,
    *,
    voice_log_id: int,
    corrected_transcript: str,
) -> VoiceLog | None:
    record = get_voice_log(db, voice_log_id)
    if record is None:
        return None

    cleaned_transcript = corrected_transcript.strip()
    if not cleaned_transcript:
        raise ValueError("corrected_transcript must not be empty.")

    record.corrected_transcript = cleaned_transcript
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def _build_retraining_rows(db: Session) -> tuple[list[dict], int]:
    corrected_logs = (
        db.query(VoiceLog)
        .filter(VoiceLog.corrected_transcript.is_not(None))
        .order_by(VoiceLog.created_at.asc())
        .all()
    )

    rows: list[dict] = []
    corrected_count = 0
    for record in corrected_logs:
        corrected_text = (record.corrected_transcript or "").strip()
        if not corrected_text:
            continue

        corrected_count += 1
        candidate_path = record.normalized_audio_path or record.audio_file_path
        if not candidate_path:
            continue

        if not Path(candidate_path).exists():
            logger.warning(
                "Skipping retraining sample with missing audio file",
                extra={"voice_log_id": record.id, "path": candidate_path},
            )
            continue

        rows.append(
            {
                "voice_log_id": record.id,
                "path": candidate_path,
                "text": corrected_text,
                "lang": record.language,
            }
        )

    return rows, corrected_count


def export_retraining_manifest(db: Session) -> dict:
    rows, corrected_count = _build_retraining_rows(db)
    ASR_RETRAIN_MANIFEST.parent.mkdir(parents=True, exist_ok=True)

    with ASR_RETRAIN_MANIFEST.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["voice_log_id", "path", "text", "lang"],
        )
        writer.writeheader()
        writer.writerows(rows)

    return {
        "manifest_path": str(ASR_RETRAIN_MANIFEST),
        "exported_samples": len(rows),
        "corrected_samples": corrected_count,
        "minimum_recommended_samples": ASR_MIN_CORRECTIONS_FOR_RETRAIN,
        "ready_for_retraining": len(rows) >= ASR_MIN_CORRECTIONS_FOR_RETRAIN,
    }
