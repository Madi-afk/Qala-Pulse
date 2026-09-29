import hashlib
import secrets
from datetime import timedelta
from uuid import UUID, uuid4

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.base import utcnow
from app.db.models import RefreshSession, User

hasher = PasswordHasher()


def hash_password(password: str) -> str:
    return hasher.hash(password)


def verify_password(password: str, encoded: str) -> bool:
    try:
        return hasher.verify(encoded, password)
    except VerificationError:
        return False


def digest(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def issue_tokens(db: Session, user: User, family: UUID | None = None) -> dict[str, str]:
    settings = get_settings()
    now = utcnow()
    access = jwt.encode(
        {
            "sub": str(user.id),
            "type": "access",
            "iat": now,
            "exp": now + timedelta(minutes=settings.access_minutes),
            "iss": "qalapulse",
            "aud": "qalapulse-mobile",
            "jti": str(uuid4()),
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
    refresh = secrets.token_urlsafe(48)
    db.add(
        RefreshSession(
            user_id=user.id,
            family_id=family or uuid4(),
            token_hash=digest(refresh),
            expires_at=now + timedelta(days=settings.refresh_days),
        )
    )
    db.flush()
    return {"access_token": access, "refresh_token": refresh, "token_type": "bearer"}
