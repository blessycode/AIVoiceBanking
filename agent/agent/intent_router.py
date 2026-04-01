from .language_utils import normalize_text


def route_intent(text: str) -> str:
    t = normalize_text(text)

    if any(x in t for x in ["create profile", "create account", "register", "gadzira account", "ngibhalise"]):
        return "CREATE_PROFILE"

    if any(x in t for x in ["login", "log me in", "ndipinze", "ngingene"]):
        return "LOGIN"

    if any(x in t for x in ["balance", "account balance", "mari iri muaccount", "imali ekwi-account"]):
        return "CHECK_BALANCE"

    if any(x in t for x in ["send", "transfer", "tumira", "thumela"]):
        return "SEND_MONEY"

    if any(x in t for x in ["airtime", "tenga airtime", "thenga airtime", "buy airtime"]):
        return "BUY_AIRTIME"

    if any(x in t for x in ["bill", "electricity", "school fees", "bhiri", "magetsi", "fees"]):
        return "PAY_BILL"

    if any(x in t for x in ["confirm", "simbisa", "qinisekisa"]):
        return "CONFIRM"

    if any(x in t for x in ["cancel", "stop", "rega", "yekela"]):
        return "CANCEL"

    if any(x in t for x in ["logout", "log me out", "ndibudise", "ngikhupha"]):
        return "LOGOUT"

    return "UNKNOWN"