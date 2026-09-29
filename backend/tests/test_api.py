from datetime import timedelta
from uuid import UUID

import pytest

from app.db.base import utcnow
from app.db.models import Incident, IncidentAssignment, Organization, User


def publish(client, headers, payload, key="request-key-0001"):
    return client.post(
        "/api/v1/incidents", headers={**headers, "Idempotency-Key": key}, json=payload
    )


def test_auth_rotation_reuse_and_logout(client, account, headers):
    assert client.get("/api/v1/users/me", headers=headers).status_code == 200
    assert client.get("/api/v1/users/me").status_code == 401
    refreshed = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": account["refresh_token"]}
    )
    assert refreshed.status_code == 200
    token = refreshed.json()["refresh_token"]
    assert token != account["refresh_token"]
    reused = client.post("/api/v1/auth/refresh", json={"refresh_token": account["refresh_token"]})
    assert reused.status_code == 401
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": token}).status_code == 401
    new = client.post(
        "/api/v1/auth/login", json={"email": "citizen@example.com", "password": "Test-only-2026!"}
    ).json()
    assert (
        client.post("/api/v1/auth/logout", json={"refresh_token": new["refresh_token"]}).status_code
        == 204
    )
    assert (
        client.post(
            "/api/v1/auth/refresh", json={"refresh_token": new["refresh_token"]}
        ).status_code
        == 401
    )


def test_no_self_escalation_and_bad_password(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "a@example.com",
            "password": "Test-only-2026!",
            "display_name": "Test",
            "role": "admin",
        },
    )
    assert response.status_code == 422
    assert (
        client.post(
            "/api/v1/auth/login", json={"email": "nobody@example.com", "password": "wrong"}
        ).status_code
        == 401
    )


def test_publish_idempotency_privacy_and_immutability(client, headers, incident_payload):
    response = publish(client, headers, incident_payload)
    assert response.status_code == 201, response.text
    incident = response.json()
    assert incident["source"] == "citizen"
    assert incident["status"] == "published"
    assert "original" not in str(incident["media"])
    assert publish(client, headers, incident_payload).json()["id"] == incident["id"]
    changed = publish(client, headers, {**incident_payload, "title": "Другой текст"})
    assert changed.status_code == 409
    assert client.get("/api/v1/incidents").json()["total"] == 1
    assert (
        client.patch(
            f"/api/v1/incidents/{incident['id']}", headers=headers, json={"title": "Новое название"}
        ).status_code
        == 409
    )
    assert len(client.get(f"/api/v1/incidents/{incident['id']}/timeline").json()["items"]) == 1
    image_url = incident["media"][0]["url"]
    assert client.get(image_url).status_code == 200
    assert client.get(image_url.replace("/image", "/original")).status_code == 422


def test_review_required_and_private_draft(client, headers, incident_payload):
    assert (
        publish(client, headers, {**incident_payload, "reviewed_by_user": False}).status_code == 422
    )
    draft = publish(
        client,
        headers,
        {**incident_payload, "reviewed_by_user": False, "publish": False},
        key="corrected-draft-0001",
    ).json()
    assert client.get("/api/v1/incidents").json()["total"] == 0
    assert client.get(f"/api/v1/incidents/{draft['id']}").status_code == 404
    result = client.patch(
        f"/api/v1/incidents/{draft['id']}",
        headers=headers,
        json={"title": "Исправлено вручную", "publish": True, "reviewed_by_user": True},
    )
    assert result.status_code == 200
    assert client.get("/api/v1/incidents").json()["total"] == 1


def test_other_citizen_can_confirm_but_cannot_edit_or_use_upload(client, headers, incident_payload):
    other = client.post(
        "/api/v1/auth/register",
        json={
            "email": "other@example.com",
            "password": "Test-only-2026!",
            "display_name": "Другой",
        },
    ).json()
    other_headers = {"Authorization": f"Bearer {other['access_token']}"}
    assert publish(client, other_headers, incident_payload).status_code == 404
    incident = publish(client, headers, incident_payload).json()
    assert (
        client.patch(
            f"/api/v1/incidents/{incident['id']}",
            headers=other_headers,
            json={"title": "Чужое изменение"},
        ).status_code
        == 403
    )
    path = f"/api/v1/incidents/{incident['id']}/confirmations"
    assert (
        client.post(path, headers=other_headers, json={"status": "still_exists"}).status_code == 201
    )
    assert (
        client.post(path, headers=other_headers, json={"status": "still_exists"}).status_code == 409
    )
    assert client.get(f"/api/v1/incidents/{incident['id']}").json()["confirmation_count"] == 1


def test_radius_duplicates_time_and_category(client, headers, incident_payload, db):
    incident = publish(client, headers, incident_payload).json()
    params = {"latitude": 43.2389, "longitude": 76.8897, "radius": 100}
    assert len(client.get("/api/v1/incidents/nearby", params=params).json()["items"]) == 1
    assert not client.get("/api/v1/incidents/nearby", params={**params, "latitude": 44}).json()[
        "items"
    ]
    search = {
        k: incident_payload[k]
        for k in ("latitude", "longitude", "title", "description", "category_id")
    }
    result = client.post("/api/v1/incidents/duplicates/search", headers=headers, json=search).json()
    assert result["items"][0]["incident"]["id"] == incident["id"]
    assert result["automatic_merge"] is False
    assert not client.post(
        "/api/v1/incidents/duplicates/search",
        headers=headers,
        json={**search, "category_id": "garbage"},
    ).json()["items"]
    item = db.get(Incident, UUID(incident["id"]))
    item.created_at = utcnow() - timedelta(days=40)
    db.commit()
    assert not client.post(
        "/api/v1/incidents/duplicates/search", headers=headers, json=search
    ).json()["items"]


