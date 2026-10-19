import secrets
from datetime import UTC, timedelta

from fastapi import APIRouter, BackgroundTasks
from pydantic import EmailStr, Field
from sqlalchemy import select, update

from app.api.deps import Db
from app.core.config import get_settings
from app.core.errors import fail
from app.core.security import digest, hash_password
from app.db.base import utcnow
from app.db.models import AuditLog, PasswordReset, RefreshSession, User
from app.schemas.common import Input
from app.services.mail import deliver_reset

router = APIRouter(tags=["auth"])


class ForgotPassword(Input):
    email: EmailStr


class ResetPassword(Input):
    token: str = Field(min_length=40, max_length=200)
    password: str = Field(min_length=10, max_length=128)


@router.post("/auth/forgot-password", status_code=202)
def forgot_password(data: ForgotPassword, db: Db, tasks: BackgroundTasks) -> dict[str, str]:
    settings = get_settings()
    if not settings.smtp_host:
        raise fail("recovery_unavailable", "Восстановление пароля временно недоступно", 503)
    user = db.scalar(select(User).where(User.email == str(data.email).lower()).with_for_update())
    result = {"status": "accepted"}
    if user is None or not user.is_active:
        return result
    latest = db.scalar(
        select(PasswordReset)
        .where(PasswordReset.user_id == user.id)
        .order_by(PasswordReset.created_at.desc())
        .limit(1)
    )
    if latest and latest.created_at.replace(tzinfo=UTC) > utcnow() - timedelta(minutes=1):
        return result
    token = secrets.token_urlsafe(48)
    db.add(
        PasswordReset(
            user_id=user.id,
            token_hash=digest(token),
            expires_at=utcnow() + timedelta(minutes=settings.password_reset_minutes),
        )
    )
    # Commit before delivery; only a hash is persisted, never the email or token in a queue.
    db.commit()
    tasks.add_task(deliver_reset, user.email, token, user.preferred_language)
    return result


@router.post("/auth/reset-password")
def reset_password(data: ResetPassword, db: Db) -> dict[str, str]:
    reset = db.scalar(select(PasswordReset).where(PasswordReset.token_hash == digest(data.token)))
    if reset is None:
        raise fail("invalid_reset", "Ссылка недействительна или истекла", 400)
    # Serialize all reset tokens for this user, including tokens issued in different requests.
    user = db.scalar(select(User).where(User.id == reset.user_id).with_for_update())
    db.refresh(reset)
    if (
        user is None
        or not user.is_active
        or reset.used
        or reset.expires_at.replace(tzinfo=UTC) <= utcnow()
    ):
        raise fail("invalid_reset", "Ссылка недействительна или истекла", 400)
    user.password_hash = hash_password(data.password)
    user.auth_version += 1
    db.execute(update(PasswordReset).where(PasswordReset.user_id == user.id).values(used=True))
    db.execute(update(RefreshSession).where(RefreshSession.user_id == user.id).values(revoked=True))
    db.add(
        AuditLog(actor_id=user.id, entity_type="user", entity_id=user.id, action="password_reset")
    )
    return {"status": "password_changed"}
