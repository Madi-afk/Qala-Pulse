from functools import lru_cache
from typing import Literal

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=("../.env", ".env"), extra="ignore")
    environment: Literal["development", "test", "production"] = "development"
    database_url: str = "postgresql+psycopg://qalapulse:local-only@localhost:5432/qalapulse"
    redis_url: str = "redis://localhost:6379/0"
    jwt_secret: str = Field(
        default="development-only-change-before-deployment-0123456789", min_length=32
    )
    access_minutes: int = 15
    refresh_days: int = 30
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080"]
    public_api_url: str = "http://localhost:8000"
    storage_mode: Literal["minio", "local"] = "minio"
    storage_path: str = ".storage"
    minio_endpoint: str = "localhost:9000"
    minio_access_key: str = "local-only"
    minio_secret_key: str = "local-only-change-me"
    minio_secure: bool = False
    private_bucket: str = "qalapulse-originals"
    public_bucket: str = "qalapulse-redacted"
    max_image_bytes: int = 10 * 1024 * 1024
    max_audio_bytes: int = 15 * 1024 * 1024
    privacy_mode: Literal["local", "full_frame"] = "local"
    ai_mode: Literal["mock", "cloud"] = "mock"
    ai_base_url: str = ""
    ai_api_key: str = ""
    ai_vision_model: str = ""
    ai_text_model: str = ""
    ai_transcription_model: str = ""
    ai_embedding_model: str = ""
    ai_timeout_seconds: float = 25
    ai_retries: int = 2
    cloud_ai_consent_required: bool = True
    duplicate_threshold: float = Field(default=0.66, ge=0, le=1)
    duplicate_radius_meters: int = 250
    duplicate_days: int = 30
    task_always_eager: bool = False
    rate_limit_enabled: bool = True
    rate_limit_per_minute: int = 120
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    smtp_tls: Literal["starttls", "ssl"] = "starttls"
    password_reset_minutes: int = Field(default=20, ge=5, le=60)
    metrics_token: str = ""
    pilot_registration_closed: bool = False
    pilot_registration_emails: list[str] = []
    original_retention_days: int = Field(default=7, ge=1, le=30)
    audio_retention_days: int = Field(default=2, ge=1, le=7)
    unattached_retention_days: int = Field(default=7, ge=1, le=30)
    public_photo_retention_days: int = Field(default=90, ge=7, le=365)

    @model_validator(mode="after")
    def production_secrets(self) -> "Settings":
        if self.environment == "production":
            if self.jwt_secret.startswith("development-") or self.minio_secret_key.startswith(
                "local-"
            ):
                raise ValueError("Production requires unique JWT and storage secrets")
            if self.storage_mode != "minio" or not self.rate_limit_enabled:
                raise ValueError("Production requires MinIO and rate limiting")
            if not self.public_api_url.startswith("https://"):
                raise ValueError("Production requires an HTTPS public URL")
            if not self.smtp_host or not self.smtp_from or len(self.metrics_token) < 32:
                raise ValueError("Production requires SMTP and a separate metrics token")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
