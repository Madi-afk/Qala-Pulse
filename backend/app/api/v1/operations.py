from typing import Any, Literal
from uuid import UUID

from fastapi import APIRouter, Query, Response
from sqlalchemy import func, or_, select

from app.api.deps import Actor, Db, require_role
from app.core.errors import fail
from app.db.models import (
    AuditLog,
    Comment,
    ContentReport,
    Incident,
    IncidentAssignment,
    IncidentMedia,
    Organization,
    TimelineEvent,
    Upload,
    User,
)
from app.repositories.operations import staff_incident, staff_serialize
from app.schemas.common import CategoryCode, CommentCreate, DuplicateSearch, IncidentStatus
from app.services.duplicate_detection.detector import GeoTextDuplicateDetector
from app.services.storage.objects import ObjectStorage

router = APIRouter(prefix="/operations", tags=["operations"])


@router.get("/incidents")
def queue(
    db: Db,
    user: Actor,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    q: str = Query("", max_length=160),
    status: IncidentStatus | None = None,
    category_id: CategoryCode | None = None,
    visibility: Literal["visible", "hidden", "all"] = "visible",
    unassigned: bool = False,
    sort: Literal["priority", "newest", "oldest"] = "priority",
) -> dict[str, Any]:
    require_role(user, "moderator", "organization", "admin")
    query = select(Incident).where(Incident.is_published.is_(True))
    if user.role == "organization":
        query = query.join(IncidentAssignment).where(
            IncidentAssignment.organization_id == user.organization_id,
            Incident.is_hidden.is_(False),
        )
    elif visibility != "all":
        query = query.where(Incident.is_hidden == (visibility == "hidden"))
    if q.strip():
        query = query.where(
            or_(
                Incident.title.icontains(q.strip(), autoescape=True),
                Incident.address.icontains(q.strip(), autoescape=True),
            )
        )
    if status:
        query = query.where(Incident.status == status)
    if category_id:
        query = query.where(Incident.category_id == category_id)
    if unassigned:
        query = query.where(
            ~select(IncidentAssignment.id)
            .where(IncidentAssignment.incident_id == Incident.id)
            .exists()
        )
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    order: Any = {
        "priority": Incident.priority_score.desc(),
        "newest": Incident.created_at.desc(),
        "oldest": Incident.created_at.asc(),
    }[sort]
    rows = db.scalars(
        query.order_by(order, Incident.id).offset((page - 1) * page_size).limit(page_size)
    )
    return {
        "items": [staff_serialize(db, i, user) for i in rows],
        "total": total,
        "page": page,
        "has_more": page * page_size < total,
    }


@router.get("/organizations")
def organizations(
    db: Db, user: Actor, q: str = Query("", max_length=100), page: int = Query(1, ge=1)
) -> dict[str, Any]:
    require_role(user, "moderator", "organization", "admin")
    query = select(Organization)
    if user.role == "organization":
        query = query.where(Organization.id == user.organization_id)
    if q:
        query = query.where(Organization.name_ru.icontains(q, autoescape=True))
    rows = list(
        db.scalars(
            query.order_by(Organization.name_ru, Organization.id).offset((page - 1) * 50).limit(51)
        )
    )
    return {
        "items": [{"id": o.id, "name_ru": o.name_ru, "name_kk": o.name_kk} for o in rows[:50]],
        "has_more": len(rows) > 50,
    }


@router.get("/incidents/{incident_id}")
def detail(incident_id: UUID, db: Db, user: Actor) -> dict[str, Any]:
    item = staff_incident(db, incident_id, user)
    result = staff_serialize(db, item, user)
    result["media"] = [
        {
            "id": m.id,
            "media_type": m.media_type,
            "url": f"/api/v1/operations/incidents/{item.id}/media/{m.id}",
        }
        for m in db.scalars(select(IncidentMedia).where(IncidentMedia.incident_id == item.id))
        if m.redacted_url
    ]
    return result


@router.get("/incidents/{incident_id}/media/{media_id}")
def media(incident_id: UUID, media_id: UUID, db: Db, user: Actor) -> Response:
    staff_incident(db, incident_id, user)
    row = db.get(IncidentMedia, media_id)
    if row is None or row.incident_id != incident_id:
        raise fail("not_found", "Фотография не найдена", 404)
    upload = db.get(Upload, row.upload_id)
    if upload is None or not upload.redacted_key:
        raise fail("not_found", "Фотография недоступна", 404)
    return Response(
        ObjectStorage().get(upload.redacted_key, public=True),
        media_type="image/jpeg",
        headers={"Cache-Control": "private, no-store"},
    )