def test_confirmations_and_resolution_dispute(client, headers, incident_payload, db):
    incident = publish(client, headers, incident_payload).json()
    path = f"/api/v1/incidents/{incident['id']}/confirmations"
    assert client.post(path, headers=headers, json={"status": "resolved"}).status_code == 409
    assert client.post(path, headers=headers, json={"status": "still_exists"}).status_code == 201
    assert client.post(path, headers=headers, json={"status": "still_exists"}).status_code == 409
    assert client.get(f"/api/v1/incidents/{incident['id']}").json()["confirmation_count"] == 1
    item = db.get(Incident, UUID(incident["id"]))
    item.status = "resolved_pending_confirmation"
    db.commit()
    assert (
        client.post(path, headers=headers, json={"status": "resolved"}).json()["incident_status"]
        == "resolved"
    )
    assert (
        client.post(path, headers=headers, json={"status": "partially_resolved"}).json()[
            "incident_status"
        ]
        == "under_review"
    )


def test_status_permissions_and_organization_scope(client, headers, account, incident_payload, db):
    incident = publish(client, headers, incident_payload).json()
    path = f"/api/v1/moderation/incidents/{incident['id']}"
    assert client.patch(path, headers=headers, json={"status": "under_review"}).status_code == 403
    user = db.get(User, UUID(account["user"]["id"]))
    user.role = "moderator"
    db.commit()
    assert client.patch(path, headers=headers, json={"status": "under_review"}).status_code == 200
    assert client.patch(path, headers=headers, json={"status": "resolved"}).status_code == 409
    assert client.patch(path, headers=headers, json={"status": "accepted"}).status_code == 403
    org = Organization(name_ru="Тестовая организация", name_kk="Сынақ ұйымы")
    db.add(org)
    db.flush()
    user.role, user.organization_id = "organization", org.id
    db.commit()
    assert client.patch(path, headers=headers, json={"status": "accepted"}).status_code == 403
    db.add(
        IncidentAssignment(
            incident_id=UUID(incident["id"]), organization_id=org.id, assigned_by=user.id
        )
    )
    db.commit()
    for status in ("accepted", "in_progress", "resolved_pending_confirmation"):
        response = client.patch(path, headers=headers, json={"status": status})
        assert response.status_code == 200, response.text


def test_comments_reports_hiding(client, headers, account, incident_payload, db):
    incident = publish(client, headers, incident_payload).json()
    path = f"/api/v1/incidents/{incident['id']}/comments"
    comment = client.post(path, headers=headers, json={"text": "Подтверждаю проблему"})
    assert comment.status_code == 201
    assert len(client.get(path).json()["items"]) == 1
    report = client.post(
        "/api/v1/content-reports",
        headers=headers,
        json={"comment_id": comment.json()["id"], "reason": "Проверка жалобы"},
    )
    assert report.status_code == 201
    assert client.get("/api/v1/moderation/reports", headers=headers).status_code == 403
    db.get(User, UUID(account["user"]["id"])).role = "moderator"
    db.commit()
    assert (
        client.post(
            f"/api/v1/moderation/reports/{report.json()['id']}/resolve", headers=headers
        ).status_code
        == 200
    )
    assert client.get(path).json()["items"] == []
    hidden = client.patch(
        f"/api/v1/moderation/incidents/{incident['id']}",
        headers=headers,
        json={"status": "under_review", "is_hidden": True},
    )
    assert hidden.status_code == 200
    assert client.get(f"/api/v1/incidents/{incident['id']}").status_code == 404
    assert client.get(incident["media"][0]["url"]).status_code == 404


@pytest.mark.parametrize(
    "mime,data",
    [("image/jpeg", b"not an image"), ("image/svg+xml", b"<svg/>"), ("image/png", b"GIF89a")],
)
def test_invalid_uploads(client, headers, mime, data):
    response = client.post(
        "/api/v1/uploads/images", headers=headers, files={"file": ("test.jpg", data, mime)}
    )
    assert response.status_code == 415


def test_size_and_ai(client, headers, incident_payload, monkeypatch):
    from app.core.config import get_settings

    monkeypatch.setattr(get_settings(), "max_image_bytes", 8)
    response = client.post(
        "/api/v1/uploads/images",
        headers=headers,
        files={"file": ("test.jpg", b"x" * 9, "image/jpeg")},
    )
    assert response.status_code == 413
    result = client.post(
        "/api/v1/incidents/analyze",
        headers=headers,
        json={"upload_id": incident_payload["upload_ids"][0], "description": "Открытый люк"},
    )
    assert result.status_code == 200
    assert result.json()["result"]["category_code"] == "open_manhole"
    assert result.json()["requires_review"] is True


def test_chunked_request_is_bounded_before_json_parsing(client):
    response = client.post(
        "/api/v1/auth/register",
        content=iter([b" " * (1024 * 1024) for _ in range(17)]),
        headers={"Content-Type": "application/json"},
    )
    assert response.status_code == 413
    assert response.json()["error"]["code"] == "file_too_large"
