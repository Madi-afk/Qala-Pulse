from uuid import UUID, uuid4

import pytest
from sqlalchemy import func, select

from app.db.models import (
    AuditLog,
    Comment,
    ContentReport,
    Incident,
    IncidentMedia,
    Organization,
    TimelineEvent,
)
from tests.test_confirmation_cycles import actor


@pytest.fixture
def workspace(client, db, account, headers, incident_payload):
    org = Organization(name_ru="Test service", name_kk="Test service")
    other = Organization(name_ru="Other service", name_kk="Other service")
    db.add_all([org, other])
    db.commit()
    moderator, _ = actor(client, db, "moderator")
    assigned_org, _ = actor(client, db, "organization", org.id)
    other_org, _ = actor(client, db, "organization", other.id)
    item = client.post(
        "/api/v1/incidents",
        headers={**headers, "Idempotency-Key": str(uuid4())},
        json=incident_payload,
    ).json()
    incident = db.get(Incident, UUID(item["id"]))
    assert incident
    for i in range(24):
        db.add(
            Incident(
                author_id=incident.author_id,
                category_id="road_damage",
                title=f"Test road {i}",
                description="Test pothole",
                latitude=incident.latitude,
                longitude=incident.longitude,
                location=incident.location,
                severity=5,
                is_published=i != 23,
                is_hidden=i == 22,
            )
        )
    db.commit()
    return item, org, moderator, assigned_org, other_org


def test_queue_permissions_filters_and_pagination(client, db, headers, workspace):
    item, org, mod, organization, other = workspace
    path = "/api/v1/operations/incidents"
    assert client.get(path).status_code == 401
    assert client.get(path, headers=headers).status_code == 403
    assert client.get(path, headers=organization).json()["total"] == 0
    result = client.get(path, headers=mod).json()
    assert result["total"] == 23 and result["has_more"]
    assert len(result["items"]) == 20
    second = client.get(path + "?page=2", headers=mod).json()
    assert len(second["items"]) == 3 and not second["has_more"]
    assert not {i["id"] for i in result["items"]} & {i["id"] for i in second["items"]}
    assert client.get(path + "?visibility=hidden", headers=mod).json()["total"] == 1
    assert client.get(path + "?q=Test%20road%2021", headers=mod).json()["total"] == 1
    assert client.get(path + "?q=%25", headers=mod).json()["total"] == 0
    assert client.get(path + "?page_size=1000", headers=mod).status_code == 422
    assert client.get(path + "?status=resolved", headers=mod).json()["total"] == 0
    assigned = client.post(
        f"/api/v1/moderation/incidents/{item['id']}/assignments",
        headers=mod,
        json={"organization_id": str(org.id), "executor_name": "Team A"},
    )
    assert assigned.status_code == 201
    queue = client.get(path + "?visibility=all", headers=organization).json()
    assert queue["total"] == 1 and queue["items"][0]["assignment"]["executor_name"] == "Team A"
    assert client.get(path, headers=other).json()["total"] == 0


def test_hidden_media_and_staff_detail_authorization(client, db, headers, workspace):
    item, org, mod, organization, other = workspace
    path = f"/api/v1/operations/incidents/{item['id']}"
    for suffix in ("", "/activity", "/duplicates"):
        assert client.get(path + suffix, headers=headers).status_code == 403
        assert client.get(path + suffix, headers=other).status_code == 403
    details = client.get(path, headers=mod).json()
    image = details["media"][0]["url"]
    assert client.get(image, headers=mod).status_code == 200
    assert client.get(image, headers=other).status_code == 403
    assert "original" not in str(details["media"])
    client.patch(
        f"/api/v1/moderation/incidents/{item['id']}",
        headers=mod,
        json={"status": "under_review", "is_hidden": True},
    )
    assert client.get(image, headers=mod).status_code == 200
    assert client.get(f"/api/v1/incidents/{item['id']}").status_code == 404
    hidden = db.get(Incident, UUID(item["id"]))
    hidden.is_published = False
    db.commit()
    assert client.get(path, headers=mod).status_code == 409
    assert (
        client.post(
            f"/api/v1/moderation/incidents/{item['id']}/assignments",
            headers=mod,
            json={"organization_id": str(org.id)},
        ).status_code
        == 409
    )


def test_assignment_status_response_and_result_photo(client, db, photo, workspace):
    item, org, mod, organization, other = workspace
    path = f"/api/v1/moderation/incidents/{item['id']}"
    ops = f"/api/v1/operations/incidents/{item['id']}"
    assert (
        client.post(
            path + "/assignments", headers=organization, json={"organization_id": str(org.id)}
        ).status_code
        == 403
    )
    assert (
        client.post(
            path + "/assignments", headers=mod, json={"organization_id": str(org.id)}
        ).status_code
        == 201
    )
    assert (
        client.post(
            path + "/assignments",
            headers=organization,
            json={
                "organization_id": str(org.id),
                "executor_name": "Crew 12",
                "due_at": "2026-11-01T10:00:00Z",
            },
        ).status_code
        == 201
    )
    assert client.get(ops, headers=organization).json()["allowed_statuses"] == ["accepted"]
    for status in ("accepted", "in_progress", "resolved_pending_confirmation"):
        assert client.patch(path, headers=organization, json={"status": status}).status_code == 200
    assert client.patch(path, headers=organization, json={"status": "resolved"}).status_code == 403
    # Moderators can correct category without taking an organization's action.
    assert (
        client.patch(
            path,
            headers=mod,
            json={"status": "resolved_pending_confirmation", "category_id": "other"},
        ).status_code
        == 200
    )
    assert (
        client.patch(
            path,
            headers=organization,
            json={"status": "resolved_pending_confirmation", "category_id": "garbage"},
        ).status_code
        == 403
    )
    response = client.post(
        ops + "/responses", headers=organization, json={"text": "Repairs completed; please check."}
    )
    assert response.status_code == 201
    assert (
        client.get(f"/api/v1/incidents/{item['id']}/comments").json()["items"][0]["text"]
        == "Repairs completed; please check."
    )
    assert (
        client.post(ops + "/responses", headers=other, json={"text": "forbidden"}).status_code
        == 403
    )
    assert (
        client.post(ops + "/responses", headers=mod, json={"text": "forbidden"}).status_code == 403
    )
    assert db.scalar(select(AuditLog).where(AuditLog.action == "organization_response"))
    upload = client.post(
        "/api/v1/uploads/images",
        headers=organization,
        files={"file": ("after.jpg", photo, "image/jpeg")},
    ).json()
    photo_path = path + f"/after-photo/{upload['id']}"
    assert client.post(photo_path, headers=organization).status_code == 422
    first = client.post(photo_path + "?reviewed_by_user=true", headers=organization)
    second = client.post(photo_path + "?reviewed_by_user=true", headers=organization)
    assert first.status_code == 201 and second.json()["id"] == first.json()["id"]
    assert (
        db.scalar(
            select(func.count())
            .select_from(IncidentMedia)
            .where(IncidentMedia.media_type == "after_image")
        )
        == 1
    )
    assert client.post(photo_path + "?reviewed_by_user=true", headers=other).status_code == 403


