from sqlalchemy.orm import Session

from ..database.models import Account


def get_account_by_user_id(db: Session, user_id: int) -> Account | None:
    return db.query(Account).filter(Account.user_id == user_id).first()


def get_balance(db: Session, user_id: int) -> float:
    account = get_account_by_user_id(db, user_id)
    if account is None:
        raise ValueError("Account not found.")
    return float(account.balance)
