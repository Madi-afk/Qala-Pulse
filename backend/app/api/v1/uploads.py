from io import BytesIO
from typing import Annotated, Any, Literal
from uuid import UUID, uuid4

from fastapi import APIRouter, File, Form, Response, UploadFile
from PIL import Image, UnidentifiedImageError
from sqlalchemy import select

from app.api.deps import Actor, Db
from app.core.config import get_settings
from app.core.errors import fail
from app.db.models import Incident, IncidentMedia, Upload
from app.services.privacy.redactor import ConservativeMockRedactor
from app.services.storage.objects import ObjectStorage
from app.workers.tasks import transcribe_upload

router = APIRouter(tags=["uploads"])


def owned_upload(db: Db, upload_id: UUID, user_id: UUID) -> Upload:
    item = db.get(Upload, upload_id)
    if item is None or item.owner_id != user_id:
        raise fail("upload_not_found", "Файл не найден", 404)
    return item


def upload_json(item: Upload) -> dict[str, Any]:
    return {
        "id": item.id,
        "media_type": item.media_type,
        "status": item.status,
        "transcript": item.transcript,
        "privacy_method": item.privacy_method,
    }


@router.post("/uploads/images", status_code=201)
def upload_image(db: Db, user: Actor, file: Annotated[UploadFile, File()]) -> dict[str, Any]:
    data = file.file.read(get_settings().max_image_bytes + 1)
    if not data or len(data) > get_settings().max_image_bytes:
        raise fail("file_too_large", "Размер фотографии превышает лимит", 413)
    allowed = {"JPEG": "image/jpeg", "PNG": "image/png", "WEBP": "image/webp"}
    try:
        with Image.open(BytesIO(data)) as image:
            if image.format not in allowed or allowed[image.format] != file.content_type:
                raise fail("invalid_file", "Разрешены JPEG, PNG и WebP", 415)
            image.verify()
        redacted, thumbnail, method = ConservativeMockRedactor().redact(data)
    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombError,
        Image.DecompressionBombWarning,
    ):
        raise fail("invalid_image", "Не удалось прочитать изображение", 415) from None
    key = str(uuid4())
    storage = ObjectStorage()
    storage.put(f"{key}/original", data, file.content_type or "application/octet-stream")
    storage.put(f"{key}/public.jpg", redacted, "image/jpeg", public=True)
    storage.put(f"{key}/thumb.jpg", thumbnail, "image/jpeg", public=True)
    item = Upload(
        owner_id=user.id,
        media_type="image",
        original_key=f"{key}/original",
        redacted_key=f"{key}/public.jpg",
        thumbnail_key=f"{key}/thumb.jpg",
        mime_type=file.content_type or "image/jpeg",
        privacy_method=method,
    )
    db.add(item)
    db.flush()
    return upload_json(item)


def audio_mime(data: bytes) -> str | None:
    if data.startswith(b"RIFF") and data[8:12] == b"WAVE":
        return "audio/wav"
    if data[4:8] == b"ftyp":
        return "audio/mp4"
    if data.startswith(b"OggS"):
        return "audio/ogg"
    if data.startswith(b"\x1aE\xdf\xa3"):
        return "audio/webm"
    if data.startswith(b"ID3") or (len(data) > 1 and data[0] == 255 and data[1] & 224 == 224):
        return "audio/mpeg"
    return None


@router.post("/uploads/audio", status_code=202)
def upload_audio(
    db: Db,
    user: Actor,
    file: Annotated[UploadFile, File()],
    language: Annotated[Literal["ru", "kk"], Form()] = "ru",
    cloud_consent: Annotated[bool, Form()] = False,
) -> dict[str, Any]:
    data = file.file.read(get_settings().max_audio_bytes + 1)
    if not data or len(data) > get_settings().max_audio_bytes:
        raise fail("file_too_large", "Размер записи превышает лимит", 413)
    mime = audio_mime(data)
    if mime is None or file.content_type not in (mime, "audio/x-wav", "audio/m4a"):
        raise fail("invalid_audio", "Неподдерживаемая аудиозапись", 415)
    key = f"{uuid4()}/audio"
    ObjectStorage().put(key, data, mime)
    item = Upload(
        owner_id=user.id,
        media_type="audio",
        original_key=key,
        mime_type=mime,
        status="queued",
        cloud_consent=cloud_consent,
        language=language,
    )
    db.add(item)
    db.commit()
    try:
        transcribe_upload.delay(str(item.id))
    except Exception:
        item.status = "waiting_retry"
        db.commit()
    db.refresh(item)
    return upload_json(item)


@router.get("/uploads/{upload_id}")
def upload_status(upload_id: UUID, db: Db, user: Actor) -> dict[str, Any]:
    return upload_json(owned_upload(db, upload_id, user.id))


@router.post("/uploads/{upload_id}/retry", status_code=202)
def retry_upload(upload_id: UUID, db: Db, user: Actor) -> dict[str, Any]:
    item = owned_upload(db, upload_id, user.id)
    if item.media_type != "audio":
        raise fail("invalid_job", "Этот файл не является аудиозаписью")
    if item.status not in ("ready", "ready_mock"):
        try:
            transcribe_upload.delay(str(item.id))
        except Exception:
            raise fail("queue_unavailable", "Очередь недоступна, повторите позже", 503) from None
    return upload_json(item)


@router.get("/uploads/{upload_id}/preview")
def preview(upload_id: UUID, db: Db, user: Actor) -> Response:
    item = owned_upload(db, upload_id, user.id)
    if not item.redacted_key:
        raise fail("upload_not_found", "Изображение не найдено", 404)
    return Response(
        ObjectStorage().get(item.redacted_key, public=True),
        media_type="image/jpeg",
        headers={"Cache-Control": "private, no-store"},
    )


@router.get("/media/{upload_id}/{variant}")
def public_media(upload_id: UUID, variant: Literal["image", "thumbnail"], db: Db) -> Response:
    item = db.scalar(
        select(Upload)
        .join(IncidentMedia, IncidentMedia.upload_id == Upload.id)
        .join(Incident, IncidentMedia.incident_id == Incident.id)
        .where(
            Upload.id == upload_id, Incident.is_hidden.is_(False), Incident.is_published.is_(True)
        )
    )
    if item is None:
        raise fail("media_not_found", "Изображение недоступно", 404)
    key = item.redacted_key if variant == "image" else item.thumbnail_key
    if key is None:
        raise fail("media_not_found", "Изображение недоступно", 404)
    return Response(
        ObjectStorage().get(key, public=True),
        media_type="image/jpeg",
        headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"},
    )
