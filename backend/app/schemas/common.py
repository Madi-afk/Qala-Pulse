import unicodedata
from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator

CategoryCode = Literal[
    "road_damage",
    "open_manhole",
    "garbage",
    "street_light",
    "water_leak",
    "sidewalk_damage",
    "other",
]
IncidentStatus = Literal[
    "published",
    "under_review",
    "accepted",
    "in_progress",
    "resolved_pending_confirmation",
    "resolved",
    "rejected",
]
Source = Literal["citizen", "inspector", "bus_camera", "municipal_vehicle", "cctv"]
ConfirmationStatus = Literal["still_exists", "resolved", "partially_resolved"]
Role = Literal["citizen", "moderator", "organization", "admin"]


class Input(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    @field_validator("*", mode="before")
    @classmethod
    def normalize(cls, value: Any) -> Any:
        if isinstance(value, str):
            return "".join(
                c
                for c in unicodedata.normalize("NFC", value)
                if c in "\n\t" or not unicodedata.category(c).startswith("C")
            )
        return value


class Register(Input):
    email: EmailStr
    password: str = Field(min_length=10, max_length=128)
    display_name: str = Field(min_length=2, max_length=80)
    preferred_language: Literal["ru", "kk"] = "ru"


class Login(Input):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class Refresh(Input):
    refresh_token: str = Field(min_length=20, max_length=200)


class ProfilePatch(Input):
    display_name: str = Field(min_length=2, max_length=80)
    preferred_language: Literal["ru", "kk"]


class Analyze(Input):
    upload_id: UUID
    description: str = Field(default="", max_length=4000)
    language: Literal["ru", "kk"] = "ru"
    cloud_consent: bool = False


class VisionResult(Input):
    is_civic_issue: bool
    category_code: CategoryCode
    title_ru: str = Field(min_length=1, max_length=160)
    title_kk: str = Field(min_length=1, max_length=160)
    description_ru: str = Field(min_length=1, max_length=4000)
    description_kk: str = Field(min_length=1, max_length=4000)
    severity: int = Field(ge=1, le=10)
    confidence: float = Field(ge=0, le=1)
    explanation_ru: str = Field(max_length=1000)
    explanation_kk: str = Field(max_length=1000)
    privacy_risks: list[Literal["face", "license_plate", "sensitive_object"]] = Field(max_length=3)


class Coordinates(Input):
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)


class DuplicateSearch(Coordinates):
    category_id: CategoryCode
    title: str = Field(min_length=3, max_length=160)
    description: str = Field(default="", max_length=4000)
    cloud_consent: bool = False


class IncidentCreate(DuplicateSearch):
    address: str = Field(default="", max_length=300)
    severity: int = Field(ge=1, le=10)
    upload_ids: list[UUID] = Field(min_length=1, max_length=5)
    reviewed_by_user: bool
    publish: bool = True


class IncidentPatch(Input):
    title: str | None = Field(default=None, min_length=3, max_length=160)
    description: str | None = Field(default=None, max_length=4000)
    category_id: CategoryCode | None = None
    severity: int | None = Field(default=None, ge=1, le=10)
    publish: bool = False
    reviewed_by_user: bool = False


class ConfirmationCreate(Input):
    status: ConfirmationStatus
    comment: str | None = Field(default=None, max_length=1000)


class CommentCreate(Input):
    text: str = Field(min_length=1, max_length=2000)


class ReportCreate(Input):
    incident_id: UUID | None = None
    comment_id: UUID | None = None
    reason: str = Field(min_length=5, max_length=1000)

    @model_validator(mode="after")
    def one_target(self) -> "ReportCreate":
        if (self.incident_id is None) == (self.comment_id is None):
            raise ValueError("Exactly one target is required")
        return self


class StatusChange(Input):
    status: IncidentStatus
    note: str = Field(default="", max_length=1000)
    category_id: CategoryCode | None = None
    is_hidden: bool | None = None


class AssignmentCreate(Input):
    organization_id: UUID
    executor_name: str | None = Field(default=None, max_length=100)
    due_at: datetime | None = None


class MergeCreate(Input):
    target_incident_id: UUID


class RoleChange(Input):
    role: Role
    organization_id: UUID | None = None


class CategoryPatch(Input):
    name_ru: str = Field(min_length=1, max_length=100)
    name_kk: str = Field(min_length=1, max_length=100)
    description: str = Field(max_length=500)
    base_severity: int = Field(ge=1, le=10)
    icon: str = Field(max_length=40)
    color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    is_active: bool
