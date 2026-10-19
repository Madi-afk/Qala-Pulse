import importlib
import json
import subprocess
from pathlib import Path

import pytest


@pytest.fixture
def maintenance(monkeypatch, tmp_path):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[2] / "scripts"))
    module = importlib.import_module("pilot_ops")
    monkeypatch.setattr(module, "STATE", tmp_path)
    monkeypatch.setattr(module, "COMPOSE", ["compose-test-only"])
    monkeypatch.setattr(module, "restic_env", lambda: {})
    (tmp_path / "transfer").mkdir()
    (tmp_path / "state").mkdir()
    return module


def test_backup_failure_restarts_writers_and_does_not_claim_success(maintenance, monkeypatch):
    commands = []

    def run(args, **kwargs):
        commands.append(args)
        if "export" in args:
            raise subprocess.CalledProcessError(1, args)

    monkeypatch.setattr(maintenance, "run", run)
    with pytest.raises(subprocess.CalledProcessError):
        maintenance.backup()
    assert any(
        "up" in command and "backend" in command and "worker" in command for command in commands
    )
    assert not (maintenance.STATE / "state" / "backup.json").exists()
    assert not (maintenance.STATE / "transfer" / "snapshot").exists()


def test_backup_records_success_only_after_repository_check(maintenance, monkeypatch):
    commands = []
    monkeypatch.setattr(maintenance, "run", lambda args, **kwargs: commands.append(args))
    maintenance.backup()
    assert commands[-1][1] == "forget"
    assert ["restic", "check"] in commands
    assert (
        json.loads((maintenance.STATE / "state" / "backup.json").read_text())["success_timestamp"]
        > 0
    )


def test_backup_preserves_preexisting_staging(maintenance, monkeypatch):
    stage = maintenance.STATE / "transfer" / "snapshot"
    stage.mkdir()
    marker = stage / "keep"
    marker.write_text("user data")
    commands = []
    monkeypatch.setattr(maintenance, "run", lambda args, **kwargs: commands.append(args))
    with pytest.raises(FileExistsError):
        maintenance.backup()
    assert marker.read_text() == "user data"
    assert not any("stop" in command for command in commands)


def test_monitoring_config_uses_private_metrics_and_tls(tmp_path, monkeypatch):
    monkeypatch.syspath_prepend(str(Path(__file__).resolve().parents[2] / "scripts"))
    prepare = importlib.import_module("prepare_pilot")
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
    }
    values.update(
        {
            key: "a" * 64
            for key in [
                "POSTGRES_PASSWORD",
                "JWT_SECRET",
                "MINIO_ROOT_PASSWORD",
                "MINIO_SECRET_KEY",
                "METRICS_TOKEN",
            ]
        }
    )
    prepare.prepare(values, tmp_path)
    config = json.loads((tmp_path / ".pilot/monitoring/prometheus.json").read_text())
    api = config["scrape_configs"][0]
    assert api["metrics_path"] == "/internal/metrics"
    assert "credentials_file" in api["authorization"]
    alert = json.loads((tmp_path / ".pilot/monitoring/alertmanager.json").read_text())
    assert alert["global"]["smtp_require_tls"]
    values["PUBLIC_API_URL"] = "http://pilot.example.test"
    with pytest.raises(ValueError):
        prepare.prepare(values, tmp_path)
