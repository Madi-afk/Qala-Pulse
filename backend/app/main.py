import hashlib
import logging
import time
from collections.abc import Awaitable, Callable
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI, Request, Response
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from redis.asyncio import Redis
from redis.exceptions import RedisError
from sqlalchemy.exc import IntegrityError
from starlette.exceptions import HTTPException

from app.api.deps import Actor, require_role
from app.api.v1 import auth, confirmations, health, incidents, moderation, operations, uploads
from app.core.body_limit import RequestSizeLimit
from app.core.config import get_settings
from app.core.logging import configure_logging

configure_logging()
logger = logging.getLogger("qalapulse.http")
settings = get_settings()
app = FastAPI(
    title="QalaPulse API",
    version="0.1.0",
    description="Гражданская платформа. Публикация не является регистрацией в государственном органе.",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "Accept-Language"],
    expose_headers=["X-Request-ID"],
)
requests_total = Counter(
    "qalapulse_http_requests_total", "HTTP requests", ["method", "route", "status"]
)

app.add_middleware(
    RequestSizeLimit, limit=max(settings.max_audio_bytes, settings.max_image_bytes) + 1024 * 1024
)


def error_response(request: Request, status: int, code: str, message: str) -> JSONResponse:
    return JSONResponse(
        {
            "error": {
                "code": code,
                "message": message,
                "request_id": getattr(request.state, "request_id", "unknown"),
            }
        },
        status_code=status,
    )


@app.exception_handler(HTTPException)
async def http_error(request: Request, exc: HTTPException) -> JSONResponse:
    detail = (
        exc.detail
        if isinstance(exc.detail, dict)
        else {"code": "http_error", "message": str(exc.detail)}
    )
    return error_response(request, exc.status_code, detail["code"], detail["message"])


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
    return error_response(request, 422, "validation_error", "Проверьте поля запроса")


@app.exception_handler(IntegrityError)
async def conflict_error(request: Request, exc: IntegrityError) -> JSONResponse:
    return error_response(
        request, 409, "conflict", "Запись уже существует или связана с другими данными"
    )


@app.middleware("http")
async def observe(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    request.state.request_id = str(uuid4())
    started = time.monotonic()
    try:
        length = request.headers.get("content-length")
        if (
            length
            and int(length) > max(settings.max_audio_bytes, settings.max_image_bytes) + 1024 * 1024
        ):
            response: Response = error_response(
                request, 413, "file_too_large", "Запрос превышает лимит"
            )
        elif settings.rate_limit_enabled and request.url.path not in (
            "/api/v1/health",
            "/api/v1/ready",
        ):
            host = request.client.host if request.client else "unknown"
            fingerprint = hashlib.sha256((settings.jwt_secret + host).encode()).hexdigest()[:24]
            bucket = f"rate:{fingerprint}:{int(time.time() // 60)}"
            auth_request = request.url.path.startswith("/api/v1/auth/")
            if auth_request:
                bucket += ":auth"
            try:
                async with Redis.from_url(
                    settings.redis_url, socket_connect_timeout=2, socket_timeout=2
                ) as redis:
                    count = await redis.eval(
                        "local n=redis.call('INCR',KEYS[1]); if n==1 then redis.call('EXPIRE',KEYS[1],61) end; return n",
                        1,
                        bucket,
                    )
                if int(count) > (20 if auth_request else settings.rate_limit_per_minute):
                    response = error_response(
                        request, 429, "rate_limited", "Слишком много запросов"
                    )
                    response.headers["Retry-After"] = "60"
                else:
                    response = await call_next(request)
            except RedisError:
                response = error_response(
                    request, 503, "service_unavailable", "Сервис временно недоступен"
                )
        else:
            response = await call_next(request)
    except Exception as exc:
        logger.error(
            "unhandled_error",
            extra={"error_type": type(exc).__name__, "request_id": request.state.request_id},
        )
        response = error_response(request, 500, "internal_error", "Временная ошибка сервера")
    route = getattr(request.scope.get("route"), "path", "unmatched")
    response.headers["X-Request-ID"] = request.state.request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    if request.url.path.startswith("/console"):
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self'; style-src 'self'; "
            "img-src 'self' blob:; connect-src 'self'; font-src 'self'; "
            "object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"
        )
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
    if request.url.path.startswith("/api/v1/operations"):
        response.headers["Cache-Control"] = "private, no-store"
    logger.info(
        "request",
        extra={
            "request_id": request.state.request_id,
            "method": request.method,
            "route": route,
            "status": response.status_code,
            "duration_ms": round((time.monotonic() - started) * 1000),
        },
    )
    requests_total.labels(request.method, route, str(response.status_code)).inc()
    return response


for router in [
    health.router,
    auth.router,
    uploads.router,
    incidents.router,
    confirmations.router,
    moderation.router,
    operations.router,
]:
    app.include_router(router, prefix="/api/v1")

app.mount(
    "/console", StaticFiles(directory=Path(__file__).parent / "console", html=True), name="console"
)


@app.get("/metrics", include_in_schema=False)
def metrics(user: Actor) -> Response:
    require_role(user, "admin")
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
