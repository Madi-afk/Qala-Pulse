from typing import Any
from uuid import UUID

from fastapi import APIRouter, Query
from sqlalchemy import select

from app.api.deps import Actor, Db, require_role
from app.core.errors import fail
from app.db.base import utcnow
from app.db.models import (
    AuditLog,
    Comment,
    ContentReport,
    Incident,
    IncidentConfirmation,
    TimelineEvent,
    User,
)
from app.repositories.incidents import get_visible, recalculate
from app.schemas.common import CommentCreate, ConfirmationCreate, ReportCreate

router = APIRouter(tags=["community"])


@router.post("/incidents/{incident_id}/confirmations", status_code=201)
def confirm(incident_id: UUID, data: ConfirmationCreate, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "citizen")
    item = get_visible(db, incident_id, lock=True)
    if db.scalar(
        select(IncidentConfirmation).where(
            IncidentConfirmation.incident_id == incident_id,
            IncidentConfirmation.user_id == user.id,
            IncidentConfirmation.status == data.status,
            IncidentConfirmation.resolution_cycle == item.resolution_cycle,
        )
    ):
        raise fail("already_confirmed", "Вы уже отправили это подтверждение", 409)
    if item.status == "rejected":
        raise fail("invalid_status", "Обращение отклонено", 409)
    if data.status == "resolved" and item.status not in (
        "resolved_pending_confirmation",
        "resolved",
    ):
        raise fail("invalid_status", "Сначала требуется отметка о выполнении", 409)
    already_supports = db.scalar(
        select(IncidentConfirmation.id)
        .where(
            IncidentConfirmation.incident_id == incident_id,
            IncidentConfirmation.user_id == user.id,
            IncidentConfirmation.status == "still_exists",
        )
        .limit(1)
    )
    confirmation = IncidentConfirmation(
        incident_id=incident_id,
        user_id=user.id,
        resolution_cycle=item.resolution_cycle,
        **data.model_dump(),
    )
    db.add(confirmation)
    if data.status == "still_exists" and not already_supports:
        item.confirmation_count += 1
    old_status = item.status
    if data.status == "resolved" and item.status == "resolved_pending_confirmation":
        item.status, item.resolved_at = "resolved", utcnow()
    elif data.status in ("still_exists", "partially_resolved") and item.status in (
        "resolved_pending_confirmation",
        "resolved",
    ):
        item.status, item.resolved_at = "under_review", None
    if old_status != item.status:
        db.add(TimelineEvent(incident_id=incident_id, status=item.status))
    recalculate(db, item)
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="incident",
            entity_id=item.id,
            action="confirmation",
            old_data={"status": old_status},
            new_data={
                "status": item.status,
                "confirmation": data.status,
                "resolution_cycle": item.resolution_cycle,
            },
        )
    )
    db.flush()
    return {
        "id": confirmation.id,
        "status": confirmation.status,
        "incident_status": item.status,
        "resolution_cycle": item.resolution_cycle,
    }


@router.get("/incidents/{incident_id}/confirmations")
def confirmations(
    incident_id: UUID, db: Db, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    get_visible(db, incident_id)
    rows = db.scalars(
        select(IncidentConfirmation)
        .where(IncidentConfirmation.incident_id == incident_id)
        .order_by(IncidentConfirmation.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "id": row.id,
                "status": row.status,
                "resolution_cycle": row.resolution_cycle,
                "comment": row.comment,
                "created_at": row.created_at,
            }
            for row in rows
        ]
    }


@router.get("/users/me/confirmations")
def my_confirmations(
    db: Db, user: Actor, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    rows = db.execute(
        select(IncidentConfirmation, Incident.title)
        .join(Incident, Incident.id == IncidentConfirmation.incident_id)
        .where(
            IncidentConfirmation.user_id == user.id,
            Incident.is_hidden.is_(False),
            Incident.is_published.is_(True),
        )
        .order_by(IncidentConfirmation.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "incident_id": row.incident_id,
                "title": title,
                "status": row.status,
                "created_at": row.created_at,
            }
            for row, title in rows
        ]
    }


@router.post("/incidents/{incident_id}/comments", status_code=201)
def comment(incident_id: UUID, data: CommentCreate, db: Db, user: Actor) -> dict[str, Any]:
    get_visible(db, incident_id)
    item = Comment(incident_id=incident_id, author_id=user.id, text=data.text)
    db.add(item)
    db.flush()
    return {
        "id": item.id,
        "text": item.text,
        "author_name": user.display_name,
        "created_at": item.created_at,
    }


@router.get("/incidents/{incident_id}/comments")
def comments(
    incident_id: UUID, db: Db, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    get_visible(db, incident_id)
    rows = db.execute(
        select(Comment, User.display_name)
        .join(User, User.id == Comment.author_id)
        .where(Comment.incident_id == incident_id, Comment.is_hidden.is_(False))
        .order_by(Comment.created_at.desc(), Comment.id)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {"id": item.id, "text": item.text, "author_name": name, "created_at": item.created_at}
            for item, name in rows
        ]
    }


@router.post("/content-reports", status_code=201)
def report(data: ReportCreate, db: Db, user: Actor) -> dict[str, Any]:
    if data.incident_id:
        get_visible(db, data.incident_id)
    if data.comment_id:
        target = db.get(Comment, data.comment_id)
        if target is None or target.is_hidden:
            raise fail("comment_not_found", "Комментарий недоступен", 404)
        get_visible(db, target.incident_id)
    item = ContentReport(reporter_id=user.id, **data.model_dump())
    db.add(item)
    db.flush()
    return {"id": item.id, "status": item.status}


@router.get("/users/me/notifications")
def notifications(
    db: Db, user: Actor, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    rows = db.execute(
        select(TimelineEvent, Incident.title)
        .join(Incident, Incident.id == TimelineEvent.incident_id)
        .where(
            Incident.author_id == user.id,
            Incident.is_hidden.is_(False),
            Incident.is_published.is_(True),
        )
        .order_by(TimelineEvent.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "id": event.id,
                "incident_id": event.incident_id,
                "title": title,
                "status": event.status,
                "created_at": event.created_at,
            }
            for event, title in rows
        ]
    }
