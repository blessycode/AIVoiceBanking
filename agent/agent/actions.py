from backend.app.database.db import SessionLocal
from backend.app.services.account_service import get_balance as get_user_balance
from backend.app.services.auth_service import hash_password, login_user
from backend.app.services.transaction_service import buy_airtime as buy_airtime_service
from backend.app.services.transaction_service import pay_bill as pay_bill_service
from backend.app.services.transaction_service import send_money as send_money_service
from backend.app.services.user_service import UserAlreadyExistsError, create_user


def create_profile(name: str, phone: str, language: str, password: str):
    with SessionLocal() as db:
        try:
            user = create_user(
                db,
                name=name,
                phone=phone,
                language=language,
                password_hash=hash_password(password),
            )
        except UserAlreadyExistsError as exc:
            return {"success": False, "message": str(exc)}

        return {
            "success": True,
            "user_id": user.id,
            "name": user.name,
            "phone": user.phone,
            "language": user.language,
        }


def login(phone: str, password: str):
    with SessionLocal() as db:
        user = login_user(db, phone=phone, password=password)
        if not user:
            return None

        return {
            "user_id": user.id,
            "name": user.name,
            "phone": user.phone,
            "language": user.language,
        }


def get_balance(user_id: int) -> float:
    with SessionLocal() as db:
        return float(get_user_balance(db, user_id))


def send_money(user_id: int, recipient: str, amount: float):
    with SessionLocal() as db:
        try:
            return send_money_service(db, user_id=user_id, recipient=recipient, amount=amount)
        except ValueError as exc:
            return {"success": False, "message": str(exc)}


def pay_bill(user_id: int, biller: str, amount: float):
    with SessionLocal() as db:
        try:
            return pay_bill_service(db, user_id=user_id, biller=biller, amount=amount)
        except ValueError as exc:
            return {"success": False, "message": str(exc)}


def buy_airtime(user_id: int, amount: float):
    with SessionLocal() as db:
        try:
            return buy_airtime_service(db, user_id=user_id, amount=amount)
        except ValueError as exc:
            return {"success": False, "message": str(exc)}
