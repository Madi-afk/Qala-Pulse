from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import require_role
from app.core.errors import fail
from app.db.models import Incident, IncidentAssignment, Organization, User
from app.repositories.incidents import get_visible, serialize

TRANSITIONS = {
    "published": {"under_review", "accepted", "rejected"},
    "under_review": {"published", "accepted", "rejected"},
    "accepted": {"in_progress", "under_review"},
    "in_progress": {"resolved_pending_confirmation", "under_review"},
    "resolved_pending_confirmation": {"under_review", "in_progress"},
    "resolved": {"under_review"},
    "rejected": {"under_review"},
}
ORGANIZATION_STATUSES = {"accepted", "in_progress", "resolved_pending_confirmation"}


def assignment_for(db: Session, incident_id: UUID) -> IncidentAssignment | None:
    return db.scalar(
        select(IncidentAssignment).where(IncidentAssignment.incident_id == incident_id)
    )


def staff_incident(db: Session, incident_id: UUID, user: User, *, lock: bool = False) -> Incident:
    require_role(user, "moderator", "organization", "admin")
    item = get_visible(db, incident_id, user, lock=lock)
    if not item.is_published:
        raise fail("draft_private", "Черновик не опубликован", 409)
    if user.role == "organization":
        assignment = assignment_for(db, item.id)
        if assignment is None or assignment.organization_id != user.organization_id:
            raise fail("forbidden", "Обращение не назначено вашей организации", 403)
    return item


def staff_serialize(db: Session, item: Incident, user: User) -> dict[str, Any]:
    assignment = assignment_for(db, item.id)
    org = db.get(Organization, assignment.organization_id) if assignment else None
    statuses = TRANSITIONS[item.status].copy()
    if user.role == "organization":
        statuses &= ORGANIZATION_STATUSES
    if user.role == "moderator" or assignment is None:
        statuses -= ORGANIZATION_STATUSES
    return serialize(db, item) | {
        "is_hidden": item.is_hidden,
        "allowed_statuses": sorted(statuses),
        "assignment": {
            "organization_id": assignment.organization_id,
            "organization_name": org.name_ru if org else "",
            "executor_name": assignment.executor_name,
            "due_at": assignment.due_at,
            "assigned_at": assignment.assigned_at,
        }
        if assignment
        else None,
    }
