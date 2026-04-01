from backend.database.db import SessionLocal
from backend.database.models import User


def login_user(phone, password):
    db = SessionLocal()

    user = db.query(User).filter(User.phone == phone).first()

    if not user:
        return None

    if user.password != password:
        return None

    return user