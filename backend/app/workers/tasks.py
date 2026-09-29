from uuid import UUID

from celery import Celery
from sqlalchemy import select

from app.core.config import get_settings
from app.db.models import Upload
from app.db.session import SessionLocal
from app.services.ai.providers import CompatibleCloudProvider, MockSpeechTranscriber
from app.services.storage.objects import ObjectStorage

settings = get_settings()
celery_app = Celery("qalapulse", broker=settings.redis_url)
celery_app.conf.update(
    task_always_eager=settings.task_always_eager,
    task_ignore_result=True,
    broker_connection_retry_on_startup=True,
    task_serializer="json",
    accept_content=["json"],
    worker_hijack_root_logger=False,
    task_soft_time_limit=100,
    task_time_limit=120,
)


@celery_app.task(
    name="qalapulse.transcribe",
    acks_late=True,
    autoretry_for=(OSError,),
    retry_backoff=True,
    max_retries=3,
)
def transcribe_upload(upload_id: str) -> None:
    with SessionLocal.begin() as db:
        upload = db.scalar(select(Upload).where(Upload.id == UUID(upload_id)).with_for_update())
        if upload is None or upload.status in ("ready", "ready_mock"):
            return
        audio = ObjectStorage().get(upload.original_key)
        cloud = settings.ai_mode == "cloud" and upload.cloud_consent
        if cloud:
            try:
                upload.transcript = CompatibleCloudProvider().transcribe(
                    audio, upload.mime_type, upload.language
                )
                upload.status = "ready"
            except Exception:
                upload.transcript = MockSpeechTranscriber().transcribe(
                    audio, upload.mime_type, upload.language
                )
                upload.status = "ready_mock"
        else:
            upload.transcript = MockSpeechTranscriber().transcribe(
                audio, upload.mime_type, upload.language
            )
            upload.status = "ready_mock"
