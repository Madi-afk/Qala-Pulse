"""Run real services on disposable, uniquely named volumes. Never reads .env."""

import os
import secrets
import socket
import subprocess
import sys
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]


def port() -> int:
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def main() -> None:
    project = f"qalapulse-check-{uuid4().hex[:10]}"
    artifact = ROOT / "artifacts" / f"{project}.env"
    artifact.parent.mkdir(exist_ok=True)
    password, storage_password = secrets.token_hex(24), secrets.token_hex(24)
    api_port, pg_port, redis_port, minio_port, console_port = (port() for _ in range(5))
    values = {
        "ENVIRONMENT": "test",
        "AI_MODE": "mock",
        "POSTGRES_USER": "qalapulse",
        "POSTGRES_PASSWORD": password,
        "POSTGRES_DB": "qalapulse_test",
        "JWT_SECRET": secrets.token_hex(32),
        "MINIO_ROOT_USER": "qalapulse-test",
        "MINIO_ROOT_PASSWORD": storage_password,
        "MINIO_ACCESS_KEY": "qalapulse-test",
        "MINIO_SECRET_KEY": storage_password,
        "PUBLIC_API_URL": f"http://localhost:{api_port}",
        "CHECK_API_PORT": str(api_port),
        "CHECK_POSTGRES_PORT": str(pg_port),
        "CHECK_REDIS_PORT": str(redis_port),
        "CHECK_MINIO_PORT": str(minio_port),
        "CHECK_CONSOLE_PORT": str(console_port),
        "CHECK_ENV_FILE": artifact.as_posix(),
    }
    artifact.write_text(
        "\n".join(f"{key}={value}" for key, value in values.items()) + "\n",
        encoding="utf-8",
    )
    compose = [
        "docker",
        "compose",
        "--env-file",
        str(artifact),
        "-p",
        project,
        "-f",
        "docker-compose.yml",
        "-f",
        "docker-compose.integration.yml",
    ]
    compose_env = os.environ | values
    print(f"Isolated integration project: {project}", flush=True)
    try:
        subprocess.run(
            [*compose, "up", "--build", "-d", "--wait", "--wait-timeout", "240"],
            cwd=ROOT,
            env=compose_env,
            check=True,
        )
        subprocess.run(
            [*compose, "exec", "-T", "backend", "python", "-m", "app.seed"],
            cwd=ROOT,
            env=compose_env,
            check=True,
        )
        subprocess.run(
            [*compose, "exec", "-T", "backend", "alembic", "current"],
            cwd=ROOT,
            env=compose_env,
            check=True,
        )
        env = os.environ | {
            "RUN_INTEGRATION": "1",
            "QALAPULSE_INTEGRATION_ISOLATED": "1",
            "INTEGRATION_API_URL": f"http://localhost:{api_port}/api/v1",
            "INTEGRATION_STORAGE_URL": f"http://localhost:{minio_port}",
            "INTEGRATION_DATABASE_URL": f"postgresql+psycopg://qalapulse:{password}@127.0.0.1:{pg_port}/qalapulse_test",
        }
        subprocess.run(
            [
                sys.executable,
                "-m",
                "pytest",
                "backend/tests",
                "-m",
                "integration",
                "-v",
                "--tb=short",
                "--show-capture=no",
                "-o",
                "faulthandler_timeout=45",
            ],
            cwd=ROOT,
            env=env,
            check=True,
            timeout=300,
        )
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        subprocess.run(
            [*compose, "logs", "--tail=60", "backend", "worker", "minio-init"],
            cwd=ROOT,
            env=compose_env,
            check=False,
        )
        raise
    finally:
        # The generated project name is the boundary: no existing project is removed.
        subprocess.run(
            [*compose, "down", "--volumes", "--remove-orphans"],
            cwd=ROOT,
            env=compose_env,
            check=True,
        )
        artifact.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
