from sqlalchemy.orm import Session

from ..database.models import Account, User


class UserAlreadyExistsError(ValueError):
    """Raised when a profile already exists for the provided phone number."""


def create_user(
    db: Session,
    *,
    name: str,
    phone: str,
    language: str,
    password_hash: str,
    opening_balance: float = 100.0,
) -> User:
    existing_user = db.query(User).filter(User.phone == phone).first()
    if existing_user:
        raise UserAlreadyExistsError("A profile already exists for that phone number.")

    user = User(
        name=name,
        phone=phone,
        language=language,
        password_hash=password_hash,
    )
    db.add(user)
    db.flush()

    account = Account(user_id=user.id, balance=opening_balance)
    db.add(account)
    db.commit()
    db.refresh(user)
    return user


def find_user_by_phone(db: Session, phone: str) -> User | None:
    return db.query(User).filter(User.phone == phone).first()


def get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()


def find_user_by_name_or_phone(db: Session, recipient: str) -> User | None:
    return (
        db.query(User)
        .filter((User.phone == recipient) | (User.name.ilike(f"%{recipient}%")))
        .first()
    )
