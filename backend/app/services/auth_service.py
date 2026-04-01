import hashlib
import hmac

from sqlalchemy.orm import Session

from ..database.models import User
from .user_service import find_user_by_phone


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def verify_password(password: str, password_hash: str) -> bool:
    return hmac.compare_digest(hash_password(password), password_hash)


def login_user(db: Session, *, phone: str, password: str) -> User | None:
    user = find_user_by_phone(db, phone)
    if user is None:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
