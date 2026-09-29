from fastapi import APIRouter
from fastapi.responses import JSONResponse
from redis import Redis
from sqlalchemy import text

from app.api.deps import Db
from app.core.config import get_settings
from app.services.storage.objects import ObjectStorage

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "qalapulse"}


@router.get("/ready")
def ready(db: Db) -> JSONResponse:
    checks: dict[str, bool] = {}
    try:
        db.execute(text("SELECT 1"))
        checks["postgresql"] = True
    except Exception:
        checks["postgresql"] = False
        db.rollback()
    try:
        checks["redis"] = bool(
            Redis.from_url(
                get_settings().redis_url, socket_connect_timeout=2, socket_timeout=2
            ).ping()
        )
    except Exception:
        checks["redis"] = False
    try:
        checks["minio"] = ObjectStorage().ready()
    except Exception:
        checks["minio"] = False
    return JSONResponse(
        {"status": "ready" if all(checks.values()) else "unavailable", "checks": checks},
        status_code=200 if all(checks.values()) else 503,
    )
