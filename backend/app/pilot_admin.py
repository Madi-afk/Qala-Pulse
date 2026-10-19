"""Provision real pilot staff and categories; never creates demo incidents/passwords."""

import argparse
import getpass

from pydantic import EmailStr, TypeAdapter
from sqlalchemy import select

from app.core.security import hash_password
from app.db.models import AuditLog, Category, User
from app.db.session import SessionLocal
from app.services.ai.providers import LABELS


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--email", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--role", choices=["moderator", "admin"], default="moderator")
    args = parser.parse_args()
    email = str(TypeAdapter(EmailStr).validate_python(args.email)).lower()
    if not 2 <= len(args.name.strip()) <= 80:
        raise SystemExit("Name must contain 2-80 characters")
    password = getpass.getpass("New unique password (at least 14 characters): ")
    if (
        len(password) < 14
        or len(password) > 128
        or password != getpass.getpass("Repeat password: ")
    ):
        raise SystemExit("Password length or confirmation is invalid")
    with SessionLocal.begin() as db:
        if db.scalar(select(User).where(User.email == email)):
            raise SystemExit("Account exists; use recovery to change its password")
        for code, (ru, kk, severity, _) in LABELS.items():
            if db.get(Category, code) is None:
                db.add(
                    Category(
                        id=code,
                        code=code,
                        name_ru=ru,
                        name_kk=kk,
                        description=ru,
                        base_severity=severity,
                        icon=code,
                        color="#168573",
                    )
                )
        user = User(
            email=email,
            display_name=args.name.strip(),
            role=args.role,
            password_hash=hash_password(password),
        )
        db.add(user)
        db.flush()
        db.add(
            AuditLog(
                actor_id=user.id,
                entity_type="user",
                entity_id=user.id,
                action="pilot_staff_provisioned",
                new_data={"role": args.role},
            )
        )
    print("Staff account and categories provisioned. No demo data added.")


if __name__ == "__main__":
    main()
