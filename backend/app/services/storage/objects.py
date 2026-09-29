from io import BytesIO
from pathlib import Path

from minio import Minio

from app.core.config import get_settings


class ObjectStorage:
    def __init__(self) -> None:
        self.settings = get_settings()
        self.client = Minio(
            self.settings.minio_endpoint,
            access_key=self.settings.minio_access_key,
            secret_key=self.settings.minio_secret_key,
            secure=self.settings.minio_secure,
        )

    def bucket(self, public: bool) -> str:
        return self.settings.public_bucket if public else self.settings.private_bucket

    def put(self, key: str, data: bytes, mime: str, public: bool = False) -> None:
        bucket = self.bucket(public)
        if self.settings.storage_mode == "local":
            path = Path(self.settings.storage_path) / bucket / key
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        else:
            self.client.put_object(bucket, key, BytesIO(data), len(data), content_type=mime)

    def get(self, key: str, public: bool = False) -> bytes:
        if self.settings.storage_mode == "local":
            return (Path(self.settings.storage_path) / self.bucket(public) / key).read_bytes()
        response = self.client.get_object(self.bucket(public), key)
        try:
            return response.read()
        finally:
            response.close()
            response.release_conn()

    def ready(self) -> bool:
        if self.settings.storage_mode == "local":
            Path(self.settings.storage_path).mkdir(parents=True, exist_ok=True)
            return True
        return all(
            self.client.bucket_exists(bucket)
            for bucket in [self.settings.private_bucket, self.settings.public_bucket]
        )
