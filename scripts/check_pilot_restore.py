"""Synthetic encrypted backup/restore test, isolated from .env and live project volumes."""

import json
import os
import secrets
import subprocess
import tempfile
import time
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]


def run(args, **kwargs):
    return subprocess.run(args, cwd=ROOT, check=True, timeout=1800, **kwargs)


def reclaim_test_files(work: Path) -> None:
    """Return container-created files to the runner without widening permissions."""
    if os.name != "posix":
        return
    directory = work.resolve(strict=True)
    if directory.parent != (
        ROOT / "artifacts"
    ).resolve() or not directory.name.startswith("pilot-recovery-"):
        raise ValueError(
            "Ownership repair is restricted to this test's temporary directory"
        )
    run(
        [
            "docker",
            "run",
            "--rm",
            "-v",
            f"{directory.as_posix()}:/work",
            "alpine:3.21.3",
            "chown",
            "-hR",
            f"{os.getuid()}:{os.getgid()}",
            "/work",
        ]
    )


def main():
    identity = uuid4().hex[:10]
    projects = [f"qalapulse-backuptest-{identity}", f"qalapulse-restoretest-{identity}"]
    volume = f"qalapulse-restictest-{identity}"
    artifacts = ROOT / "artifacts"
    artifacts.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="pilot-recovery-", dir=artifacts) as temp:
        work = Path(temp)
        source = work / "source"
        source.mkdir()
        empty_env = work / "empty.env"
        empty_env.write_text("# isolated test\n")
        env = os.environ | {
            "DRILL_PASSWORD": secrets.token_hex(32),
            "DRILL_SNAPSHOT": source.as_posix(),
            "DRILL_MOUNT_MODE": "rw",
        }
        base = [
            "docker",
            "compose",
            "--env-file",
            str(empty_env),
            "-f",
            str(ROOT / "docker-compose.restore.yml"),
        ]
        source_cmd = [*base, "-p", projects[0]]
        target_cmd = [*base, "-p", projects[1]]
        restic_env = os.environ | {"RESTIC_PASSWORD": secrets.token_hex(32)}
        restic = [
            "docker",
            "run",
            "--rm",
            "-e",
            "RESTIC_PASSWORD",
            "-v",
            f"{volume}:/repo",
            "-v",
            f"{work.as_posix()}:/work",
            "restic/restic:0.18.1",
            "-r",
            "/repo",
        ]
        try:
            run(["docker", "build", "-t", "qalapulse-backend:pilot", "backend"])
            run(
                [
                    "docker",
                    "build",
                    "-t",
                    "qalapulse-minio:2025-04-22-0d7408fc",
                    "--build-arg",
                    "COMPONENT=minio",
                    "--build-arg",
                    "SOURCE_COMMIT=0d7408fc9969caf07de6a8c3a84f9fbb10a6739e",
                    "infrastructure/minio",
                ]
            )
            run([*source_cmd, "up", "-d", "--wait", "postgres", "minio"], env=env)
            run(
                [
                    *source_cmd,
                    "exec",
                    "-T",
                    "postgres",
                    "createdb",
                    "-U",
                    "qalapulse",
                    "-T",
                    "template1",
                    "qalapulse_restore",
                ],
                env=env,
            )
            for attempt in range(30):
                ready = subprocess.run(
                    [
                        *source_cmd,
                        "run",
                        "--rm",
                        "--no-deps",
                        "--entrypoint",
                        "python",
                        "verify",
                        "-c",
                        "from app.services.storage.objects import ObjectStorage; s=ObjectStorage(); [s.client.make_bucket(s.bucket(p)) for p in (False,True) if not s.client.bucket_exists(s.bucket(p))]",
                    ],
                    env=env,
                    cwd=ROOT,
                    capture_output=True,
                    timeout=30,
                    check=False,
                )
                if ready.returncode == 0:
                    break
                time.sleep(2)
            else:
                raise RuntimeError("Synthetic source storage did not become ready")
            run(
                [
                    *source_cmd,
                    "run",
                    "--rm",
                    "--no-deps",
                    "--entrypoint",
                    "sh",
                    "verify",
                    "-c",
                    "alembic upgrade head && python -m app.seed",
                ],
                env=env,
            )
            with (source / "database.dump").open("wb") as stream:
                run(
                    [
                        *source_cmd,
                        "exec",
                        "-T",
                        "postgres",
                        "pg_dump",
                        "-U",
                        "qalapulse",
                        "-d",
                        "qalapulse_restore",
                        "-Fc",
                        "--no-owner",
                        "--no-acl",
                    ],
                    env=env,
                    stdout=stream,
                )
            run(
                [
                    *source_cmd,
                    "run",
                    "--rm",
                    "--no-deps",
                    "verify",
                    "export",
                    "/backup",
                ],
                env=env,
            )
            run([*restic, "init"], env=restic_env)
            run(
                [*restic, "backup", "/work/source", "--tag", "qalapulse-test"],
                env=restic_env,
            )
            run([*restic, "check", "--read-data"], env=restic_env)
            run(
                [*restic, "restore", "latest", "--target", "/work/recovered"],
                env=restic_env,
            )
            reclaim_test_files(work)
            recovered = work / "recovered" / "work" / "source"
            target_env = env | {
                "DRILL_SNAPSHOT": recovered.as_posix(),
                "DRILL_MOUNT_MODE": "ro",
            }
            run(
                [*target_cmd, "up", "-d", "--wait", "postgres", "minio"], env=target_env
            )
            run(
                [
                    *target_cmd,
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
                env=target_env,
            )
            run(
                [
                    *target_cmd,
                    "run",
                    "--rm",
                    "--no-deps",
                    "verify",
                    "validate",
                    "/backup",
                ],
                env=target_env,
            )
            with (recovered / "database.dump").open("rb") as stream:
                run(
                    [
                        *target_cmd,
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
                    env=target_env,
                    stdin=stream,
                )
            run(
                [
                    *target_cmd,
                    "run",
                    "--rm",
                    "--no-deps",
                    "verify",
                    "restore",
                    "/backup",
                ],
                env=target_env,
            )
            manifest = json.loads((source / "manifest.json").read_text())
            report = {
                "passed": True,
                "objects": len(manifest["objects"]),
                "database": manifest["database"],
                "tested_at": time.time(),
            }
            (artifacts / "pilot-restore-result.json").write_text(
                json.dumps(report, indent=2)
            )
            print(json.dumps(report))
        finally:
            for project in projects:
                subprocess.run(
                    [*base, "-p", project, "down", "--volumes", "--remove-orphans"],
                    env=env,
                    cwd=ROOT,
                    timeout=120,
                    check=False,
                )
            subprocess.run(
                ["docker", "volume", "rm", volume],
                cwd=ROOT,
                timeout=30,
                check=False,
                capture_output=True,
            )
            reclaim_test_files(work)


if __name__ == "__main__":
    main()
