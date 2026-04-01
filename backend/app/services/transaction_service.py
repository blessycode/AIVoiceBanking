from sqlalchemy.orm import Session

from ..database.models import Transaction
from .account_service import get_account_by_user_id
from .user_service import find_user_by_name_or_phone


def _ensure_positive_amount(amount: float) -> None:
    if amount <= 0:
        raise ValueError("Amount must be greater than zero.")


def _debit_account(account, amount: float) -> tuple[float, float]:
    balance_before = float(account.balance)
    if balance_before < amount:
        raise ValueError("Insufficient funds.")
    account.balance = balance_before - amount
    return balance_before, float(account.balance)


def send_money(db: Session, *, user_id: int, recipient: str, amount: float) -> dict:
    _ensure_positive_amount(amount)
    sender_account = get_account_by_user_id(db, user_id)
    if sender_account is None:
        raise ValueError("Sender account not found.")

    balance_before, balance_after = _debit_account(sender_account, amount)
    recipient_user = find_user_by_name_or_phone(db, recipient)
    if recipient_user and recipient_user.id != user_id:
        recipient_account = get_account_by_user_id(db, recipient_user.id)
        if recipient_account is not None:
            recipient_account.balance = float(recipient_account.balance) + amount

    transaction = Transaction(
        user_id=user_id,
        transaction_type="SEND_MONEY",
        amount=amount,
        recipient=recipient,
        reference="voice_transfer",
        status="SUCCESS",
        balance_before=balance_before,
        balance_after=balance_after,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return {
        "success": True,
        "message": "Transaction successful.",
        "transaction_id": transaction.id,
        "balance_after": balance_after,
    }


def pay_bill(db: Session, *, user_id: int, biller: str, amount: float) -> dict:
    _ensure_positive_amount(amount)
    account = get_account_by_user_id(db, user_id)
    if account is None:
        raise ValueError("Account not found.")

    balance_before, balance_after = _debit_account(account, amount)
    transaction = Transaction(
        user_id=user_id,
        transaction_type="PAY_BILL",
        amount=amount,
        recipient=biller,
        reference="voice_bill_payment",
        status="SUCCESS",
        balance_before=balance_before,
        balance_after=balance_after,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return {
        "success": True,
        "message": "Bill payment successful.",
        "transaction_id": transaction.id,
        "balance_after": balance_after,
    }


def buy_airtime(db: Session, *, user_id: int, amount: float) -> dict:
    _ensure_positive_amount(amount)
    account = get_account_by_user_id(db, user_id)
    if account is None:
        raise ValueError("Account not found.")

    balance_before, balance_after = _debit_account(account, amount)
    transaction = Transaction(
        user_id=user_id,
        transaction_type="BUY_AIRTIME",
        amount=amount,
        recipient=None,
        reference="voice_airtime_purchase",
        status="SUCCESS",
        balance_before=balance_before,
        balance_after=balance_after,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return {
        "success": True,
        "message": "Airtime purchase successful.",
        "transaction_id": transaction.id,
        "balance_after": balance_after,
    }


def list_recent_transactions(
    db: Session,
    *,
    user_id: int,
    limit: int = 5,
) -> list[Transaction]:
    return (
        db.query(Transaction)
        .filter(Transaction.user_id == user_id)
        .order_by(Transaction.created_at.desc())
        .limit(limit)
        .all()
    )
