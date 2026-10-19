"""Post-restore reconciliation before reopening a replacement server to users."""

from sqlalchemy import update

from app.db.models import PasswordReset, RefreshSession, Upload, User
from app.db.session import SessionLocal


def main() -> None:
    with SessionLocal.begin() as db:
        db.execute(update(User).values(auth_version=User.auth_version + 1))
        db.execute(update(RefreshSession).values(revoked=True))
        db.execute(update(PasswordReset).values(used=True))
        db.execute(update(Upload).where(Upload.status == "queued").values(status="waiting_retry"))
    print("Restored sessions revoked. Interrupted audio jobs can be retried by their owners.")


if __name__ == "__main__":
    main()
