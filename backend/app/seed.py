"""Idempotent synthetic Almaty dataset. Refuses production mode."""

from datetime import timedelta
from io import BytesIO
from uuid import NAMESPACE_URL, UUID, uuid5

from PIL import Image, ImageDraw

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.base import utcnow
from app.db.models import (
    Category,
    Comment,
    ContentReport,
    Incident,
    IncidentAssignment,
    IncidentConfirmation,
    IncidentDuplicate,
    IncidentMedia,
    Organization,
    TimelineEvent,
    Upload,
    User,
)
from app.db.session import SessionLocal
from app.repositories.incidents import recalculate
from app.services.ai.providers import LABELS
from app.services.privacy.redactor import get_privacy_redactor
from app.services.storage.objects import ObjectStorage

DEMO_PASSWORD = "QalaPulse-Demo-2026!"


def seed_id(value: str) -> UUID:
    return uuid5(NAMESPACE_URL, f"https://qalapulse.example/demo/{value}")


def sample_image(index: int = 0) -> bytes:
    image = Image.new("RGB", (800, 600), "#d9e5db")
    draw = ImageDraw.Draw(image)
    draw.polygon([(220, 600), (370, 100), (480, 100), (720, 600)], fill="#66766e")
    draw.ellipse((330 + index % 40, 360, 490, 440), fill="#2c3936", outline="#b2b8ae", width=8)
    draw.rectangle((24, 24, 300, 70), fill="#ffffff")
    draw.text((40, 40), "QALAPULSE / SYNTHETIC DEMO", fill="#145347")
    output = BytesIO()
    image.save(output, "JPEG", quality=90)
    return output.getvalue()


