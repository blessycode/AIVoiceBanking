from .constants import *
from .session_store import DatabaseSessionStore, InMemorySessionStore
from .language_utils import detect_language, normalize_text
from .intent_router import route_intent
from .entity_extractor import (
    extract_name_or_recipient,
    extract_phone,
    extract_amount,
    extract_biller,
    extract_language_choice,
    extract_password,
)
from .prompts import speak
from .actions import create_profile, login, get_balance, send_money, pay_bill, buy_airtime


class VoiceBankingAgent:
    def __init__(self, store=None):
        self.store = store or DatabaseSessionStore()

    def process(self, session_id: str, transcript: str):
        session = self.store.get_or_create(session_id)

        text = normalize_text(transcript)
        detected_lang = detect_language(text)
        if session.state in {WELCOME, AWAITING_LANGUAGE_CHOICE} and session.language == "en" and detected_lang != "en":
            session.language = detected_lang

        if session.state == WELCOME:
            session.state = AWAITING_LANGUAGE_CHOICE
            self.store.save(session)
            return self._response(session, speak("en", "welcome"))

        if session.state == AWAITING_LANGUAGE_CHOICE:
            lang_choice = extract_language_choice(text)
            if not lang_choice:
                return self._response(session, speak("en", "ask_language"))
            session.language = lang_choice
            session.data["language"] = lang_choice
            session.data["language_selected"] = True
            session.state = AWAITING_ENTRY_CHOICE
            self.store.save(session)
            return self._response(session, speak(session.language, "entry_choice"))

        intent = route_intent(text)

        # global cancel
        if intent == "CANCEL":
            was_awaiting_language = session.state == AWAITING_LANGUAGE_CHOICE
            session.current_intent = None
            session.data = {}
            if session.is_authenticated:
                session.state = AUTHENTICATED_HOME
            elif was_awaiting_language:
                session.state = AWAITING_LANGUAGE_CHOICE
            else:
                session.data["language"] = session.language
                session.data["language_selected"] = True
                session.state = AWAITING_ENTRY_CHOICE
            self.store.save(session)
            return self._response(session, speak(session.language, "cancelled"))

        # global logout
        if intent == "LOGOUT":
            session.is_authenticated = False
            session.user_id = None
            session.current_intent = None
            session.data = {}
            session.state = AWAITING_ENTRY_CHOICE
            self.store.save(session)
            return self._response(session, speak(session.language, "logout_success"))

        # ---------- entry choice ----------
        if session.state == AWAITING_ENTRY_CHOICE:
            if intent == "CREATE_PROFILE":
                session.data = {
                    "language": session.language,
                    "language_selected": True,
                }
                session.state = CREATE_PROFILE_NAME
                self.store.save(session)
                return self._response(session, speak(session.language, "ask_name"))

            if intent == "LOGIN":
                session.state = LOGIN_IDENTIFIER
                self.store.save(session)
                return self._response(session, speak(session.language, "ask_login_id"))

            return self._response(session, speak(session.language, "fallback"))

        # ---------- create profile ----------
        if session.state == CREATE_PROFILE_NAME:
            name = transcript.strip()
            session.data["name"] = name
            session.state = CREATE_PROFILE_PHONE
            self.store.save(session)
            return self._response(session, speak(session.language, "ask_phone"))

        if session.state == CREATE_PROFILE_PHONE:
            phone = extract_phone(text)
            if not phone:
                return self._response(session, speak(session.language, "fallback"))
            session.data["phone"] = phone
            session.data["language"] = session.language
            session.state = CREATE_PROFILE_PASSWORD
            self.store.save(session)
            return self._response(session, speak(session.language, "ask_password"))

        if session.state == CREATE_PROFILE_PASSWORD:
            password = extract_password(text)
            if not password:
                return self._response(session, speak(session.language, "fallback"))
            session.data["password"] = password
            session.state = CREATE_PROFILE_CONFIRM
            self.store.save(session)
            return self._response(
                session,
                speak(
                    session.language,
                    "confirm_profile",
                    name=session.data["name"],
                    phone=session.data["phone"],
                    language=session.data["language"],
                )
            )

        if session.state == CREATE_PROFILE_CONFIRM:
            if intent == "CONFIRM" or text == "confirm":
                user = create_profile(
                    name=session.data["name"],
                    phone=session.data["phone"],
                    language=session.data["language"],
                    password=session.data["password"]
                )
                if not user["success"]:
                    session.current_intent = None
                    session.data = {}
                    session.state = AWAITING_ENTRY_CHOICE
                    self.store.save(session)
                    return self._response(session, user["message"])
                session.user_id = user["user_id"]
                session.is_authenticated = True
                session.current_intent = None
                session.state = AUTHENTICATED_HOME
                session.data = {}
                self.store.save(session)
                return self._response(
                    session,
                    speak(session.language, "profile_created"),
                    transaction_result="PROFILE_CREATED",
                )

            return self._response(session, speak(session.language, "fallback"))

        # ---------- login ----------
        if session.state == LOGIN_IDENTIFIER:
            phone = extract_phone(text)
            if not phone:
                return self._response(session, speak(session.language, "fallback"))
            session.data["phone"] = phone
            session.state = LOGIN_PASSWORD
            self.store.save(session)
            return self._response(session, speak(session.language, "ask_login_password"))

        if session.state == LOGIN_PASSWORD:
            password = extract_password(text)
            if not password:
                return self._response(session, speak(session.language, "fallback"))

            user = login(session.data["phone"], password)
            if not user:
                session.data = {}
                session.state = AWAITING_ENTRY_CHOICE
                self.store.save(session)
                return self._response(session, speak(session.language, "invalid_login"))

            session.user_id = user["user_id"]
            session.is_authenticated = True
            session.language = user["language"]
            session.current_intent = None
            session.data = {}
            session.state = AUTHENTICATED_HOME
            self.store.save(session)
            return self._response(
                session,
                speak(session.language, "login_success"),
                transaction_result="LOGIN_SUCCESS",
            )

        # ---------- authenticated home ----------
        if session.state == AUTHENTICATED_HOME:
            if intent == "CHECK_BALANCE":
                balance = get_balance(session.user_id)
                return self._response(session, speak(session.language, "balance", balance=balance))

            if intent == "SEND_MONEY":
                session.current_intent = "SEND_MONEY"
                session.state = SEND_MONEY_RECIPIENT
                session.data = {}
                self.store.save(session)
                recipient = extract_name_or_recipient(text)
                amount = extract_amount(text)

                if recipient:
                    session.data["recipient"] = recipient
                    if amount:
                        session.data["amount"] = amount
                        session.state = SEND_MONEY_CONFIRM
                        self.store.save(session)
                        return self._response(
                            session,
                            speak(session.language, "confirm_send", amount=amount, recipient=recipient)
                        )
                    session.state = SEND_MONEY_AMOUNT
                    self.store.save(session)
                    return self._response(session, speak(session.language, "ask_amount"))

                return self._response(session, speak(session.language, "ask_recipient"))

            if intent == "PAY_BILL":
                session.current_intent = "PAY_BILL"
                session.state = PAY_BILL_TYPE
                session.data = {}
                self.store.save(session)

                biller = extract_biller(text)
                amount = extract_amount(text)

                if biller:
                    session.data["biller"] = biller
                    if amount:
                        session.data["amount"] = amount
                        session.state = PAY_BILL_CONFIRM
                        self.store.save(session)
                        return self._response(
                            session,
                            speak(session.language, "confirm_bill", amount=amount, biller=biller)
                        )
                    session.state = PAY_BILL_AMOUNT
                    self.store.save(session)
                    return self._response(session, speak(session.language, "ask_bill_amount"))

                return self._response(session, speak(session.language, "ask_bill_type"))

            if intent == "BUY_AIRTIME":
                session.current_intent = "BUY_AIRTIME"
                session.state = BUY_AIRTIME_AMOUNT
                session.data = {}
                self.store.save(session)

                amount = extract_amount(text)
                if amount:
                    session.data["amount"] = amount
                    session.state = BUY_AIRTIME_CONFIRM
                    self.store.save(session)
                    return self._response(session, speak(session.language, "confirm_airtime", amount=amount))

                return self._response(session, speak(session.language, "ask_airtime_amount"))

            return self._response(session, speak(session.language, "fallback"))

        # ---------- send money flow ----------
        if session.state == SEND_MONEY_RECIPIENT:
            recipient = extract_name_or_recipient(text)
            if not recipient:
                return self._response(session, speak(session.language, "fallback"))
            session.data["recipient"] = recipient
            session.state = SEND_MONEY_AMOUNT
            self.store.save(session)
            return self._response(session, speak(session.language, "ask_amount"))

        if session.state == SEND_MONEY_AMOUNT:
            amount = extract_amount(text)
            if amount is None:
                return self._response(session, speak(session.language, "fallback"))
            session.data["amount"] = amount
            session.state = SEND_MONEY_CONFIRM
            self.store.save(session)
            return self._response(
                session,
                speak(
                    session.language,
                    "confirm_send",
                    amount=session.data["amount"],
                    recipient=session.data["recipient"]
                )
            )

        if session.state == SEND_MONEY_CONFIRM:
            if intent == "CONFIRM" or text == "confirm":
                result = send_money(
                    user_id=session.user_id,
                    recipient=session.data["recipient"],
                    amount=float(session.data["amount"])
                )
                session.current_intent = None
                session.state = AUTHENTICATED_HOME
                temp = session.data.copy()
                session.data = {}
                self.store.save(session)

                if result["success"]:
                    return self._response(
                        session,
                        speak(session.language, "send_success", amount=temp["amount"], recipient=temp["recipient"]),
                        transaction_result="SEND_MONEY_SUCCESS",
                    )
                return self._response(session, result["message"], transaction_result="SEND_MONEY_FAILED")

            return self._response(session, speak(session.language, "fallback"))

        # ---------- pay bill flow ----------
        if session.state == PAY_BILL_TYPE:
            biller = extract_biller(text)
            if not biller:
                return self._response(session, speak(session.language, "fallback"))
            session.data["biller"] = biller
            session.state = PAY_BILL_AMOUNT
            self.store.save(session)
            return self._response(session, speak(session.language, "ask_bill_amount"))

        if session.state == PAY_BILL_AMOUNT:
            amount = extract_amount(text)
            if amount is None:
                return self._response(session, speak(session.language, "fallback"))
            session.data["amount"] = amount
            session.state = PAY_BILL_CONFIRM
            self.store.save(session)
            return self._response(
                session,
                speak(session.language, "confirm_bill", amount=amount, biller=session.data["biller"])
            )

        if session.state == PAY_BILL_CONFIRM:
            if intent == "CONFIRM" or text == "confirm":
                result = pay_bill(
                    user_id=session.user_id,
                    biller=session.data["biller"],
                    amount=float(session.data["amount"])
                )
                session.current_intent = None
                session.state = AUTHENTICATED_HOME
                temp = session.data.copy()
                session.data = {}
                self.store.save(session)

                if result["success"]:
                    return self._response(
                        session,
                        speak(session.language, "bill_success", amount=temp["amount"], biller=temp["biller"]),
                        transaction_result="PAY_BILL_SUCCESS",
                    )
                return self._response(session, result["message"], transaction_result="PAY_BILL_FAILED")

            return self._response(session, speak(session.language, "fallback"))

        # ---------- buy airtime flow ----------
        if session.state == BUY_AIRTIME_AMOUNT:
            amount = extract_amount(text)
            if amount is None:
                return self._response(session, speak(session.language, "fallback"))
            session.data["amount"] = amount
            session.state = BUY_AIRTIME_CONFIRM
            self.store.save(session)
            return self._response(session, speak(session.language, "confirm_airtime", amount=amount))

        if session.state == BUY_AIRTIME_CONFIRM:
            if intent == "CONFIRM" or text == "confirm":
                result = buy_airtime(session.user_id, float(session.data["amount"]))
                session.current_intent = None
                session.state = AUTHENTICATED_HOME
                temp = session.data.copy()
                session.data = {}
                self.store.save(session)

                if result["success"]:
                    return self._response(
                        session,
                        speak(session.language, "airtime_success", amount=temp["amount"]),
                        transaction_result="BUY_AIRTIME_SUCCESS",
                    )
                return self._response(session, result["message"], transaction_result="BUY_AIRTIME_FAILED")

            return self._response(session, speak(session.language, "fallback"))

        return self._response(session, speak(session.language, "fallback"))

    def _response(self, session, response_text, transaction_result=None):
        return {
            "session_id": session.session_id,
            "state": session.state,
            "language": session.language,
            "is_authenticated": session.is_authenticated,
            "user_id": session.user_id,
            "response_text": response_text,
            "transaction_result": transaction_result,
        }
