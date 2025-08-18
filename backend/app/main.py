"""Основной модуль приложения FastAPI."""

from fastapi import FastAPI
import structlog
from .config import settings

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)

logger = structlog.get_logger()

app = FastAPI(title=settings.app_name)


@app.get("/health", summary="Проверка состояния")
async def health() -> dict[str, str]:
    """Возвращает статус работоспособности сервиса."""
    logger.info("проверка_состояния")
    return {"статус": "ок"}
