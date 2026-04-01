from backend.database.db import SessionLocal
from backend.database.models import Account, Transaction


def send_money(user_id, recipient, amount):
    db = SessionLocal()

    account = db.query(Account).filter(Account.user_id == user_id).first()

    if account.balance < amount:
        return {"success": False, "message": "Insufficient funds"}

    account.balance -= amount

    tx = Transaction(
        user_id=user_id,
        type="SEND",
        amount=amount,
        recipient=recipient
    )

    db.add(tx)
    db.commit()

    return {"success": True}


def pay_bill(user_id, biller, amount):
    db = SessionLocal()

    account = db.query(Account).filter(Account.user_id == user_id).first()

    if account.balance < amount:
        return {"success": False}

    account.balance -= amount

    tx = Transaction(
        user_id=user_id,
        type="BILL",
        amount=amount,
        recipient=biller
    )

    db.add(tx)
    db.commit()

    return {"success": True}


def buy_airtime(user_id, amount):
    db = SessionLocal()

    account = db.query(Account).filter(Account.user_id == user_id).first()

    if account.balance < amount:
        return {"success": False}

    account.balance -= amount

    tx = Transaction(
        user_id=user_id,
        type="AIRTIME",
        amount=amount
    )

    db.add(tx)
    db.commit()

    return {"success": True}