import json
from dataclasses import dataclass, field
from typing import Dict, Any, Optional

from backend.app.services.session_service import (
    DatabaseSessionRepository,
    get_or_create_session_record,
    reset_session_record,
    save_session_record,
)

from .constants import WELCOME


@dataclass
class Session:
    session_id: str
    state: str = WELCOME
    language: str = "en"
    user_id: Optional[int] = None
    is_authenticated: bool = False
    current_intent: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)


class InMemorySessionStore:
    def __init__(self):
        self.sessions: Dict[str, Session] = {}

    def get_or_create(self, session_id: str) -> Session:
        if session_id not in self.sessions:
            self.sessions[session_id] = Session(session_id=session_id)
        return self.sessions[session_id]

    def save(self, session: Session):
        self.sessions[session.session_id] = session

    def reset(self, session_id: str):
        self.sessions[session_id] = Session(session_id=session_id)


class DatabaseSessionStore:
    def _from_record(self, record) -> Session:
        return Session(
            session_id=record.session_id,
            state=record.state,
            language=record.language,
            user_id=record.user_id,
            is_authenticated=record.is_authenticated,
            current_intent=record.current_intent,
            data=json.loads(record.data_json or "{}"),
        )

    def get_or_create(self, session_id: str) -> Session:
        with DatabaseSessionRepository() as db:
            record = get_or_create_session_record(db, session_id, WELCOME)
            return self._from_record(record)

    def save(self, session: Session):
        with DatabaseSessionRepository() as db:
            save_session_record(
                db,
                session_id=session.session_id,
                state=session.state,
                language=session.language,
                user_id=session.user_id,
                is_authenticated=session.is_authenticated,
                current_intent=session.current_intent,
                data=session.data,
            )

    def reset(self, session_id: str):
        with DatabaseSessionRepository() as db:
            reset_session_record(db, session_id, WELCOME)
