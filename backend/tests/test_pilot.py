import hashlib
import json
from datetime import timedelta
from uuid import UUID

import pytest
from pydantic import ValidationError
from sqlalchemy import select

from app.backup import safe_file, validate_snapshot
from app.core.config import Settings, get_settings
from app.core.security import digest
from app.db.base import utcnow
from app.db.models import AuditLog, IncidentMedia, PasswordReset, Upload, User
from app.retention import erase_upload, expire_files, expire_orphans
from app.services.storage.objects import ObjectStorage


@pytest.fixture
def mail(monkeypatch):
    delivered = []
    monkeypatch.setattr(get_settings(), "smtp_host", "smtp.example.test")
    monkeypatch.setattr("app.api.v1.recovery.deliver_reset", lambda *args: delivered.append(args))
    return delivered


def test_reset_revokes_all_sessions_and_is_single_use(client, db, account, headers, mail):
    response = client.post("/api/v1/auth/forgot-password", json={"email": "citizen@example.com"})
    assert response.status_code == 202
    token = mail[0][1]
    assert token not in response.text
    reset = db.scalar(select(PasswordReset))
    assert reset.token_hash == digest(token)
    changed = client.post(
        "/api/v1/auth/reset-password", json={"token": token, "password": "New-password-2026!"}
    )
    assert changed.status_code == 200
    assert client.get("/api/v1/users/me", headers=headers).status_code == 401
    assert (
        client.post(
            "/api/v1/auth/refresh", json={"refresh_token": account["refresh_token"]}
        ).status_code
        == 401
    )
    assert (
        client.post(
            "/api/v1/auth/login",
            json={"email": "citizen@example.com", "password": "Test-only-2026!"},
        ).status_code
        == 401
    )
    assert (
        client.post(
            "/api/v1/auth/login",
            json={"email": "citizen@example.com", "password": "New-password-2026!"},
        ).status_code
        == 200
    )
    assert (
        client.post(
            "/api/v1/auth/reset-password", json={"token": token, "password": "Another-password!"}
        ).status_code
        == 400
    )
    assert db.scalar(select(AuditLog).where(AuditLog.action == "password_reset"))


def test_recovery_does_not_reveal_account_and_limits_delivery(client, db, account, mail):
    for email in ["citizen@example.com", "absent@example.com", "citizen@example.com"]:
        response = client.post("/api/v1/auth/forgot-password", json={"email": email})
        assert response.status_code == 202
        assert response.json() == {"status": "accepted"}
        assert response.headers["cache-control"] == "no-store"
    assert len(mail) == 1
    db.get(User, UUID(account["user"]["id"])).is_active = False
    db.commit()
    assert (
        client.post(
            "/api/v1/auth/forgot-password", json={"email": "citizen@example.com"}
        ).status_code
        == 202
    )
    assert len(mail) == 1


def test_expired_reset_cannot_change_password(client, db, account, mail):
    client.post("/api/v1/auth/forgot-password", json={"email": "citizen@example.com"})
    reset = db.scalar(select(PasswordReset))
    reset.expires_at = utcnow() - timedelta(seconds=1)
    db.commit()
    assert (
        client.post(
            "/api/v1/auth/reset-password",
            json={"token": mail[0][1], "password": "New-password-2026!"},
        ).status_code
        == 400
    )
    assert not reset.used


def test_mail_failure_is_generic_and_does_not_log_secrets(client, account, monkeypatch):
    from app.core.metrics import mail_failures
    from app.services.mail import deliver_reset

    logs = []
    monkeypatch.setattr("app.services.mail.logger.error", logs.append)
    monkeypatch.setattr(
        "app.services.mail.send_mail",
        lambda *args: (_ for _ in ()).throw(OSError("secret-email@example.com secret-token")),
    )
    before = mail_failures._value.get()
    deliver_reset("secret-email@example.com", "secret-token", "ru")
    assert mail_failures._value.get() == before + 1
    assert logs == ["password_reset_delivery_failed"]


def test_pilot_registration_gate(client, monkeypatch):
    monkeypatch.setattr(get_settings(), "pilot_registration_closed", True)
    monkeypatch.setattr(get_settings(), "pilot_registration_emails", ["invited@example.com"])
    data = {
        "email": "outside@example.com",
        "password": "Test-only-2026!",
        "display_name": "Resident",
    }
    assert client.post("/api/v1/auth/register", json=data).status_code == 403
    data["email"] = "invited@example.com"
    assert client.post("/api/v1/auth/register", json=data).status_code == 201


