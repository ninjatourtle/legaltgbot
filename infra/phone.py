import re


def normalize(phone: str) -> str:
    """Нормализует российские номера телефонов в международный формат."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("8"):
        digits = "7" + digits[1:]
    if not digits.startswith("7"):
        digits = "7" + digits
    return "+" + digits
