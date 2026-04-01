def normalize_text(text: str) -> str:
    return str(text).strip().lower()


def detect_language(text: str) -> str:
    t = normalize_text(text)

    shona_markers = [
        "ndi", "muaccount", "simbisa", "mari", "bhadhara", "tenga",
        "ndibudise", "ndipinze", "nemutsara", "madora", "magetsi"
    ]
    ndebele_markers = [
        "ngi", "qinisekisa", "imali", "ngingene", "ngikhupha",
        "ngitshele", "umutsho", "yami", "ku-account"
    ]

    shona_score = sum(1 for m in shona_markers if m in t)
    ndebele_score = sum(1 for m in ndebele_markers if m in t)

    if shona_score > ndebele_score and shona_score > 0:
        return "sn"
    if ndebele_score > shona_score and ndebele_score > 0:
        return "nd"
    return "en"