from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "legal-tg-bot"
    log_level: str = "INFO"
    database_url: str = "postgresql+asyncpg://postgres:postgres@postgres:5432/bot"
    redis_url: str = "redis://redis:6379/0"
    rabbitmq_url: str = "amqp://rabbitmq:rabbitmq@rabbitmq:5672//"
    minio_endpoint: str = "minio:9000"
    minio_access_key: str = "minio"
    minio_secret_key: str = "minio123"

    class Config:
        env_file = ".env"

settings = Settings()
