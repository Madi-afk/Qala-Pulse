import pytest
from pydantic import ValidationError

from app.core.config import Settings
from app.core.security import hash_password, verify_password
from app.db.base import utcnow
from app.db.models import Incident
from app.services.ai.providers import MockVisionAnalyzer
from app.services.geospatial.priority import distance_meters, priority


def test_health_and_stable_errors(client):
    response = client.get("/api/v1/health")
    assert response.json()["status"] == "ok"
    assert response.headers["X-Request-ID"]
    bad = client.get("/api/v1/incidents/nearby?latitude=100&longitude=0")
    assert bad.status_code == 422
    assert set(bad.json()["error"]) == {"code", "message", "request_id"}


def test_hashes_are_salted_and_verify():
    first, second = hash_password("test-password"), hash_password("test-password")
    assert first != second
    assert verify_password("test-password", first)
    assert not verify_password("wrong", first)


def test_production_rejects_unsafe_settings():
    with pytest.raises(ValidationError):
        Settings(environment="production", jwt_secret="development-" + "x" * 32)


def test_priority_caps_confirmations_and_distance():
    score, explanation = priority(10, 10, 100, utcnow(), 0, 0)
    assert explanation["components"]["confirmations"] == 30
    assert score == 110
    assert distance_meters(43.2389, 76.8897, 43.2389, 76.8897) == 0
    assert 100 < distance_meters(43, 76, 43.001, 76) < 120


def test_mock_is_deterministic_and_honest():
    analyzer = MockVisionAnalyzer()
    result = analyzer.analyze(b"", "Открытый люк")
    assert result == analyzer.analyze(b"", "Открытый люк")
    assert result.category_code == "open_manhole"
    assert result.confidence == 0
    assert not analyzer.analyze(b"", "селфи").is_civic_issue


def test_required_models_exist():
    assert Incident.__table__.c.location.type.get_col_spec() == "geography(POINT,4326)"
