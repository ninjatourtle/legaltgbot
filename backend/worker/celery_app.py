"""Инициализация приложения Celery."""

from celery import Celery
from backend.app.config import settings

celery_app = Celery(
    "worker",
    broker=settings.rabbitmq_url,
    backend=settings.redis_url,
)

celery_app.conf.accept_content = ["json"]
celery_app.conf.task_serializer = "json"
celery_app.conf.result_serializer = "json"
celery_app.conf.timezone = "Europe/Moscow"
