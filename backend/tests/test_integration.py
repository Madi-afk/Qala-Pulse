"""Black-box tests against a live Compose stack, never a SQLite substitute."""

import io
import os
import time
import wave
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4

import httpx
import pytest

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION") != "1", reason="Set RUN_INTEGRATION=1 with Compose running"
    ),
]
BASE = os.getenv("INTEGRATION_API_URL", "http://localhost:8000/api/v1")


def test_live_postgis_minio_idempotency_and_worker(photo):
    with httpx.Client(base_url=BASE, timeout=30) as client:
        readiness = client.get("/ready")
        assert readiness.status_code == 200, readiness.text
        assert all(readiness.json()["checks"].values())
        response = client.post(
            "/auth/register",
            json={
                "email": f"integration-{uuid4()}@example.com",
                "password": "Test-only-Integration!",
                "display_name": "Integration",
            },
        )
        assert response.status_code == 201, response.text
        headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
        upload = client.post(
            "/uploads/images",
            headers=headers,
            files={"file": ("synthetic.jpg", photo, "image/jpeg")},
        )
        assert upload.status_code == 201, upload.text
        payload = {
            "category_id": "road_damage",
            "title": "Integration PostGIS radius",
            "description": "Synthetic integration test",
            "latitude": 44.12345,
            "longitude": 77.12345,
            "severity": 7,
            "upload_ids": [upload.json()["id"]],
            "reviewed_by_user": True,
        }
        key = str(uuid4())

        def send(_):
            return client.post(
                "/incidents", headers={**headers, "Idempotency-Key": key}, json=payload
            )

        with ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(send, range(4)))
        assert all(result.status_code == 201 for result in results), [r.text for r in results]
        ids = {result.json()["id"] for result in results}
        assert len(ids) == 1
        incident = results[0].json()
        nearby = client.get(
            "/incidents/nearby", params={"latitude": 44.12345, "longitude": 77.12345, "radius": 10}
        )
        assert incident["id"] in [r["id"] for r in nearby.json()["items"]]
        outside = client.get(
            "/incidents/nearby", params={"latitude": 44.13345, "longitude": 77.12345, "radius": 10}
        )
        assert incident["id"] not in [r["id"] for r in outside.json()["items"]]
        assert (
            client.get(incident["media"][0]["url"]).headers["content-type"].startswith("image/jpeg")
        )
        sample = io.BytesIO()
        with wave.open(sample, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(16000)
            wav.writeframes(b"\0\0" * 1600)
        audio = client.post(
            "/uploads/audio",
            headers=headers,
            files={"file": ("voice.wav", sample.getvalue(), "audio/wav")},
            data={"language": "kk"},
        )
        assert audio.status_code == 202, audio.text
        for _ in range(20):
            result = client.get(f"/uploads/{audio.json()['id']}", headers=headers).json()
            if result["status"] in ("ready", "ready_mock"):
                break
            time.sleep(0.5)
        assert result["status"] == "ready_mock"
        assert result["transcript"].startswith("Сынақ")


def test_live_storage_buckets_are_private():
    storage_url = os.getenv("INTEGRATION_STORAGE_URL", "http://localhost:59000")
    with httpx.Client(timeout=10) as client:
        for bucket in ("qalapulse-originals", "qalapulse-redacted"):
            assert client.get(f"{storage_url}/{bucket}").status_code == 403
