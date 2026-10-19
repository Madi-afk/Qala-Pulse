from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import UserDefinedType

from app.db.base import Base, Entity, utcnow


class Geography(UserDefinedType[str]):
    cache_ok = True

    def get_col_spec(self, **kw: Any) -> str:
        return "geography(POINT,4326)"


class User(Entity, Base):
    __tablename__ = "users"
    email: Mapped[str] = mapped_column(String(254), unique=True)
    phone: Mapped[str | None] = mapped_column(String(30))
    password_hash: Mapped[str] = mapped_column(String(255))
    display_name: Mapped[str] = mapped_column(String(80))
    preferred_language: Mapped[str] = mapped_column(String(5), default="ru")
    role: Mapped[str] = mapped_column(String(20), default="citizen")
    organization_id: Mapped[UUID | None] = mapped_column(ForeignKey("organizations.id"))
    is_active: Mapped[bool] = mapped_column(default=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )


class Category(Base):
    __tablename__ = "categories"
    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    code: Mapped[str] = mapped_column(String(40), unique=True)
    name_ru: Mapped[str] = mapped_column(String(100))
    name_kk: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(String(500))
    base_severity: Mapped[int]
    icon: Mapped[str] = mapped_column(String(40))
    color: Mapped[str] = mapped_column(String(10))
    is_active: Mapped[bool] = mapped_column(default=True)


class Incident(Entity, Base):
    __tablename__ = "incidents"
    __table_args__ = (
        CheckConstraint("severity BETWEEN 1 AND 10"),
        CheckConstraint("latitude BETWEEN -90 AND 90"),
        CheckConstraint("longitude BETWEEN -180 AND 180"),
        CheckConstraint("confirmation_count >= 0"),
    )
    author_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    source: Mapped[str] = mapped_column(String(30), default="citizen")
    category_id: Mapped[str] = mapped_column(ForeignKey("categories.id"), index=True)
    title: Mapped[str] = mapped_column(String(160))
    description: Mapped[str] = mapped_column(Text)
    latitude: Mapped[float]
    longitude: Mapped[float]
    location: Mapped[str] = mapped_column(Geography().with_variant(Text(), "sqlite"))
    address: Mapped[str] = mapped_column(String(300), default="")
    severity: Mapped[int]
    priority_score: Mapped[float] = mapped_column(default=0)
    priority_explanation: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    ai_confidence: Mapped[float | None]
    ai_explanation: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(40), default="published", index=True)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)
    confirmation_count: Mapped[int] = mapped_column(default=0)
    resolution_cycle: Mapped[int] = mapped_column(default=0, server_default="0")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Upload(Entity, Base):
    __tablename__ = "uploads"
    owner_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    media_type: Mapped[str] = mapped_column(String(10))
    original_key: Mapped[str] = mapped_column(String(200))
    redacted_key: Mapped[str | None] = mapped_column(String(200))
    thumbnail_key: Mapped[str | None] = mapped_column(String(200))
    mime_type: Mapped[str] = mapped_column(String(100))
    status: Mapped[str] = mapped_column(String(20), default="ready")
    transcript: Mapped[str | None] = mapped_column(Text)
    analysis: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    privacy_method: Mapped[str | None] = mapped_column(String(60))
    cloud_consent: Mapped[bool] = mapped_column(default=False)
    language: Mapped[str] = mapped_column(String(5), default="ru")


class IncidentMedia(Entity, Base):
    __tablename__ = "incident_media"
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"), index=True)
    upload_id: Mapped[UUID] = mapped_column(ForeignKey("uploads.id"), unique=True)
    media_type: Mapped[str] = mapped_column(String(20))
    original_url: Mapped[str] = mapped_column(String(300))
    redacted_url: Mapped[str] = mapped_column(String(300))
    thumbnail_url: Mapped[str] = mapped_column(String(300))


class IncidentConfirmation(Entity, Base):
    __tablename__ = "incident_confirmations"
    __table_args__ = (
        UniqueConstraint(
            "incident_id", "user_id", "status", "resolution_cycle", name="uq_confirmation_cycle"
        ),
    )
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"), index=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    status: Mapped[str] = mapped_column(String(30))
    resolution_cycle: Mapped[int] = mapped_column(default=0, server_default="0")
    comment: Mapped[str | None] = mapped_column(String(1000))


class IncidentDuplicate(Entity, Base):
    __tablename__ = "incident_duplicates"
    __table_args__ = (UniqueConstraint("source_incident_id", "target_incident_id"),)
    source_incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"))
    target_incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"))
    similarity_score: Mapped[float]
    distance_meters: Mapped[float]
    text_similarity: Mapped[float]
    image_similarity: Mapped[float | None]
    status: Mapped[str] = mapped_column(String(20), default="suggested")


class Comment(Entity, Base):
    __tablename__ = "comments"
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"), index=True)
    author_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(String(2000))
    is_hidden: Mapped[bool] = mapped_column(default=False)


class Organization(Entity, Base):
    __tablename__ = "organizations"
    name_ru: Mapped[str] = mapped_column(String(200))
    name_kk: Mapped[str] = mapped_column(String(200))
    contact_data: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    service_area: Mapped[dict[str, Any] | None] = mapped_column(JSON)


class IncidentAssignment(Entity, Base):
    __tablename__ = "incident_assignments"
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"), unique=True)
    organization_id: Mapped[UUID] = mapped_column(ForeignKey("organizations.id"))
    assigned_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    executor_name: Mapped[str | None] = mapped_column(String(100))
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class AuditLog(Entity, Base):
    __tablename__ = "audit_logs"
    actor_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    entity_type: Mapped[str] = mapped_column(String(50))
    entity_id: Mapped[UUID]
    action: Mapped[str] = mapped_column(String(80))
    old_data: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    new_data: Mapped[dict[str, Any] | None] = mapped_column(JSON)


class TimelineEvent(Entity, Base):
    __tablename__ = "timeline_events"
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"), index=True)
    status: Mapped[str] = mapped_column(String(40))
    note: Mapped[str] = mapped_column(String(1000), default="")


class ContentReport(Entity, Base):
    __tablename__ = "content_reports"
    __table_args__ = (CheckConstraint("(incident_id IS NULL) != (comment_id IS NULL)"),)
    reporter_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    incident_id: Mapped[UUID | None] = mapped_column(ForeignKey("incidents.id"))
    comment_id: Mapped[UUID | None] = mapped_column(ForeignKey("comments.id"))
    reason: Mapped[str] = mapped_column(String(1000))
    status: Mapped[str] = mapped_column(String(30), default="pending")


class RefreshSession(Entity, Base):
    __tablename__ = "refresh_sessions"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    family_id: Mapped[UUID] = mapped_column(index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked: Mapped[bool] = mapped_column(default=False)


class IdempotencyRecord(Entity, Base):
    __tablename__ = "idempotency_records"
    __table_args__ = (UniqueConstraint("user_id", "key"),)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    key: Mapped[str] = mapped_column(String(100))
    request_hash: Mapped[str] = mapped_column(String(64))
    incident_id: Mapped[UUID] = mapped_column(ForeignKey("incidents.id"))


class PublicationCancellation(Entity, Base):
    __tablename__ = "publication_cancellations"
    __table_args__ = (UniqueConstraint("user_id", "key"),)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    key: Mapped[str] = mapped_column(String(100))
