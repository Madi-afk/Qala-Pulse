from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import fail
from app.db.models import User
from app.db.session import get_db

Db = Annotated[Session, Depends(get_db)]
bearer = HTTPBearer(auto_error=False)


def current_user(
    db: Db, credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)]
) -> User:
    if credentials is None:
        raise fail("authentication_required", "Требуется вход", 401)
    try:
        claims = jwt.decode(
            credentials.credentials,
            get_settings().jwt_secret,
            algorithms=["HS256"],
            audience="qalapulse-mobile",
            issuer="qalapulse",
        )
        if claims.get("type") != "access":
            raise ValueError("wrong token type")
        user = db.get(User, UUID(claims["sub"]))
    except (jwt.PyJWTError, ValueError, KeyError):
        raise fail("invalid_token", "Сессия истекла", 401) from None
    if user is None or not user.is_active:
        raise fail("invalid_token", "Сессия недоступна", 401)
    return user


Actor = Annotated[User, Depends(current_user)]


def require_role(user: User, *roles: str) -> None:
    if user.role not in roles:
        raise fail("forbidden", "Недостаточно прав", 403)
