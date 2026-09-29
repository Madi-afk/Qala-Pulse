import os
from collections.abc import Generator
from io import BytesIO

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

os.environ.update(
    ENVIRONMENT="test",
    DATABASE_URL="sqlite://",
    STORAGE_MODE="local",
    RATE_LIMIT_ENABLED="false",
    TASK_ALWAYS_EAGER="true",
    AI_MODE="mock",
)

from app.db.base import Base  # noqa: E402
from app.db.models import Category  # noqa: E402
from app.db.session import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.services.ai.providers import LABELS  # noqa: E402


@pytest.fixture
def db(tmp_path, monkeypatch) -> Generator[Session]:
    from app.core.config import get_settings

    monkeypatch.setattr(get_settings(), "storage_path", str(tmp_path))
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(engine)
    with Session(engine, expire_on_commit=False) as session:
        for code, (ru, kk, severity, _) in LABELS.items():
            session.add(
                Category(
                    id=code,
                    code=code,
                    name_ru=ru,
                    name_kk=kk,
                    description=ru,
                    base_severity=severity,
                    icon=code,
                    color="#168573",
                )
            )
        session.commit()
        yield session
    engine.dispose()


@pytest.fixture
def client(db) -> Generator[TestClient]:
    def override() -> Generator[Session]:
        try:
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise

    app.dependency_overrides[get_db] = override
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def account(client):
    return client.post(
        "/api/v1/auth/register",
        json={
            "email": "citizen@example.com",
            "password": "Test-only-2026!",
            "display_name": "Житель",
        },
    ).json()


@pytest.fixture
def headers(account):
    return {"Authorization": f"Bearer {account['access_token']}"}


@pytest.fixture
def photo():
    output = BytesIO()
    Image.new("RGB", (100, 100), "red").save(output, "JPEG")
    return output.getvalue()


@pytest.fixture
def incident_payload(client, headers, photo):
    upload = client.post(
        "/api/v1/uploads/images",
        headers=headers,
        files={"file": ("photo.jpg", photo, "image/jpeg")},
    )
    assert upload.status_code == 201, upload.text
    return {
        "category_id": "road_damage",
        "title": "Яма на дороге",
        "description": "Глубокая яма на дороге",
        "latitude": 43.2389,
        "longitude": 76.8897,
        "severity": 7,
        "upload_ids": [upload.json()["id"]],
        "reviewed_by_user": True,
    }
