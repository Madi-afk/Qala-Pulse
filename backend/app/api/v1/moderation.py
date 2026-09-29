from typing import Any
from uuid import UUID

from fastapi import APIRouter, Query
from sqlalchemy import select

from app.api.deps import Actor, Db, require_role
from app.api.v1.incidents import validate_category
from app.core.errors import fail
from app.db.models import (
    AuditLog,
    Category,
    Comment,
    ContentReport,
    Incident,
    IncidentAssignment,
    IncidentDuplicate,
    IncidentMedia,
    Organization,
    TimelineEvent,
    User,
)
from app.repositories.incidents import get_visible, recalculate, serialize
from app.schemas.common import (
    AssignmentCreate,
    CategoryCode,
    CategoryPatch,
    MergeCreate,
    RoleChange,
    StatusChange,
)
from app.services.geospatial.priority import distance_meters

router = APIRouter(tags=["moderation"])
TRANSITIONS = {
    "published": {"under_review", "accepted", "rejected"},
    "under_review": {"published", "accepted", "rejected"},
    "accepted": {"in_progress", "under_review"},
    "in_progress": {"resolved_pending_confirmation", "under_review"},
    "resolved_pending_confirmation": {"under_review", "in_progress"},
    "resolved": {"under_review"},
    "rejected": {"under_review"},
}


@router.get("/moderation/incidents")
def queue(
    db: Db, user: Actor, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    require_role(user, "moderator", "admin")
    rows = db.scalars(
        select(Incident)
        .where(Incident.is_published.is_(True))
        .order_by(Incident.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {"items": [serialize(db, item) | {"is_hidden": item.is_hidden} for item in rows]}


@router.patch("/moderation/incidents/{incident_id}")
def moderate(incident_id: UUID, data: StatusChange, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "moderator", "organization", "admin")
    item = get_visible(db, incident_id, user, lock=True)
    if not item.is_published:
        raise fail("draft_private", "Черновик не опубликован", 409)
    if user.role == "organization":
        assignment = db.scalar(
            select(IncidentAssignment).where(IncidentAssignment.incident_id == item.id)
        )
        if assignment is None or assignment.organization_id != user.organization_id:
            raise fail("forbidden", "Обращение не назначено вашей организации", 403)
        if (
            data.category_id is not None
            or data.is_hidden is not None
            or data.status not in ("accepted", "in_progress", "resolved_pending_confirmation")
        ):
            raise fail("forbidden", "Недостаточно прав", 403)
    if user.role == "moderator" and data.status in (
        "accepted",
        "in_progress",
        "resolved_pending_confirmation",
    ):
        raise fail("organization_required", "Нужно действие назначенной организации", 403)
    if data.status != item.status and data.status not in TRANSITIONS[item.status]:
        raise fail("invalid_transition", "Недопустимый переход статуса", 409)
    if data.status in (
        "accepted",
        "in_progress",
        "resolved_pending_confirmation",
    ) and not db.scalar(
        select(IncidentAssignment).where(IncidentAssignment.incident_id == item.id)
    ):
        raise fail("assignment_required", "Сначала назначьте организацию", 409)
    old = {"status": item.status, "category_id": item.category_id, "is_hidden": item.is_hidden}
    item.status = data.status
    if data.category_id:
        validate_category(db, data.category_id)
        item.category_id = data.category_id
    if data.is_hidden is not None:
        item.is_hidden = data.is_hidden
    if item.status != "resolved":
        item.resolved_at = None
    db.add(TimelineEvent(incident_id=item.id, status=item.status, note=data.note))
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="incident",
            entity_id=item.id,
            action="moderate",
            old_data=old,
            new_data=data.model_dump(exclude_none=True),
        )
    )
    recalculate(db, item)
    db.flush()
    return serialize(db, item)


@router.post("/moderation/incidents/{incident_id}/assignments", status_code=201)
def assign(incident_id: UUID, data: AssignmentCreate, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "moderator", "admin", "organization")
    get_visible(db, incident_id, user, lock=True)
    item = db.scalar(
        select(IncidentAssignment).where(IncidentAssignment.incident_id == incident_id)
    )
    if user.role == "organization" and (
        item is None
        or item.organization_id != user.organization_id
        or data.organization_id != user.organization_id
    ):
        raise fail("forbidden", "Недостаточно прав", 403)
    if db.get(Organization, data.organization_id) is None:
        raise fail("organization_not_found", "Организация не найдена", 404)
    if item is None:
        item = IncidentAssignment(incident_id=incident_id, assigned_by=user.id, **data.model_dump())
        db.add(item)
    else:
        for key, value in data.model_dump().items():
            setattr(item, key, value)
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="incident",
            entity_id=incident_id,
            action="assign",
            new_data={"organization_id": str(data.organization_id)},
        )
    )
    db.flush()
    return {"id": item.id, "organization_id": item.organization_id}


