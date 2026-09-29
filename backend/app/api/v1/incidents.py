import hashlib
import json
from io import BytesIO
from typing import Annotated, Any, Literal
from uuid import UUID

from fastapi import APIRouter, Header, Query
from PIL import Image, ImageOps
from sqlalchemy import func, select

from app.api.deps import Actor, Db
from app.api.v1.uploads import owned_upload
from app.core.config import get_settings
from app.core.errors import fail
from app.db.base import utcnow
from app.db.models import (
    AuditLog,
    Category,
    IdempotencyRecord,
    Incident,
    IncidentMedia,
    TimelineEvent,
)
from app.repositories.incidents import get_visible, nearby, recalculate, serialize, visible_query
from app.schemas.common import (
    Analyze,
    CategoryCode,
    DuplicateSearch,
    IncidentCreate,
    IncidentPatch,
    IncidentStatus,
)
from app.services.ai.providers import analyze_with_fallback
from app.services.duplicate_detection.detector import GeoTextDuplicateDetector
from app.services.storage.objects import ObjectStorage

router = APIRouter(tags=["incidents"])


def validate_category(db: Db, code: str) -> None:
    category = db.get(Category, code)
    if category is None or not category.is_active:
        raise fail("invalid_category", "Категория недоступна", 422)


@router.get("/categories")
def categories(db: Db) -> list[dict[str, Any]]:
    return [
        {
            "id": c.id,
            "code": c.code,
            "name_ru": c.name_ru,
            "name_kk": c.name_kk,
            "description": c.description,
            "base_severity": c.base_severity,
            "icon": c.icon,
            "color": c.color,
            "is_active": c.is_active,
        }
        for c in db.scalars(
            select(Category).where(Category.is_active.is_(True)).order_by(Category.code)
        )
    ]


@router.post("/incidents/analyze")
def analyze(data: Analyze, db: Db, user: Actor) -> dict[str, Any]:
    upload = owned_upload(db, data.upload_id, user.id)
    if upload.media_type != "image":
        raise fail("invalid_image", "Нужна фотография", 422)
    raw = ObjectStorage().get(upload.original_key)
    # Strip EXIF/GPS before an explicitly consented cloud request.
    with Image.open(BytesIO(raw)) as source:
        clean = ImageOps.exif_transpose(source).convert("RGB")
        clean.thumbnail((1600, 1600))
        stream = BytesIO()
        clean.save(stream, "JPEG")
    result = analyze_with_fallback(stream.getvalue(), data.description, data.cloud_consent)
    upload.analysis = result
    return result


@router.post("/incidents/duplicates/search")
def duplicates(data: DuplicateSearch, db: Db, user: Actor) -> dict[str, Any]:
    validate_category(db, data.category_id)
    return {"items": GeoTextDuplicateDetector().search(db, data), "automatic_merge": False}


@router.post("/incidents", status_code=201)
def create(
    data: IncidentCreate,
    db: Db,
    user: Actor,
    idempotency_key: Annotated[str, Header(min_length=8, max_length=100)],
) -> dict[str, Any]:
    # Serialize concurrent requests per user before checking the unique key or media ownership.
    from app.db.models import User

    db.scalar(select(User).where(User.id == user.id).with_for_update())
    encoded = json.dumps(data.model_dump(mode="json"), sort_keys=True, ensure_ascii=False)
    request_hash = hashlib.sha256(encoded.encode()).hexdigest()
    previous = db.scalar(
        select(IdempotencyRecord).where(
            IdempotencyRecord.user_id == user.id, IdempotencyRecord.key == idempotency_key
        )
    )
    if previous:
        if previous.request_hash != request_hash:
            raise fail("idempotency_conflict", "Ключ уже использован для другого содержимого", 409)
        item = db.get(Incident, previous.incident_id)
        assert item is not None
        return serialize(db, item)
    if data.publish and not data.reviewed_by_user:
        raise fail("review_required", "Проверьте результат перед публикацией", 422)
    validate_category(db, data.category_id)
    if len(set(data.upload_ids)) != len(data.upload_ids):
        raise fail("duplicate_upload", "Файл указан несколько раз", 422)
    uploads = [owned_upload(db, upload_id, user.id) for upload_id in data.upload_ids]
    for upload in uploads:
        if upload.media_type != "image" or not upload.redacted_key:
            raise fail("redaction_required", "Изображение ещё не обработано", 422)
        if db.scalar(select(IncidentMedia.id).where(IncidentMedia.upload_id == upload.id)):
            raise fail("upload_already_used", "Файл уже опубликован", 409)
    analysis = uploads[0].analysis
    item = Incident(
        author_id=user.id,
        source="citizen",
        category_id=data.category_id,
        title=data.title,
        description=data.description,
        latitude=data.latitude,
        longitude=data.longitude,
        location=f"SRID=4326;POINT({data.longitude} {data.latitude})",
        address=data.address,
        severity=data.severity,
        is_published=data.publish,
        status="published",
        created_at=utcnow(),
        ai_confidence=analysis["result"]["confidence"] if analysis else None,
        ai_explanation=analysis["result"]["explanation_ru"] if analysis else None,
        confirmation_count=0,
    )
    db.add(item)
    db.flush()
    recalculate(db, item)
    for upload in uploads:
        root = f"{get_settings().public_api_url}/api/v1/media/{upload.id}"
        db.add(
            IncidentMedia(
                incident_id=item.id,
                upload_id=upload.id,
                media_type="image",
                original_url=upload.original_key,
                redacted_url=f"{root}/image",
                thumbnail_url=f"{root}/thumbnail",
            )
        )
    db.add(
        IdempotencyRecord(
            user_id=user.id, key=idempotency_key, request_hash=request_hash, incident_id=item.id
        )
    )
    if data.publish:
        db.add(TimelineEvent(incident_id=item.id, status="published"))
    db.add(
        AuditLog(
            actor_id=user.id,
            entity_type="incident",
            entity_id=item.id,
            action="publish" if data.publish else "draft_create",
            new_data={"status": item.status},
        )
    )
    db.flush()
    return serialize(db, item)


