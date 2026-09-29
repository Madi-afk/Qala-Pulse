from uuid import UUID, uuid4

import pytest
from sqlalchemy import func, select

from app.db.models import IncidentAssignment, IncidentConfirmation, Organization, User


def actor(client, db, role, organization_id=None):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"{uuid4()}@example.com",
            "password": "Test-only-2026!",
            "display_name": "Regression actor",
        },
    ).json()
    user = db.get(User, UUID(response["user"]["id"]))
    user.role, user.organization_id = role, organization_id
    db.commit()
    return {"Authorization": f"Bearer {response['access_token']}"}, user.id


@pytest.fixture
def assigned(client, db, headers, incident_payload):
    item = client.post(
        "/api/v1/incidents",
        headers={**headers, "Idempotency-Key": str(uuid4())},
        json=incident_payload,
    ).json()
    org = Organization(name_ru="Тест", name_kk="Сынақ")
    db.add(org)
    db.flush()
    organization_headers, user_id = actor(client, db, "organization", org.id)
    db.add(
        IncidentAssignment(
            incident_id=UUID(item["id"]), organization_id=org.id, assigned_by=user_id
        )
    )
    db.commit()
    return item["id"], organization_headers


def complete(client, incident_id, organization_headers):
    for status in ("accepted", "in_progress", "resolved_pending_confirmation"):
        response = client.patch(
            f"/api/v1/moderation/incidents/{incident_id}",
            headers=organization_headers,
            json={"status": status},
        )
        assert response.status_code == 200, response.text


@pytest.mark.parametrize("role", ["assigned_organization", "organization", "moderator", "admin"])
def test_only_citizen_can_confirm_repair(client, db, headers, assigned, role):
    incident_id, organization_headers = assigned
    complete(client, incident_id, organization_headers)
    forbidden_headers = (
        organization_headers if role == "assigned_organization" else actor(client, db, role)[0]
    )
    path = f"/api/v1/incidents/{incident_id}/confirmations"
    response = client.post(path, headers=forbidden_headers, json={"status": "resolved"})
    assert response.status_code == 403
    assert (
        client.get(f"/api/v1/incidents/{incident_id}").json()["status"]
        == "resolved_pending_confirmation"
    )
    assert (
        client.post(path, headers=headers, json={"status": "resolved"}).json()["incident_status"]
        == "resolved"
    )


def test_supporter_can_dispute_and_confirm_later_cycle(client, db, headers, assigned):
    incident_id, organization_headers = assigned
    path = f"/api/v1/incidents/{incident_id}/confirmations"
    assert client.post(path, headers=headers, json={"status": "still_exists"}).status_code == 201
    complete(client, incident_id, organization_headers)
    disputed = client.post(path, headers=headers, json={"status": "still_exists"})
    assert disputed.status_code == 201
    assert disputed.json()["incident_status"] == "under_review"
    assert client.post(path, headers=headers, json={"status": "still_exists"}).status_code == 409
    assert client.get(f"/api/v1/incidents/{incident_id}").json()["confirmation_count"] == 1
    complete(client, incident_id, organization_headers)
    assert (
        client.post(path, headers=headers, json={"status": "resolved"}).json()["incident_status"]
        == "resolved"
    )
    assert client.post(path, headers=headers, json={"status": "resolved"}).status_code == 409
    assert (
        db.scalar(
            select(func.count())
            .select_from(IncidentConfirmation)
            .where(IncidentConfirmation.incident_id == UUID(incident_id))
        )
        == 3
    )
    assert client.get(f"/api/v1/incidents/{incident_id}").json()["confirmation_count"] == 1