def seed() -> None:
    settings = get_settings()
    if settings.environment == "production":
        raise RuntimeError("Demo seed is disabled in production")
    storage = ObjectStorage()
    with SessionLocal.begin() as db:
        colors = ["#D97743", "#C9473B", "#4F9267", "#B79532", "#398EBC", "#9B79AA", "#5B7970"]
        for index, (code, (ru, kk, severity, _)) in enumerate(LABELS.items()):
            if db.get(Category, code) is None:
                db.add(
                    Category(
                        id=code,
                        code=code,
                        name_ru=ru,
                        name_kk=kk,
                        description=f"Сообщения жителей: {ru.lower()}",
                        base_severity=severity,
                        icon=code,
                        color=colors[index],
                    )
                )
        org_id = seed_id("organization")
        if db.get(Organization, org_id) is None:
            db.add(
                Organization(
                    id=org_id,
                    name_ru="Демо-служба QalaPulse (не госорган)",
                    name_kk="QalaPulse сынақ қызметі (меморган емес)",
                    contact_data={"demo": True},
                )
            )
        db.flush()
        users = []
        for role in ["citizen", "moderator", "organization", "admin"]:
            user_id = seed_id(role)
            user = db.get(User, user_id)
            if user is None:
                user = User(
                    id=user_id,
                    email=f"{role}@qalapulse.example.com",
                    display_name=f"Demo {role}",
                    password_hash=hash_password(DEMO_PASSWORD),
                    role=role,
                    organization_id=org_id if role == "organization" else None,
                )
                db.add(user)
            if user.email == f"{role}@qalapulse.test":
                user.email = f"{role}@qalapulse.example.com"
            users.append(user)
        db.flush()
        statuses = [
            "published",
            "under_review",
            "accepted",
            "in_progress",
            "resolved_pending_confirmation",
            "resolved",
            "rejected",
        ]
        ids = []
        for index in range(28):
            incident_id = seed_id(f"incident-{index}")
            ids.append(incident_id)
            if db.get(Incident, incident_id):
                continue
            code = list(LABELS)[index % 7]
            ru, _, severity, _ = LABELS[code]
            # Every 7th item forms a nearby same-category group; deterministic demo duplicates.
            latitude, longitude = (
                43.2389 + (index % 7) * 0.002 + (index // 7) * 0.00003,
                76.8897 + (index % 7) * 0.0015,
            )
            status = statuses[(index // 4) % 7]
            created = utcnow() - timedelta(hours=index * 3)
            item = Incident(
                id=incident_id,
                author_id=users[0].id,
                source="citizen",
                category_id=code,
                title=f"{ru} · демо {index + 1}",
                description=f"Синтетическое тестовое обращение. {ru}. Не является реальным сообщением.",
                latitude=latitude,
                longitude=longitude,
                location=f"SRID=4326;POINT({longitude} {latitude})",
                address="Алматы, условная демонстрационная точка",
                severity=severity,
                confirmation_count=1,
                ai_confidence=0,
                ai_explanation="Синтетические данные",
                status=status,
                created_at=created,
                resolved_at=utcnow() if status == "resolved" else None,
            )
            db.add(item)
            upload_id = seed_id(f"upload-{index}")
            original = sample_image(index)
            redacted, thumb, method = get_privacy_redactor().redact(original)
            key = f"demo/{upload_id}"
            storage.put(f"{key}/original", original, "image/jpeg")
            storage.put(f"{key}/image.jpg", redacted, "image/jpeg", public=True)
            storage.put(f"{key}/thumb.jpg", thumb, "image/jpeg", public=True)
            db.add(
                Upload(
                    id=upload_id,
                    owner_id=users[0].id,
                    media_type="image",
                    original_key=f"{key}/original",
                    redacted_key=f"{key}/image.jpg",
                    thumbnail_key=f"{key}/thumb.jpg",
                    mime_type="image/jpeg",
                    privacy_method=method,
                )
            )
            db.flush()
            root = f"{settings.public_api_url}/api/v1/media/{upload_id}"
            db.add(
                IncidentMedia(
                    incident_id=item.id,
                    upload_id=upload_id,
                    media_type="image",
                    original_url=f"{key}/original",
                    redacted_url=f"{root}/image",
                    thumbnail_url=f"{root}/thumbnail",
                )
            )
            db.add(TimelineEvent(incident_id=item.id, status="published", created_at=created))
            if status != "published":
                db.add(
                    TimelineEvent(
                        incident_id=item.id, status=status, created_at=created + timedelta(hours=1)
                    )
                )
            db.add(
                Comment(
                    incident_id=item.id,
                    author_id=users[1].id,
                    text="Демонстрационный комментарий для проверки пилота.",
                )
            )
            db.add(
                IncidentConfirmation(
                    incident_id=item.id, user_id=users[1].id, status="still_exists"
                )
            )
            if status in ("accepted", "in_progress", "resolved_pending_confirmation", "resolved"):
                db.add(
                    IncidentAssignment(
                        incident_id=item.id, organization_id=org_id, assigned_by=users[1].id
                    )
                )
            recalculate(db, item)
        db.flush()
        for index in range(7):
            duplicate_id = seed_id(f"duplicate-{index}")
            if db.get(IncidentDuplicate, duplicate_id) is None:
                db.add(
                    IncidentDuplicate(
                        id=duplicate_id,
                        source_incident_id=ids[index + 7],
                        target_incident_id=ids[index],
                        similarity_score=0.94,
                        distance_meters=3.3,
                        text_similarity=0.85,
                        status="suggested",
                    )
                )
        for index in range(3):
            report_id = seed_id(f"report-{index}")
            if db.get(ContentReport, report_id) is None:
                db.add(
                    ContentReport(
                        id=report_id,
                        reporter_id=users[0].id,
                        incident_id=ids[index],
                        reason="Демонстрационная жалоба: проверьте соответствие описания фотографии.",
                    )
                )
    print(
        "Seed complete: 4 test accounts, 7 categories, 28 synthetic incidents. Existing rows preserved."
    )


if __name__ == "__main__":
    seed()