@router.post("/moderation/incidents/{incident_id}/after-photo/{upload_id}", status_code=201)
def after_photo(incident_id: UUID, upload_id: UUID, db: Db, user: Actor) -> dict[str, Any]:
    from app.api.v1.uploads import owned_upload
    from app.core.config import get_settings

    require_role(user, "organization", "admin")
    get_visible(db, incident_id, user)
    assignment = db.scalar(
        select(IncidentAssignment).where(IncidentAssignment.incident_id == incident_id)
    )
    if user.role != "admin" and (
        assignment is None or assignment.organization_id != user.organization_id
    ):
        raise fail("forbidden", "Недостаточно прав", 403)
    upload = owned_upload(db, upload_id, user.id)
    if not upload.redacted_key:
        raise fail("redaction_required", "Нужна обработанная фотография", 422)
    root = f"{get_settings().public_api_url}/api/v1/media/{upload.id}"
    media = IncidentMedia(
        incident_id=incident_id,
        upload_id=upload.id,
        media_type="after_image",
        original_url=upload.original_key,
        redacted_url=f"{root}/image",
        thumbnail_url=f"{root}/thumbnail",
    )
    db.add(media)
    db.add(
        AuditLog(
            actor_id=user.id, entity_type="incident", entity_id=incident_id, action="after_photo"
        )
    )
    db.flush()
    return {"id": media.id, "url": media.redacted_url}


@router.post("/moderation/incidents/{incident_id}/merge")
def merge(incident_id: UUID, data: MergeCreate, db: Db, user: Actor) -> dict[str, Any]:
    require_role(user, "moderator", "admin")
    if incident_id == data.target_incident_id:
        raise fail("invalid_merge", "Нельзя объединить обращение с самим собой", 422)
    items = {
        key: get_visible(db, key, user, lock=True)
        for key in sorted([incident_id, data.target_incident_id])
    }
    source, target = items[incident_id], items[data.target_incident_id]
    if source.is_hidden or target.is_hidden or not source.is_published or not target.is_published:
        raise fail("invalid_merge", "Нужны два доступных обращения", 409)
    source.is_hidden = True
    db.add(
        IncidentDuplicate(
            source_incident_id=source.id,
            target_incident_id=target.id,
            similarity_score=1,
            distance_meters=distance_meters(
                source.latitude, source.longitude, target.latitude, target.longitude
            ),
            text_similarity=0,
            status="confirmed",
        )
    )
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="incident",
            entity_id=source.id,
            action="merge",
            new_data={"target_id": str(target.id)},
        )
    )
    return {"target_id": target.id}


@router.get("/moderation/reports")
def reports(
    db: Db, user: Actor, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100)
) -> dict[str, Any]:
    require_role(user, "moderator", "admin")
    rows = db.scalars(
        select(ContentReport)
        .where(ContentReport.status == "pending")
        .order_by(ContentReport.created_at)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "id": r.id,
                "incident_id": r.incident_id,
                "comment_id": r.comment_id,
                "reason": r.reason,
            }
            for r in rows
        ]
    }


@router.post("/moderation/reports/{report_id}/resolve")
def resolve_report(report_id: UUID, db: Db, user: Actor, hide: bool = True) -> dict[str, str]:
    require_role(user, "moderator", "admin")
    report = db.get(ContentReport, report_id)
    if report is None:
        raise fail("not_found", "Жалоба не найдена", 404)
    if hide:
        target = (
            db.get(Incident, report.incident_id)
            if report.incident_id
            else db.get(Comment, report.comment_id)
        )
        if target:
            target.is_hidden = True
    report.status = "actioned" if hide else "dismissed"
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="content_report",
            entity_id=report.id,
            action=report.status,
        )
    )
    return {"status": report.status}


@router.patch("/admin/categories/{code}")
def category_update(code: CategoryCode, data: CategoryPatch, db: Db, user: Actor) -> dict[str, str]:
    require_role(user, "admin")
    category = db.get(Category, code)
    if category is None:
        raise fail("category_not_found", "Категория не найдена", 404)
    for key, value in data.model_dump().items():
        setattr(category, key, value)
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="category",
            entity_id=user.id,
            action="category_update",
            new_data={"code": code, **data.model_dump()},
        )
    )
    return {"code": code}


@router.patch("/admin/users/{user_id}/role")
def role_update(user_id: UUID, data: RoleChange, db: Db, user: Actor) -> dict[str, str]:
    require_role(user, "admin")
    target = db.get(User, user_id)
    if target is None:
        raise fail("user_not_found", "Пользователь не найден", 404)
    if data.role == "organization" and (
        data.organization_id is None or db.get(Organization, data.organization_id) is None
    ):
        raise fail("organization_required", "Укажите организацию", 422)
    old_role = target.role
    target.role, target.organization_id = data.role, data.organization_id
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="user",
            entity_id=target.id,
            action="role_update",
            old_data={"role": old_role},
            new_data={"role": data.role},
        )
    )
    return {"role": target.role}


@router.get("/admin/audit")
def audit(
    db: Db, user: Actor, page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=100)
) -> dict[str, Any]:
    require_role(user, "admin")
    rows = db.scalars(
        select(AuditLog)
        .order_by(AuditLog.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "id": r.id,
                "actor_id": r.actor_id,
                "entity_type": r.entity_type,
                "entity_id": r.entity_id,
                "action": r.action,
                "old_data": r.old_data,
                "new_data": r.new_data,
                "created_at": r.created_at,
            }
            for r in rows
        ]
    }
