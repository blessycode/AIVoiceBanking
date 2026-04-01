import re
from .language_utils import normalize_text

DIGIT_WORDS = {
    "zero": "0",
    "oh": "0",
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
}

REPEAT_WORDS = {
    "double": 2,
    "triple": 3,
}

NUMBER_WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "twenty": 20,
    "gumi": 10, "makumi maviri": 20, "mashanu": 5,
    "kunye": 1, "kubili": 2, "kuthathu": 3, "kune": 4, "isihlanu": 5,
}

BILLERS = {
    "electricity": "electricity",
    "school fees": "school_fees",
    "magetsi": "electricity",
    "fees": "school_fees",
    "bhiri": "bill",
}


def _replace_digit_words(text: str) -> str:
    normalized = normalize_text(text)

    # Expand phrases like "double 1", "double one", "triple 7".
    for repeat_word, count in REPEAT_WORDS.items():
        digit_pattern = "|".join(map(re.escape, DIGIT_WORDS.keys())) + r"|\d"

        def _expand_repeat(match: re.Match) -> str:
            raw_digit = match.group(1)
            digit = DIGIT_WORDS.get(raw_digit, raw_digit)
            return " ".join([digit] * count)

        normalized = re.sub(
            rf"\b{repeat_word}\s+({digit_pattern})\b",
            _expand_repeat,
            normalized,
        )

    for word, digit in DIGIT_WORDS.items():
        normalized = re.sub(rf"\b{word}\b", digit, normalized)
    return normalized


def _digit_sequences(text: str) -> list[str]:
    """
    Extract numeric runs while preserving boundaries between separate numbers.
    Examples:
    - `0,7.1.3.0.3.8.6.1.1` -> [`0713038611`]
    - `send 20 to 0713038611` -> [`20`, `0713038611`]
    - `1 2 3 4` -> [`1234`]
    """
    normalized = _replace_digit_words(text)
    matches = re.finditer(r"\d(?:[\s,.,-]*\d)*", normalized)
    return [re.sub(r"\D", "", match.group(0)) for match in matches if match.group(0)]


def extract_phone(text: str):
    for candidate in _digit_sequences(text):
        if re.fullmatch(r"07\d{8}", candidate):
            return candidate
    return None


def extract_amount(text: str):
    t = normalize_text(text)

    for candidate in _digit_sequences(text):
        if candidate and len(candidate) <= 6:
            return float(candidate)

    if "makumi maviri" in t:
        return 20.0

    for word, val in NUMBER_WORDS.items():
        if re.search(rf"\b{re.escape(word)}\b", t):
            return float(val)

    return None


def extract_biller(text: str):
    t = normalize_text(text)
    for k, v in BILLERS.items():
        if k in t:
            return v
    return None


def extract_name_or_recipient(text: str):
    t = normalize_text(text)

    patterns = [
        r"(?:to|kuna|ku)\s+([a-zA-Z0-9]+)",
        r"(?:recipient is|send to)\s+([a-zA-Z0-9]+)"
    ]

    for pattern in patterns:
        m = re.search(pattern, t)
        if m:
            return m.group(1)

    if re.fullmatch(r"[a-zA-Z]+", t):
        return t

    return None


def extract_language_choice(text: str):
    t = normalize_text(text)
    if "english" in t:
        return "en"
    if "shona" in t:
        return "sn"
    if "ndebele" in t:
        return "nd"
    return None


def extract_password(text: str):
    for candidate in _digit_sequences(text):
        if len(candidate) == 4:
            return candidate

    return None
