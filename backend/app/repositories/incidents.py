from datetime import timedelta
from typing import Any
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from app.core.errors import fail
from app.db.base import utcnow
from app.db.models import Category, Incident, IncidentMedia, User
from app.services.geospatial.priority import distance_meters, priority


def visible_query() -> Select[tuple[Incident]]:
    return select(Incident).where(Incident.is_published.is_(True), Incident.is_hidden.is_(False))


def get_visible(
    db: Session, incident_id: UUID, user: User | None = None, lock: bool = False
) -> Incident:
    query = select(Incident).where(Incident.id == incident_id)
    if lock:
        query = query.with_for_update()
    item = db.scalar(query)
    privileged = user is not None and user.role in ("admin", "moderator")
    own_draft = (
        user is not None
        and item is not None
        and user.id == item.author_id
        and not item.is_published
    )
    if item is None or (
        (item.is_hidden or not item.is_published) and not privileged and not own_draft
    ):
        raise fail("incident_not_found", "Обращение не найдено", 404)
    return item


def recalculate(db: Session, item: Incident) -> None:
    category = db.get(Category, item.category_id)
    assert category is not None
    item.priority_score, item.priority_explanation = priority(
        category.base_severity,
        item.severity,
        item.confirmation_count,
        item.created_at or utcnow(),
        item.latitude,
        item.longitude,
    )


def serialize(db: Session, item: Incident) -> dict[str, Any]:
    media = db.scalars(select(IncidentMedia).where(IncidentMedia.incident_id == item.id)).all()
    return {
        "id": item.id,
        "author_id": item.author_id,
        "source": item.source,
        "category_id": item.category_id,
        "title": item.title,
        "description": item.description,
        "latitude": item.latitude,
        "longitude": item.longitude,
        "address": item.address,
        "severity": item.severity,
        "priority_score": item.priority_score,
        "priority_explanation": item.priority_explanation,
        "ai_confidence": item.ai_confidence,
        "ai_explanation": item.ai_explanation,
        "status": item.status,
        "confirmation_count": item.confirmation_count,
        "is_published": item.is_published,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "resolved_at": item.resolved_at,
        "media": [
            {
                "id": m.id,
                "media_type": m.media_type,
                "url": m.redacted_url,
                "thumbnail_url": m.thumbnail_url,
            }
            for m in media
        ],
    }


def nearby(
    db: Session,
    latitude: float,
    longitude: float,
    radius: float,
    category_id: str | None = None,
    days: int | None = None,
    limit: int = 100,
) -> list[Incident]:
    query = visible_query()
    if category_id:
        query = query.where(Incident.category_id == category_id)
    if days:
        query = query.where(Incident.created_at >= utcnow() - timedelta(days=days))
    if db.get_bind().dialect.name == "postgresql":
        point = func.ST_GeogFromText(f"SRID=4326;POINT({longitude} {latitude})")
        query = query.where(func.ST_DWithin(Incident.location, point, radius)).order_by(
            func.ST_Distance(Incident.location, point), Incident.id
        )
        return list(db.scalars(query.limit(limit)))
    # SQLite exists only for fast isolated tests. Production always uses indexed PostGIS.
    candidates = list(db.scalars(query))
    candidates.sort(key=lambda i: distance_meters(latitude, longitude, i.latitude, i.longitude))
    return [
        i
        for i in candidates
        if distance_meters(latitude, longitude, i.latitude, i.longitude) <= radius
    ][:limit]