def test_reports_include_comment_context_and_resolve_once(client, db, workspace):
    item, org, mod, organization, other = workspace
    comment = Comment(
        incident_id=UUID(item["id"]),
        author_id=db.get(Incident, UUID(item["id"])).author_id,
        text="Content to review",
    )
    db.add(comment)
    db.flush()
    report = ContentReport(
        reporter_id=comment.author_id, comment_id=comment.id, reason="Test complaint"
    )
    db.add(report)
    db.commit()
    assert client.get("/api/v1/operations/reports", headers=organization).status_code == 403
    row = client.get("/api/v1/operations/reports", headers=mod).json()["items"][0]
    assert row["incident_id"] == item["id"] and row["text"] == comment.text
    path = f"/api/v1/moderation/reports/{report.id}/resolve"
    assert client.post(path + "?hide=true", headers=mod).status_code == 200
    assert client.post(path + "?hide=false", headers=mod).status_code == 409
    assert client.get("/api/v1/operations/reports", headers=mod).json()["total"] == 0
    assert (
        client.get("/api/v1/operations/reports?status=actioned", headers=mod).json()["total"] == 1
    )
    assert db.get(Comment, comment.id).is_hidden
    assert not db.get(Incident, UUID(item["id"])).is_hidden


def test_duplicates_require_explicit_merge_and_exclude_self(client, db, workspace):
    item, org, mod, organization, other = workspace
    original = db.get(Incident, UUID(item["id"]))
    target = Incident(
        author_id=original.author_id,
        category_id=original.category_id,
        title=original.title,
        description=original.description,
        latitude=original.latitude,
        longitude=original.longitude,
        location=original.location,
        severity=5,
    )
    db.add(target)
    db.commit()
    result = client.get(f"/api/v1/operations/incidents/{item['id']}/duplicates", headers=mod).json()
    assert not result["automatic_merge"]
    assert str(target.id) in [str(c["incident"]["id"]) for c in result["items"]]
    assert item["id"] not in [c["incident"]["id"] for c in result["items"]]
    assert not original.is_hidden
    path = f"/api/v1/moderation/incidents/{item['id']}/merge"
    assert (
        client.post(
            path, headers=organization, json={"target_incident_id": str(target.id)}
        ).status_code
        == 403
    )
    assert (
        client.post(path, headers=mod, json={"target_incident_id": str(target.id)}).status_code
        == 200
    )
    assert original.is_hidden


def test_activity_paginated_and_organizations_scoped(client, db, workspace):
    item, org, mod, organization, other = workspace
    for i in range(25):
        db.add(TimelineEvent(incident_id=UUID(item["id"]), status="published", note=str(i)))
    db.commit()
    path = f"/api/v1/operations/incidents/{item['id']}/activity"
    first = client.get(path, headers=mod).json()
    second = client.get(path + "?page=2", headers=mod).json()
    assert len(first["items"]) == 20 and first["has_more"]
    assert len(second["items"]) == 6 and not second["has_more"]
    assert client.get("/api/v1/operations/organizations", headers=organization).json()["items"][0][
        "id"
    ] == str(org.id)
    assert (
        len(client.get("/api/v1/operations/organizations", headers=organization).json()["items"])
        == 1
    )


def test_console_static_security_headers(client):
    response = client.get("/console/")
    assert response.status_code == 200
    assert "script-src 'self'" in response.headers["content-security-policy"]
    assert "frame-ancestors 'none'" in response.headers["content-security-policy"]
    assert response.headers["cache-control"] == "no-store"
    assert client.get("/console/app.js").status_code == 200
    assert client.get("/console/../core/config.py").status_code == 404


def test_stale_status_form_cannot_overwrite_another_moderator(client, workspace):
    item, _, mod, _, _ = workspace
    path = f"/api/v1/moderation/incidents/{item['id']}"
    first = client.patch(
        path,
        headers=mod,
        json={"status": "under_review", "expected_updated_at": item["updated_at"]},
    )
    assert first.status_code == 200
    stale = client.patch(
        path, headers=mod, json={"status": "rejected", "expected_updated_at": item["updated_at"]}
    )
    assert stale.status_code == 409
    assert stale.json()["error"]["code"] == "incident_changed"
    assert (
        client.get(f"/api/v1/operations/incidents/{item['id']}", headers=mod).json()["status"]
        == "under_review"
    )
