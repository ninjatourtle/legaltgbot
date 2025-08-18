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

@app.get("/health")
async def health() -> dict[str, str]:
    logger.info("health_check")
    return {"status": "ok"}
