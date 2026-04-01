from backend.database.db import SessionLocal
from backend.database.models import Account


def get_balance(user_id):
    db = SessionLocal()
    account = db.query(Account).filter(Account.user_id == user_id).first()
    return account.balance