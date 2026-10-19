"""Linux host maintenance: encrypted backup, isolated restore drill and retention."""

import argparse
import json
import os
import secrets
import shutil
import subprocess
import tempfile
import time
from datetime import datetime
from pathlib import Path
from uuid import uuid4

from prepare_pilot import ROOT, read_env

STATE = ROOT / ".pilot"
COMPOSE = [
    "docker",
    "compose",
    "--env-file",
    str(ROOT / ".env.pilot"),
    "-f",
    str(ROOT / "docker-compose.pilot.yml"),
]


def run(args, **kwargs):
    return subprocess.run(args, cwd=ROOT, check=True, timeout=3600, **kwargs)


def mark_success(job: str) -> None:
    path = STATE / "state" / f"{job}.json"
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps({"success_timestamp": time.time()}), encoding="utf-8")
    temp.chmod(0o644)
    temp.replace(path)


def restic_env() -> dict[str, str]:
    values = read_env(ROOT / ".env.pilot")
    if not values.get("RESTIC_REPOSITORY", "").startswith(
        ("sftp:", "s3:https://", "rest:https://")
    ):
        raise ValueError("Configure a separate off-host SFTP/HTTPS backup repository")
    password_file = Path(values.get("RESTIC_PASSWORD_FILE", ""))
    if not password_file.is_absolute() or not password_file.is_file():
        raise ValueError(
            "RESTIC_PASSWORD_FILE must be an absolute path to a protected password file"
        )
    if password_file.stat().st_mode & 0o077:
        raise ValueError("Backup password file must have mode 600 or 400")
    return os.environ | {
        key: value
        for key, value in values.items()
        if key.startswith(("RESTIC_", "AWS_"))
    }


def backup() -> None:
    env = restic_env()
    # Fail before maintenance if repository/key or credentials are unavailable.
    run(["restic", "snapshots", "--quiet"], env=env, stdout=subprocess.DEVNULL)
    stage = STATE / "transfer" / "snapshot"
    stage.mkdir(
        mode=0o700
    )  # Refuse to overwrite an interrupted or user-created snapshot.
    stopped = False
    try:
        # Drain writers. Worker tasks have a 120-second hard limit and 150-second stop grace.
        stopped = True
        run([*COMPOSE, "stop", "worker", "backend"])
        with (stage / "database.dump").open("wb") as stream:
            run(
                [
                    *COMPOSE,
                    "exec",
                    "-T",
                    "postgres",
                    "sh",
                    "-c",
                    'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc --no-owner --no-acl',
                ],
                stdout=stream,
            )
        run([*COMPOSE, "run", "--rm", "--no-deps", "ops", "export", "/backup/snapshot"])
        run([*COMPOSE, "up", "-d", "--wait", "backend", "worker"])
        stopped = False
        run(
            [
                "restic",
                "backup",
                str(stage),
                "--tag",
                "qalapulse",
                "--host",
                "qalapulse-pilot",
                "--quiet",
            ],
            env=env,
        )
        run(["restic", "check"], env=env)
        run(
            [
                "restic",
                "forget",
                "--tag",
                "qalapulse",
                "--host",
                "qalapulse-pilot",
                "--keep-within",
                "30d",
                "--prune",
            ],
            env=env,
        )
        mark_success("backup")
    finally:
        try:
            if stopped:
                run([*COMPOSE, "up", "-d", "--wait", "backend", "worker"])
        finally:
            # Only this newly-created staging directory, never repository or live data volumes.
            if stage.resolve() == (STATE / "transfer" / "snapshot").resolve():
                shutil.rmtree(stage)


