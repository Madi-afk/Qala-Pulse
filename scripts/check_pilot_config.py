"""Validate deploy configurations with upstream binaries and synthetic credentials."""

import os
import secrets
import subprocess
import tempfile
from pathlib import Path

from prepare_pilot import ROOT, prepare


def run(args, **kwargs):
    subprocess.run(args, cwd=ROOT, check=True, timeout=300, **kwargs)


def main():
    (ROOT / "artifacts").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix="pilot-config-", dir=ROOT / "artifacts"
    ) as directory:
        root = Path(directory)
        values = {
            "PILOT_DOMAIN": "pilot.example.test",
            "PUBLIC_API_URL": "https://pilot.example.test",
            "ACME_EMAIL": "operator@example.test",
            "SMTP_HOST": "smtp.example.test",
            "SMTP_FROM": "noreply@example.test",
            "ALERT_EMAIL": "operator@example.test",
            "ENVIRONMENT": "production",
            "PILOT_REGISTRATION_CLOSED": "true",
            "SMTP_TLS": "starttls",
            "POSTGRES_USER": "qalapulse",
            "POSTGRES_DB": "qalapulse",
            "MINIO_ROOT_USER": "pilot-check",
        }
        for key in (
            "POSTGRES_PASSWORD",
            "JWT_SECRET",
            "MINIO_ROOT_PASSWORD",
            "METRICS_TOKEN",
        ):
            values[key] = secrets.token_hex(32)
        values["MINIO_SECRET_KEY"] = values["MINIO_ROOT_PASSWORD"]
        env_file = root / "synthetic.env"
        values["PILOT_ENV_FILE"] = env_file.as_posix()
        env_file.write_text(
            "\n".join(f"{key}={value}" for key, value in values.items())
        )
        prepare(values, root)
        run(
            [
                "docker",
                "compose",
                "--env-file",
                str(env_file),
                "-f",
                "docker-compose.pilot.yml",
                "config",
                "--quiet",
            ],
            env=os.environ | values,
        )
        monitoring = (root / ".pilot/monitoring").as_posix()
        alerts = (ROOT / "infrastructure/pilot/alerts.yml").as_posix()
        run(
            [
                "docker",
                "run",
                "--rm",
                "--entrypoint",
                "promtool",
                "-v",
                f"{monitoring}:/etc/prometheus:ro",
                "-v",
                f"{alerts}:/etc/qalapulse-alerts.yml:ro",
                "prom/prometheus:v3.5.0",
                "check",
                "config",
                "/etc/prometheus/prometheus.json",
            ]
        )
        run(
            [
                "docker",
                "run",
                "--rm",
                "--entrypoint",
                "amtool",
                "-v",
                f"{monitoring}:/etc/alertmanager:ro",
                "prom/alertmanager:v0.28.1",
                "check-config",
                "/etc/alertmanager/alertmanager.json",
            ]
        )
        caddy = (ROOT / "infrastructure/pilot/Caddyfile").as_posix()
        run(
            [
                "docker",
                "run",
                "--rm",
                "-e",
                "PILOT_DOMAIN=pilot.example.test",
                "-e",
                "ACME_EMAIL=operator@example.test",
                "-v",
                f"{caddy}:/etc/caddy/Caddyfile:ro",
                "caddy:2.10.2-alpine",
                "caddy",
                "validate",
                "--config",
                "/etc/caddy/Caddyfile",
            ]
        )
        print(
            "Pilot Compose, Prometheus alerts, Alertmanager and Caddy configurations validated. No real email or certificate issued."
        )


if __name__ == "__main__":
    main()
