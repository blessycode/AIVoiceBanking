from datetime import datetime

from sqlalchemy import inspect

from .db import Base, DATABASE_PATH, engine
from . import models  # noqa: F401


REQUIRED_COLUMNS = {
    "users": {"id", "name", "phone", "language", "password_hash"},
    "accounts": {"id", "user_id", "balance", "currency"},
    "transactions": {
        "id",
        "user_id",
        "transaction_type",
        "amount",
        "status",
        "balance_before",
        "balance_after",
    },
    "voice_logs": {"id", "session_id", "transcript", "agent_state", "response_text"},
    "sessions": {"session_id", "state", "language", "is_authenticated", "data_json"},
}


def _schema_is_compatible() -> bool:
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    for table_name, required_columns in REQUIRED_COLUMNS.items():
        if table_name not in existing_tables:
            continue

        existing_columns = {
            column["name"] for column in inspector.get_columns(table_name)
        }
        if not required_columns.issubset(existing_columns):
            return False

    return True


def _backup_incompatible_database() -> None:
    if not DATABASE_PATH.exists():
        return

    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    backup_path = DATABASE_PATH.with_name(
        f"{DATABASE_PATH.stem}_legacy_{timestamp}{DATABASE_PATH.suffix}"
    )
    engine.dispose()
    DATABASE_PATH.replace(backup_path)


def init_db() -> None:
    if not _schema_is_compatible():
        _backup_incompatible_database()
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    init_db()