def restore_drill() -> None:
    env = restic_env()
    run(["restic", "check", "--read-data"], env=env)
    snapshots = json.loads(
        run(
            [
                "restic",
                "snapshots",
                "--tag",
                "qalapulse",
                "--host",
                "qalapulse-pilot",
                "--latest",
                "1",
                "--json",
            ],
            env=env,
            capture_output=True,
        ).stdout
    )
    if not snapshots:
        raise RuntimeError("No pilot backup exists")
    snapshot_id = snapshots[0]["id"]
    if (
        time.time()
        - datetime.fromisoformat(
            snapshots[0]["time"].replace("Z", "+00:00")
        ).timestamp()
        > 26 * 3600
    ):
        raise RuntimeError(
            "Latest backup is stale; create a fresh backup before restore drill"
        )
    project = "qalapulse-drill-" + uuid4().hex[:12]
    with tempfile.TemporaryDirectory(prefix="restore-", dir=STATE / "transfer") as temp:
        run(["restic", "restore", snapshot_id, "--target", temp], env=env)
        manifests = list(Path(temp).rglob("manifest.json"))
        if len(manifests) != 1:
            raise RuntimeError("Expected exactly one snapshot manifest")
        directory = manifests[0].parent
        drill_env = os.environ | {
            "DRILL_PASSWORD": secrets.token_hex(32),
            "DRILL_SNAPSHOT": str(directory),
        }
        compose = [
            "docker",
            "compose",
            "--env-file",
            str(ROOT / ".env.pilot"),
            "-p",
            project,
            "-f",
            str(ROOT / "docker-compose.restore.yml"),
        ]
        try:
            run([*compose, "up", "-d", "--wait", "postgres", "minio"], env=drill_env)
            run(
                [
                    *compose,
                    "exec",
                    "-T",
                    "postgres",
                    "createdb",
                    "-U",
                    "qalapulse",
                    "-T",
                    "template0",
                    "qalapulse_restore",
                ],
                env=drill_env,
            )
            run(
                [*compose, "run", "--rm", "--no-deps", "verify", "validate", "/backup"],
                env=drill_env,
            )
            with (directory / "database.dump").open("rb") as stream:
                run(
                    [
                        *compose,
                        "exec",
                        "-T",
                        "postgres",
                        "pg_restore",
                        "-U",
                        "qalapulse",
                        "-d",
                        "qalapulse_restore",
                        "--exit-on-error",
                        "--no-owner",
                        "--no-acl",
                    ],
                    env=drill_env,
                    stdin=stream,
                )
            # MinIO may still be starting after its container enters running state.
            for attempt in range(30):
                result = subprocess.run(
                    [
                        *compose,
                        "run",
                        "--rm",
                        "--no-deps",
                        "--entrypoint",
                        "python",
                        "verify",
                        "-c",
                        "from app.services.storage.objects import ObjectStorage; ObjectStorage().client.list_buckets()",
                    ],
                    cwd=ROOT,
                    env=drill_env,
                    capture_output=True,
                    timeout=30,
                    check=False,
                )
                if result.returncode == 0:
                    break
                time.sleep(2)
            else:
                raise RuntimeError("Restore MinIO did not become ready")
            run(
                [*compose, "run", "--rm", "--no-deps", "verify", "restore", "/backup"],
                env=drill_env,
            )
            mark_success("restore")
            print(
                json.dumps(
                    {
                        "restore_verified": True,
                        "snapshot": snapshot_id,
                        "project": project,
                    }
                )
            )
        finally:
            # -p is generated above, no live project volumes are selected.
            run([*compose, "down", "--volumes", "--remove-orphans"], env=drill_env)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["backup", "restore-drill", "retention"])
    args = parser.parse_args()
    if os.name != "posix":
        raise SystemExit("Run maintenance on the Linux pilot server")
    import fcntl

    STATE.mkdir(mode=0o700, exist_ok=True)
    (STATE / "state").mkdir(mode=0o755, exist_ok=True)
    (STATE / "transfer").mkdir(mode=0o700, exist_ok=True)
    with (STATE / "maintenance.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if args.action == "retention":
            run(
                [
                    *COMPOSE,
                    "exec",
                    "-T",
                    "backend",
                    "python",
                    "-m",
                    "app.retention",
                    "--apply",
                ]
            )
            mark_success("retention")
        elif args.action == "backup":
            backup()
        else:
            restore_drill()


if __name__ == "__main__":
    main()
