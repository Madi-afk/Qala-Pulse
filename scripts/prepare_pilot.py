"""Prepare local pilot configuration without connecting to external services."""

import argparse
import json
import os
import re
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_env(path: Path) -> dict[str, str]:
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, sep, value = line.partition("=")
        if not sep:
            raise ValueError("Expected KEY=value in pilot environment file")
        value = value.strip()
        if len(value) > 1 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key.strip()] = value
    return values


def validate(values: dict[str, str]) -> None:
    required = [
        "PILOT_DOMAIN",
        "ACME_EMAIL",
        "SMTP_HOST",
        "SMTP_FROM",
        "ALERT_EMAIL",
        "POSTGRES_PASSWORD",
        "JWT_SECRET",
        "MINIO_ROOT_PASSWORD",
        "METRICS_TOKEN",
    ]
    missing = [key for key in required if not values.get(key)]
    if missing:
        raise ValueError("Fill configuration keys: " + ", ".join(missing))
    domain = values["PILOT_DOMAIN"]
    if (
        not re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?", domain)
        or "." not in domain
    ):
        raise ValueError("PILOT_DOMAIN must be a DNS hostname, without scheme or path")
    if values.get("PUBLIC_API_URL") != f"https://{domain}":
        raise ValueError("PUBLIC_API_URL must equal https://PILOT_DOMAIN")
    if (
        values.get("ENVIRONMENT") != "production"
        or values.get("PILOT_REGISTRATION_CLOSED") != "true"
    ):
        raise ValueError("Pilot must use production mode and closed registration")
    for key in [
        "POSTGRES_PASSWORD",
        "JWT_SECRET",
        "MINIO_ROOT_PASSWORD",
        "METRICS_TOKEN",
    ]:
        if not re.fullmatch(r"[a-fA-F0-9]{48,}", values[key]):
            raise ValueError(
                f"{key} must be a generated hex secret of at least 48 characters"
            )
    if values.get("MINIO_SECRET_KEY") != values["MINIO_ROOT_PASSWORD"]:
        raise ValueError("MINIO_SECRET_KEY must match MINIO_ROOT_PASSWORD")
    if values.get("SMTP_TLS") != "starttls":
        raise ValueError("Pilot Alertmanager uses SMTP STARTTLS; configure port 587")


def prepare(values: dict[str, str], root: Path = ROOT) -> None:
    validate(values)
    state = root / ".pilot"
    state.mkdir(mode=0o700, exist_ok=True)
    for name in ("state", "monitoring", "transfer"):
        (state / name).mkdir(mode=0o700 if name == "transfer" else 0o755, exist_ok=True)
    monitoring = state / "monitoring"
    (monitoring / "metrics-token").write_text(values["METRICS_TOKEN"], encoding="utf-8")
    prometheus = {
        "global": {"scrape_interval": "30s", "evaluation_interval": "30s"},
        "rule_files": ["/etc/qalapulse-alerts.yml"],
        "alerting": {
            "alertmanagers": [{"static_configs": [{"targets": ["alertmanager:9093"]}]}]
        },
        "scrape_configs": [
            {
                "job_name": "api",
                "metrics_path": "/internal/metrics",
                "authorization": {"credentials_file": "/etc/prometheus/metrics-token"},
                "static_configs": [{"targets": ["backend:8000"]}],
            },
            {
                "job_name": "maintenance",
                "static_configs": [{"targets": ["ops-metrics:9108"]}],
            },
            {
                "job_name": "alertmanager",
                "static_configs": [{"targets": ["alertmanager:9093"]}],
            },
            {
                "job_name": "public-https",
                "metrics_path": "/probe",
                "params": {"module": ["https_ready"]},
                "static_configs": [
                    {"targets": [values["PUBLIC_API_URL"] + "/api/v1/ready"]}
                ],
                "relabel_configs": [
                    {
                        "source_labels": ["__address__"],
                        "target_label": "__param_target",
                    },
                    {"source_labels": ["__param_target"], "target_label": "instance"},
                    {"target_label": "__address__", "replacement": "blackbox:9115"},
                ],
            },
        ],
    }
    alertmanager = {
        "global": {
            "smtp_smarthost": f"{values['SMTP_HOST']}:{values.get('SMTP_PORT', '587')}",
            "smtp_from": values["SMTP_FROM"],
            "smtp_require_tls": True,
        },
        "route": {
            "receiver": "operator",
            "group_by": ["alertname"],
            "group_wait": "30s",
            "group_interval": "5m",
            "repeat_interval": "4h",
        },
        "receivers": [
            {
                "name": "operator",
                "email_configs": [{"to": values["ALERT_EMAIL"], "send_resolved": True}],
            }
        ],
    }
    if values.get("SMTP_USERNAME"):
        alertmanager["global"].update(
            smtp_auth_username=values["SMTP_USERNAME"],
            smtp_auth_password=values.get("SMTP_PASSWORD", ""),
        )
    for name, content in [
        ("prometheus.json", prometheus),
        ("alertmanager.json", alertmanager),
    ]:
        (monitoring / name).write_text(json.dumps(content, indent=2), encoding="utf-8")
    # Bind-mounted configs must be readable by the unprivileged container users;
    # the parent .pilot directory remains private on the host.
    for path in monitoring.iterdir():
        path.chmod(0o644)
    print(
        "Monitoring configuration prepared. No messages sent and no services started."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--init", action="store_true")
    args = parser.parse_args()
    path = ROOT / ".env.pilot"
    if args.init:
        template = (ROOT / ".env.pilot.example").read_text(encoding="utf-8")
        storage_secret = secrets.token_hex(32)
        for key in (
            "POSTGRES_PASSWORD",
            "JWT_SECRET",
            "METRICS_TOKEN",
            "MINIO_ROOT_PASSWORD",
            "MINIO_SECRET_KEY",
        ):
            value = storage_secret if key.startswith("MINIO") else secrets.token_hex(32)
            template = template.replace(f"{key}=\n", f"{key}={value}\n")
        descriptor = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(template)
        print(
            "Created .env.pilot with random secrets. Fill domain, SMTP and backup settings locally."
        )
        return
    prepare(read_env(path))


if __name__ == "__main__":
    main()
