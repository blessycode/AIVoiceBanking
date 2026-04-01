import json

from sqlalchemy.orm import Session

from ..database.db import SessionLocal
from ..database.models import AgentSession


def get_session_record(db: Session, session_id: str) -> AgentSession | None:
    return db.get(AgentSession, session_id)


def get_or_create_session_record(db: Session, session_id: str, default_state: str) -> AgentSession:
    session = get_session_record(db, session_id)
    if session is None:
        session = AgentSession(session_id=session_id, state=default_state)
        db.add(session)
        db.commit()
        db.refresh(session)
    return session


def save_session_record(
    db: Session,
    *,
    session_id: str,
    state: str,
    language: str,
    user_id: int | None,
    is_authenticated: bool,
    current_intent: str | None,
    data: dict,
) -> AgentSession:
    record = get_or_create_session_record(db, session_id, state)
    record.state = state
    record.language = language
    record.user_id = user_id
    record.is_authenticated = is_authenticated
    record.current_intent = current_intent
    record.data_json = json.dumps(data)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def reset_session_record(db: Session, session_id: str, default_state: str) -> AgentSession:
    record = get_or_create_session_record(db, session_id, default_state)
    record.state = default_state
    record.language = "en"
    record.user_id = None
    record.is_authenticated = False
    record.current_intent = None
    record.data_json = "{}"
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


class DatabaseSessionRepository:
    def __enter__(self) -> Session:
        self.db = SessionLocal()
        return self.db

    def __exit__(self, exc_type, exc, tb) -> None:
        self.db.close()