@router.get("/incidents")
def list_incidents(
    db: Db,
    page: int = Query(1, ge=1, le=10000),
    page_size: int = Query(20, ge=1, le=100),
    category_id: CategoryCode | None = None,
    status: IncidentStatus | None = None,
    sort: Literal["newest", "priority", "confirmations"] = "newest",
    author_id: UUID | None = None,
) -> dict[str, Any]:
    query = visible_query()
    if category_id:
        query = query.where(Incident.category_id == category_id)
    if status:
        query = query.where(Incident.status == status)
    if author_id:
        query = query.where(Incident.author_id == author_id)
    total = db.scalar(select(func.count()).select_from(query.subquery()))
    order = {
        "newest": Incident.created_at,
        "priority": Incident.priority_score,
        "confirmations": Incident.confirmation_count,
    }[sort]
    items = db.scalars(
        query.order_by(order.desc(), Incident.id).offset((page - 1) * page_size).limit(page_size)
    )
    return {
        "items": [serialize(db, item) for item in items],
        "page": page,
        "page_size": page_size,
        "total": total,
    }


@router.get("/incidents/nearby")
def nearby_incidents(
    db: Db,
    latitude: float = Query(ge=-90, le=90),
    longitude: float = Query(ge=-180, le=180),
    radius: float = Query(2000, ge=10, le=20000),
    category_id: CategoryCode | None = None,
    limit: int = Query(100, ge=1, le=200),
) -> dict[str, Any]:
    return {
        "items": [
            serialize(db, item)
            for item in nearby(db, latitude, longitude, radius, category_id, limit=limit)
        ],
        "limit": limit,
    }


@router.get("/incidents/{incident_id}")
def details(incident_id: UUID, db: Db) -> dict[str, Any]:
    return serialize(db, get_visible(db, incident_id))


@router.patch("/incidents/{incident_id}")
def patch(incident_id: UUID, data: IncidentPatch, db: Db, user: Actor) -> dict[str, Any]:
    item = get_visible(db, incident_id, user, lock=True)
    if item.author_id != user.id:
        raise fail("forbidden", "Нельзя изменять чужое обращение", 403)
    if item.is_published:
        raise fail("already_published", "Опубликованное обращение изменяет модератор", 409)
    if data.publish and not data.reviewed_by_user:
        raise fail("review_required", "Проверьте обращение", 422)
    if data.category_id:
        validate_category(db, data.category_id)
    for key, value in data.model_dump(
        exclude_none=True, exclude={"publish", "reviewed_by_user"}
    ).items():
        setattr(item, key, value)
    if data.publish:
        item.is_published = True
        db.add(TimelineEvent(incident_id=item.id, status="published"))
    recalculate(db, item)
    db.add(
        AuditLog(actor_id=user.id, entity_type="incident", entity_id=item.id, action="draft_update")
    )
    db.flush()
    return serialize(db, item)


@router.get("/incidents/{incident_id}/timeline")
def timeline(
    incident_id: UUID, db: Db, page: int = Query(1, ge=1), page_size: int = Query(50, ge=1, le=100)
) -> dict[str, Any]:
    get_visible(db, incident_id)
    events = db.scalars(
        select(TimelineEvent)
        .where(TimelineEvent.incident_id == incident_id)
        .order_by(TimelineEvent.created_at, TimelineEvent.id)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return {
        "items": [
            {
                "id": event.id,
                "status": event.status,
                "note": event.note,
                "created_at": event.created_at,
            }
            for event in events
        ]
    }
