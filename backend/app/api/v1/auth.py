from datetime import UTC
from typing import Any

from fastapi import APIRouter
from sqlalchemy import select, update

from app.api.deps import Actor, Db
from app.core.errors import fail
from app.core.security import digest, hash_password, issue_tokens, verify_password
from app.db.base import utcnow
from app.db.models import AuditLog, RefreshSession, User
from app.schemas.common import Login, ProfilePatch, Refresh, Register

router = APIRouter(tags=["auth"])


def profile(user: User) -> dict[str, Any]:
    return {
        "id": user.id,
        "email": user.email,
        "display_name": user.display_name,
        "preferred_language": user.preferred_language,
        "role": user.role,
    }


@router.post("/auth/register", status_code=201)
def register(data: Register, db: Db) -> dict[str, Any]:
    email = str(data.email).lower()
    if db.scalar(select(User).where(User.email == email)):
        raise fail("email_unavailable", "Этот адрес недоступен", 409)
    user = User(
        email=email,
        password_hash=hash_password(data.password),
        display_name=data.display_name,
        preferred_language=data.preferred_language,
    )
    db.add(user)
    db.flush()
    db.add(AuditLog(actor_id=user.id, entity_type="user", entity_id=user.id, action="register"))
    return {**issue_tokens(db, user), "user": profile(user)}


@router.post("/auth/login")
def login(data: Login, db: Db) -> dict[str, Any]:
    user = db.scalar(select(User).where(User.email == str(data.email).lower()))
    if user is None or not user.is_active or not verify_password(data.password, user.password_hash):
        raise fail("invalid_credentials", "Неверные данные входа", 401)
    return {**issue_tokens(db, user), "user": profile(user)}


@router.post("/auth/refresh")
def refresh(data: Refresh, db: Db) -> dict[str, str]:
    session = db.scalar(
        select(RefreshSession)
        .where(RefreshSession.token_hash == digest(data.refresh_token))
        .with_for_update()
    )
    if session is None:
        raise fail("invalid_refresh", "Сессия истекла", 401)
    if session.revoked:
        db.execute(
            update(RefreshSession)
            .where(RefreshSession.family_id == session.family_id)
            .values(revoked=True)
        )
        db.commit()  # Persist family revocation even though this request returns an error.
        raise fail("refresh_reused", "Войдите повторно", 401)
    if session.expires_at.replace(tzinfo=UTC) < utcnow():
        raise fail("invalid_refresh", "Сессия истекла", 401)
    user = db.get(User, session.user_id)
    if user is None or not user.is_active:
        raise fail("invalid_refresh", "Сессия недоступна", 401)
    session.revoked = True
    return issue_tokens(db, user, session.family_id)


@router.post("/auth/logout", status_code=204)
def logout(data: Refresh, db: Db) -> None:
    session = db.scalar(
        select(RefreshSession).where(RefreshSession.token_hash == digest(data.refresh_token))
    )
    if session:
        db.execute(
            update(RefreshSession)
            .where(RefreshSession.family_id == session.family_id)
            .values(revoked=True)
        )


@router.get("/users/me")
def me(user: Actor) -> dict[str, Any]:
    return profile(user)


@router.patch("/users/me")
def update_me(data: ProfilePatch, user: Actor, db: Db) -> dict[str, Any]:
    user.display_name = data.display_name
    user.preferred_language = data.preferred_language
    db.flush()
    return profile(user)
