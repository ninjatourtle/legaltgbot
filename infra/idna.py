import idna


def to_ascii(domain: str) -> str:
    """Преобразует доменное имя в формат IDNA ASCII."""
    return idna.encode(domain.strip()).decode("ascii")
