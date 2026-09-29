from uuid import uuid4

from app.db.models import Category


def test_category_rejection_can_be_corrected_without_losing_upload(
    client, db, headers, incident_payload
):
    key = str(uuid4())
    db.get(Category, incident_payload["category_id"]).is_active = False
    db.commit()
    result = client.post(
        "/api/v1/incidents", headers=headers | {"Idempotency-Key": key}, json=incident_payload
    )
    assert result.status_code == 422
    assert result.json()["error"]["code"] == "invalid_category"
    assert client.get("/api/v1/incidents").json()["total"] == 0
    db.get(Category, incident_payload["category_id"]).is_active = True
    db.commit()
    late = client.post(
        "/api/v1/incidents", headers=headers | {"Idempotency-Key": key}, json=incident_payload
    )
    assert late.status_code == 409
    assert late.json()["error"]["code"] == "publication_cancelled"
    corrected = client.post(
        "/api/v1/incidents",
        headers=headers | {"Idempotency-Key": str(uuid4())},
        json=incident_payload | {"category_id": "other"},
    )
    assert corrected.status_code == 201
    assert client.get("/api/v1/incidents").json()["total"] == 1


def test_cancel_fences_late_publication_and_allows_new_key(client, headers, incident_payload):
    key = str(uuid4())
    path = f"/api/v1/incidents/publications/{key}/cancel"
    assert client.post(path, headers=headers).json()["status"] == "cancelled"
    assert client.post(path, headers=headers).json()["status"] == "cancelled"
    late = client.post(
        "/api/v1/incidents", headers=headers | {"Idempotency-Key": key}, json=incident_payload
    )
    assert late.status_code == 409
    assert late.json()["error"]["code"] == "publication_cancelled"
    assert client.get("/api/v1/incidents").json()["total"] == 0
    assert (
        client.post(
            "/api/v1/incidents",
            headers=headers | {"Idempotency-Key": str(uuid4())},
            json=incident_payload,
        ).status_code
        == 201
    )


def test_recovery_returns_existing_incident_even_if_category_disabled(
    client, db, headers, incident_payload
):
    key = str(uuid4())
    incident = client.post(
        "/api/v1/incidents", headers=headers | {"Idempotency-Key": key}, json=incident_payload
    ).json()
    db.get(Category, incident_payload["category_id"]).is_active = False
    db.commit()
    retry = client.post(
        "/api/v1/incidents", headers=headers | {"Idempotency-Key": key}, json=incident_payload
    )
    assert retry.json()["id"] == incident["id"]
    recovered = client.post(f"/api/v1/incidents/publications/{key}/cancel", headers=headers).json()
    assert recovered["status"] == "published"
    assert recovered["incident"]["id"] == incident["id"]
    assert client.get("/api/v1/incidents").json()["total"] == 1
