import os
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = REPO_ROOT / "backend"


def _resolve_storage_root() -> Path:
    raw_value = os.getenv("APP_STORAGE_ROOT")
    if not raw_value:
        return BACKEND_ROOT

    candidate = Path(raw_value).expanduser()
    if not candidate.is_absolute():
        candidate = BACKEND_ROOT / candidate
    return candidate.resolve()


def _normalize_database_url(raw_value: str | None, fallback_path: Path) -> str:
    if not raw_value:
        return f"sqlite:///{fallback_path}"

    if raw_value.startswith("postgres://"):
        return raw_value.replace("postgres://", "postgresql+psycopg://", 1)

    if raw_value.startswith("postgresql://") and "+psycopg" not in raw_value:
        return raw_value.replace("postgresql://", "postgresql+psycopg://", 1)

    return raw_value


def _split_csv(raw_value: str | None, default: list[str]) -> list[str]:
    if not raw_value:
        return default

    values = [item.strip() for item in raw_value.split(",")]
    return [item for item in values if item] or default


APP_STORAGE_ROOT = _resolve_storage_root()
LOCAL_DATABASE_PATH = APP_STORAGE_ROOT / "voice_bank.db"
DATABASE_URL = _normalize_database_url(os.getenv("DATABASE_URL"), LOCAL_DATABASE_PATH)
DATABASE_IS_SQLITE = DATABASE_URL.startswith("sqlite")
UPLOAD_ROOT = APP_STORAGE_ROOT / "uploads"
ASR_STORAGE_ROOT = APP_STORAGE_ROOT / "asr"
ASR_NORMALIZED_ROOT = ASR_STORAGE_ROOT / "normalized"
ASR_LOG_FILE = ASR_STORAGE_ROOT / "asr_predictions.csv"
ASR_MANIFEST_ROOT = ASR_STORAGE_ROOT / "manifests"
ASR_RETRAIN_MANIFEST = ASR_MANIFEST_ROOT / "retrain_manifest.csv"
ASR_MODEL_SIZE = os.getenv("ASR_MODEL_SIZE", "base")
ASR_COMPUTE_TYPE = os.getenv("ASR_COMPUTE_TYPE", "int8")
ASR_MIN_CORRECTIONS_FOR_RETRAIN = int(os.getenv("ASR_MIN_CORRECTIONS_FOR_RETRAIN", "25"))
CORS_ALLOW_ORIGINS = _split_csv(os.getenv("CORS_ALLOW_ORIGINS"), ["*"])
