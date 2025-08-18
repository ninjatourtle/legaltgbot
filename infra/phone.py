import re

def normalize(phone: str) -> str:
    """Normalize Russian phone numbers to international format."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("8"):
        digits = "7" + digits[1:]
    if not digits.startswith("7"):
        digits = "7" + digits
    return "+" + digits
