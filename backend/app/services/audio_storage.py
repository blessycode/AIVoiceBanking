from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile

from ..config import UPLOAD_ROOT


def save_upload(session_id: str, upload: UploadFile) -> Path:
    suffix = Path(upload.filename or "voice_turn.wav").suffix or ".wav"
    session_dir = UPLOAD_ROOT / session_id
    session_dir.mkdir(parents=True, exist_ok=True)
    target_path = session_dir / f"{uuid4().hex}{suffix}"

    with target_path.open("wb") as buffer:
        while True:
            chunk = upload.file.read(1024 * 1024)
            if not chunk:
                break
            buffer.write(chunk)

    return target_path
