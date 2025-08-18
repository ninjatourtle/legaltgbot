import idna

def to_ascii(domain: str) -> str:
    """Normalize a domain name to its IDNA ASCII form."""
    return idna.encode(domain.strip()).decode("ascii")
