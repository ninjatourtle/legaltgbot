from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    TELEGRAM_TOKEN: str
    STARS_PROVIDER_TOKEN: str
    CRYPTO_PROVIDER_TOKEN: str
    OPENAI_API_KEY: str
    DATABASE_URL: str = "sqlite+aiosqlite:///./bot.db"
    PRICE_PER_PAGE: int = 100
    STARS_CURRENCY: str = "USD"
    CRYPTO_CURRENCY: str = "USD"

    class Config:
        env_file = ".env"

settings = Settings()