def test_original_expires_but_public_photo_remains(client, db, headers, incident_payload):
    response = client.post(
        "/api/v1/incidents",
        headers={**headers, "Idempotency-Key": "retention-original"},
        json=incident_payload,
    )
    assert response.status_code == 201, response.text
    upload = db.get(Upload, UUID(incident_payload["upload_ids"][0]))
    upload.created_at = utcnow() - timedelta(days=8)
    db.commit()
    key = upload.original_key
    assert expire_files(db)["originals"] == 1
    assert ObjectStorage().get(key)
    assert expire_files(db, apply=True)["originals"] == 1
    db.commit()
    with pytest.raises(FileNotFoundError):
        ObjectStorage().get(key)
    assert client.get(f"/api/v1/media/{upload.id}/image").status_code == 200
    assert expire_files(db, apply=True)["uploads"] == 0
    upload.created_at = utcnow() - timedelta(days=91)
    db.commit()
    assert expire_files(db, apply=True)["public_files"] == 2
    db.commit()
    assert client.get(f"/api/v1/media/{upload.id}/image").status_code == 404
    assert db.scalar(select(IncidentMedia)).redacted_url == ""


def test_abandoned_file_expires_and_cannot_be_published(client, db, headers, incident_payload):
    upload = db.get(Upload, UUID(incident_payload["upload_ids"][0]))
    upload.created_at = utcnow() - timedelta(days=8)
    db.commit()
    expire_files(db, apply=True)
    db.commit()
    assert client.get(f"/api/v1/uploads/{upload.id}/preview", headers=headers).status_code == 410
    response = client.post(
        "/api/v1/incidents",
        headers={**headers, "Idempotency-Key": "expired-publish"},
        json=incident_payload,
    )
    assert response.status_code == 410


def test_audio_retention_clears_transcript(client, db, headers):
    response = client.post(
        "/api/v1/uploads/audio",
        headers=headers,
        files={"file": ("sound.wav", b"RIFF0000WAVE" + b"0" * 30, "audio/wav")},
    )
    assert response.status_code == 202
    upload = db.get(Upload, UUID(response.json()["id"]))
    upload.created_at = utcnow() - timedelta(days=3)
    db.commit()
    expire_files(db, apply=True)
    db.commit()
    assert upload.transcript is None
    assert upload.status == "expired"
    assert client.post(f"/api/v1/uploads/{upload.id}/retry", headers=headers).status_code == 410


def test_snapshot_detects_corruption_and_traversal(tmp_path):
    dump = tmp_path / "database.dump"
    dump.write_bytes(b"database-backup")
    obj = tmp_path / "image"
    obj.write_bytes(b"photo")
    manifest = {
        "format": 1,
        "dump_sha256": hashlib.sha256(dump.read_bytes()).hexdigest(),
        "objects": [{"file": "image", "size": 5, "sha256": hashlib.sha256(b"photo").hexdigest()}],
    }
    (tmp_path / "manifest.json").write_text(json.dumps(manifest))
    validate_snapshot(tmp_path)
    obj.write_bytes(b"wrong")
    with pytest.raises(RuntimeError, match="object backup checksum"):
        validate_snapshot(tmp_path)
    with pytest.raises(ValueError):
        safe_file(tmp_path, "../outside")
    dump.write_bytes(b"damaged")
    with pytest.raises(RuntimeError, match="database backup checksum"):
        validate_snapshot(tmp_path)


def test_internal_metrics_require_separate_secret(client, monkeypatch, headers):
    monkeypatch.setattr(get_settings(), "metrics_token", "test-metrics-secret" * 3)
    assert client.get("/internal/metrics", headers=headers).status_code == 403
    assert (
        client.get(
            "/internal/metrics", headers={"Authorization": "Bearer " + get_settings().metrics_token}
        ).status_code
        == 200
    )
    response = client.get("/account/")
    assert response.status_code == 200
    assert "frame-ancestors 'none'" in response.headers["content-security-policy"]
    assert response.headers["cache-control"] == "no-store"


def test_production_rejects_incomplete_security():
    with pytest.raises(ValidationError):
        Settings(
            environment="production",
            storage_mode="minio",
            rate_limit_enabled=True,
            jwt_secret="a" * 64,
            minio_secret_key="b" * 64,
        )


def test_privacy_erasure_is_idempotent(client, db, headers, incident_payload):
    upload_id = UUID(incident_payload["upload_ids"][0])
    assert erase_upload(db, upload_id) == 1
    assert db.get(Upload, upload_id).redacted_key
    assert erase_upload(db, upload_id, apply=True) == 1
    db.commit()
    assert erase_upload(db, upload_id, apply=True) == 0
    assert db.scalar(select(AuditLog).where(AuditLog.action == "privacy_erasure"))
    assert client.get(f"/api/v1/uploads/{upload_id}/preview", headers=headers).status_code == 410


def test_orphans_require_age_and_missing_database_reference(client, db, incident_payload):
    import os
    import time
    from pathlib import Path

    storage = ObjectStorage()
    storage.put("orphan/old", b"old", "image/jpeg", public=True)
    storage.put("orphan/new", b"new", "image/jpeg", public=True)
    old = Path(get_settings().storage_path) / storage.bucket(True) / "orphan/old"
    os.utime(old, (time.time() - 9 * 86400, time.time() - 9 * 86400))
    assert expire_orphans(db) == 1
    assert old.exists()
    assert expire_orphans(db, apply=True) == 1
    assert not old.exists()
    assert storage.get("orphan/new", public=True) == b"new"
    assert db.get(Upload, UUID(incident_payload["upload_ids"][0])).redacted_key
