"""Export/verify object snapshots; import is restricted to isolated restore drills."""

import argparse
import hashlib
import json
import os
from pathlib import Path
from typing import Any

from sqlalchemy import func, select, text

from app.core.config import get_settings
from app.db.base import Base
from app.db.models import Upload
from app.db.session import SessionLocal
from app.services.storage.objects import ObjectStorage


def checksum(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def safe_file(root: Path, name: str) -> Path:
    path = (root / name).resolve()
    if not path.is_relative_to(root.resolve()) or path == root.resolve():
        raise ValueError("Invalid backup path")
    return path


def database_state() -> dict[str, Any]:
    with SessionLocal() as db:
        counts = {
            table.name: db.scalar(select(func.count()).select_from(table))
            for table in Base.metadata.sorted_tables
        }
        revision = db.scalar(text("SELECT version_num FROM alembic_version"))
        db.execute(
            text("SELECT ST_Distance(ST_Point(76,43)::geography,ST_Point(76,43)::geography)")
        )
    return {"counts": counts, "revision": revision}


def check_references(objects: list[dict[str, Any]]) -> None:
    available = {(item["public"], item["key"]) for item in objects}
    with SessionLocal() as db:
        for upload in db.scalars(select(Upload)):
            for public, key in [
                (False, upload.original_key),
                (True, upload.redacted_key),
                (True, upload.thumbnail_key),
            ]:
                if key and (public, key) not in available:
                    raise RuntimeError("Database references a missing object")


def export_snapshot(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    if (root / "manifest.json").exists():
        raise RuntimeError("Snapshot destination must be fresh")
    storage = ObjectStorage()
    objects: list[dict[str, Any]] = []
    for public in (False, True):
        for item in storage.client.list_objects(storage.bucket(public), recursive=True):
            key = item.object_name
            if not key:
                continue
            relative = f"objects/{len(objects):08d}"
            path = root / relative
            path.parent.mkdir(exist_ok=True)
            storage.client.fget_object(storage.bucket(public), key, str(path))
            stat = storage.client.stat_object(storage.bucket(public), key)
            objects.append(
                {
                    "public": public,
                    "key": key,
                    "file": relative,
                    "sha256": checksum(path),
                    "size": path.stat().st_size,
                    "mime": stat.content_type or "application/octet-stream",
                }
            )
    check_references(objects)
    manifest: dict[str, Any] = {
        "format": 1,
        "database": database_state(),
        "dump_sha256": checksum(root / "database.dump"),
        "objects": objects,
    }
    (root / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    print(
        json.dumps(
            {"exported_objects": len(objects), "tables": len(manifest["database"]["counts"])}
        )
    )


def validate_snapshot(root: Path) -> dict[str, Any]:
    manifest: dict[str, Any] = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    if manifest["format"] != 1 or checksum(root / "database.dump") != manifest["dump_sha256"]:
        raise RuntimeError("Invalid database backup checksum")
    for obj in manifest["objects"]:
        path = safe_file(root, obj["file"])
        if path.stat().st_size != obj["size"] or checksum(path) != obj["sha256"]:
            raise RuntimeError("Invalid object backup checksum")
    return manifest


def restore_objects(root: Path) -> None:
    if get_settings().environment != "test" or os.environ.get("RESTORE_DRILL") != "1":
        raise RuntimeError("Restore is only allowed in an isolated test stack")
    manifest = validate_snapshot(root)
    storage = ObjectStorage()
    for public in (False, True):
        bucket = storage.bucket(public)
        if storage.client.bucket_exists(bucket):
            if next(storage.client.list_objects(bucket), None) is not None:
                raise RuntimeError("Restore destination is not empty")
        else:
            storage.client.make_bucket(bucket)
    for obj in manifest["objects"]:
        storage.client.fput_object(
            storage.bucket(obj["public"]),
            obj["key"],
            str(safe_file(root, obj["file"])),
            content_type=obj["mime"],
        )
    verify_restored(root)


def verify_restored(root: Path) -> None:
    manifest = validate_snapshot(root)
    if database_state() != manifest["database"]:
        raise RuntimeError("Restored database row counts or migration version differ")
    storage = ObjectStorage()
    for obj in manifest["objects"]:
        if (
            hashlib.sha256(storage.get(obj["key"], public=obj["public"])).hexdigest()
            != obj["sha256"]
        ):
            raise RuntimeError("Restored object checksum differs")
    check_references(manifest["objects"])
    if not storage.ready():
        raise RuntimeError("Restored storage is not ready")
    print(
        json.dumps(
            {
                "restore_verified": True,
                "objects": len(manifest["objects"]),
                "database": manifest["database"],
            }
        )
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["export", "validate", "restore", "verify"])
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    {
        "export": export_snapshot,
        "validate": validate_snapshot,
        "restore": restore_objects,
        "verify": verify_restored,
    }[args.action](args.directory)
