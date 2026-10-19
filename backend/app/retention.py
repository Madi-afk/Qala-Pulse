"""Bounded, retry-safe file expiration. Preview by default; --apply deletes objects."""

import argparse
import json
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, delete, or_, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.base import utcnow
from app.db.models import AuditLog, IncidentMedia, PasswordReset, Upload
from app.db.session import SessionLocal
from app.services.storage.objects import ObjectStorage


def expire_files(
    db: Session, *, apply: bool = False, now: datetime | None = None
) -> dict[str, int]:
    now = now or utcnow()
    settings = get_settings()
    original_cutoff = now - timedelta(days=settings.original_retention_days)
    audio_cutoff = now - timedelta(days=settings.audio_retention_days)
    unattached_cutoff = now - timedelta(days=settings.unattached_retention_days)
    public_cutoff = now - timedelta(days=settings.public_photo_retention_days)
    attached = select(IncidentMedia.id).where(IncidentMedia.upload_id == Upload.id).exists()
    candidates = db.scalars(
        select(Upload)
        .where(
            or_(
                and_(
                    Upload.original_key != "",
                    Upload.media_type == "image",
                    Upload.created_at <= original_cutoff,
                ),
                and_(
                    Upload.original_key != "",
                    Upload.media_type == "audio",
                    Upload.created_at <= audio_cutoff,
                ),
                and_(
                    Upload.redacted_key.is_not(None),
                    or_(
                        Upload.created_at <= public_cutoff,
                        and_(~attached, Upload.created_at <= unattached_cutoff),
                    ),
                ),
                and_(~attached, Upload.original_key != "", Upload.created_at <= unattached_cutoff),
            )
        )
        .order_by(Upload.created_at)
        .limit(500)
        .with_for_update(skip_locked=True)
    ).all()
    counts = {"uploads": len(candidates), "originals": 0, "public_files": 0}
    storage = ObjectStorage()
    for upload in candidates:
        created = upload.created_at.replace(tzinfo=UTC)
        media = db.scalar(select(IncidentMedia).where(IncidentMedia.upload_id == upload.id))
        expire_public = created <= public_cutoff or (media is None and created <= unattached_cutoff)
        expire_original = (media is None and created <= unattached_cutoff) or created <= (
            audio_cutoff if upload.media_type == "audio" else original_cutoff
        )
        if expire_original and upload.original_key:
            counts["originals"] += 1
            if apply:
                storage.delete(upload.original_key)
                upload.original_key = ""
                if media:
                    media.original_url = ""
        if expire_public:
            for attr in ("redacted_key", "thumbnail_key"):
                key = getattr(upload, attr)
                if key:
                    counts["public_files"] += 1
                    if apply:
                        storage.delete(key, public=True)
                        setattr(upload, attr, None)
            if apply:
                upload.analysis = None
                if media:
                    media.redacted_url = ""
                    media.thumbnail_url = ""
        if apply:
            if upload.media_type == "audio" and expire_original:
                upload.transcript = None
                upload.status = "expired"
            elif not upload.redacted_key:
                upload.status = "expired"
            db.add(
                AuditLog(
                    entity_type="upload",
                    entity_id=upload.id,
                    action="retention_expired",
                    new_data={"original": expire_original, "public": expire_public},
                )
            )
    if apply:
        db.execute(delete(PasswordReset).where(PasswordReset.expires_at < now - timedelta(days=1)))
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument(
        "--erase-upload", type=UUID, help="Erase one upload after an approved privacy request"
    )
    args = parser.parse_args()
    with SessionLocal.begin() as db:
        if args.erase_upload:
            result = {"erased": erase_upload(db, args.erase_upload, apply=args.apply)}
        else:
            result = expire_files(db, apply=args.apply)
            # Flush tombstones before finding files left by failed uploads.
            db.flush()
            result["orphan_files"] = expire_orphans(db, apply=args.apply)
        print(json.dumps({"applied": args.apply, **result}))


def erase_upload(db: Session, upload_id: UUID, *, apply: bool = False) -> int:
    upload = db.scalar(select(Upload).where(Upload.id == upload_id).with_for_update())
    if upload is None or (
        not upload.original_key
        and not upload.redacted_key
        and not upload.thumbnail_key
        and not upload.transcript
    ):
        return 0
    if apply:
        storage = ObjectStorage()
        for public, key in [
            (False, upload.original_key),
            (True, upload.redacted_key),
            (True, upload.thumbnail_key),
        ]:
            if key:
                storage.delete(key, public=public)
        upload.original_key = ""
        upload.redacted_key = upload.thumbnail_key = None
        upload.analysis = None
        upload.transcript = None
        upload.status = "expired"
        media = db.scalar(select(IncidentMedia).where(IncidentMedia.upload_id == upload.id))
        if media:
            media.original_url = media.redacted_url = media.thumbnail_url = ""
        db.add(AuditLog(entity_type="upload", entity_id=upload.id, action="privacy_erasure"))
    return 1


def expire_orphans(db: Session, *, apply: bool = False) -> int:
    storage = ObjectStorage()
    cutoff = utcnow() - timedelta(days=get_settings().unattached_retention_days)
    keys = {
        (public, key)
        for upload in db.scalars(select(Upload))
        for public, key in [
            (False, upload.original_key),
            (True, upload.redacted_key),
            (True, upload.thumbnail_key),
        ]
        if key
    }
    count = 0
    for public in (False, True):
        for key, modified in storage.inventory(public):
            if modified <= cutoff and (public, key) not in keys:
                count += 1
                if apply:
                    storage.delete(key, public)
    return count


if __name__ == "__main__":
    main()