@router.get("/incidents/{incident_id}/activity")
def activity(
    incident_id: UUID,
    db: Db,
    user: Actor,
    kind: Literal["timeline", "comments"] = "timeline",
    page: int = Query(1, ge=1),
) -> dict[str, Any]:
    staff_incident(db, incident_id, user)
    if kind == "timeline":
        events = list(
            db.scalars(
                select(TimelineEvent)
                .where(TimelineEvent.incident_id == incident_id)
                .order_by(TimelineEvent.created_at.desc(), TimelineEvent.id)
                .offset((page - 1) * 20)
                .limit(21)
            )
        )
        return {
            "items": [
                {"id": e.id, "status": e.status, "note": e.note, "created_at": e.created_at}
                for e in events[:20]
            ],
            "has_more": len(events) > 20,
        }
    query = (
        select(Comment, User.display_name)
        .join(User, User.id == Comment.author_id)
        .where(Comment.incident_id == incident_id)
    )
    if user.role == "organization":
        query = query.where(Comment.is_hidden.is_(False))
    rows = list(
        db.execute(
            query.order_by(Comment.created_at.desc(), Comment.id).offset((page - 1) * 20).limit(21)
        )
    )
    return {
        "items": [
            {
                "id": c.id,
                "text": c.text,
                "author_name": name,
                "is_hidden": c.is_hidden,
                "created_at": c.created_at,
            }
            for c, name in rows[:20]
        ],
        "has_more": len(rows) > 20,
    }


@router.get("/incidents/{incident_id}/duplicates")
def duplicates(incident_id: UUID, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "moderator", "admin")
    item = staff_incident(db, incident_id, user)
    candidates = GeoTextDuplicateDetector().search(
        db,
        DuplicateSearch.model_validate(
            {
                "latitude": item.latitude,
                "longitude": item.longitude,
                "category_id": item.category_id,
                "title": item.title,
                "description": item.description,
            }
        ),
    )
    return {
        "items": [c for c in candidates if c["incident"]["id"] != item.id],
        "automatic_merge": False,
    }


@router.post("/incidents/{incident_id}/responses", status_code=201)
def respond(incident_id: UUID, data: CommentCreate, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "organization", "admin")
    item = staff_incident(db, incident_id, user, lock=True)
    if item.is_hidden:
        raise fail("incident_hidden", "Сначала восстановите видимость обращения", 409)
    comment = Comment(incident_id=item.id, author_id=user.id, text=data.text)
    db.add(comment)
    db.flush()
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="comment",
            entity_id=comment.id,
            action="organization_response",
            new_data={"incident_id": str(item.id)},
        )
    )
    db.add(
        TimelineEvent(
            incident_id=item.id, status=item.status, note=f"Ответ организации: {data.text[:950]}"
        )
    )
    return {"id": comment.id, "text": comment.text}


@router.get("/reports")
def reports(
    db: Db,
    user: Actor,
    status: Literal["pending", "actioned", "dismissed"] = "pending",
    page: int = Query(1, ge=1),
) -> dict[str, Any]:
    require_role(user, "moderator", "admin")
    query = select(ContentReport).where(ContentReport.status == status)
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    rows = db.scalars(
        query.order_by(ContentReport.created_at, ContentReport.id).offset((page - 1) * 20).limit(20)
    )
    result = []
    for r in rows:
        comment = db.get(Comment, r.comment_id) if r.comment_id else None
        incident_id = r.incident_id or (comment.incident_id if comment else None)
        incident = db.get(Incident, incident_id) if incident_id else None
        result.append(
            {
                "id": r.id,
                "incident_id": incident.id if incident else None,
                "title": incident.title if incident else "Обращение недоступно",
                "comment_id": r.comment_id,
                "text": comment.text if comment else (incident.description if incident else ""),
                "reason": r.reason,
                "status": r.status,
                "created_at": r.created_at,
            }
        )
    return {"items": result, "total": total, "has_more": page * 20 < total, "page": page}
