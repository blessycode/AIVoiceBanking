#!/usr/bin/env python3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
repo_root_str = str(REPO_ROOT)
if repo_root_str not in sys.path:
    sys.path.insert(0, repo_root_str)

from backend.app.database.db import SessionLocal
from backend.app.services.voice_log_service import export_retraining_manifest


def main() -> None:
    with SessionLocal() as db:
        info = export_retraining_manifest(db)

    print("ASR retraining manifest exported")
    for key, value in info.items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
