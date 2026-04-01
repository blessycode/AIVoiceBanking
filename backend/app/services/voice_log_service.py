import logging

from sqlalchemy.orm import Session

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
