from backend.database.db import SessionLocal
from backend.database.models import User, Account


def create_user(name, phone, language, password):
    db = SessionLocal()

    user = User(
        name=name,
        phone=phone,
        language=language,
        password=password
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    account = Account(user_id=user.id, balance=100.0)
    db.add(account)
    db.commit()

    return user