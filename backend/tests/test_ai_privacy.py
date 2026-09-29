from io import BytesIO

import httpx
import pytest
from PIL import Image
from pydantic import ValidationError

from app.core.config import get_settings
from app.schemas.common import VisionResult
from app.services.ai.providers import (
    CompatibleCloudProvider,
    MockSpeechTranscriber,
    MockVisionAnalyzer,
    analyze_with_fallback,
)
from app.services.privacy.redactor import ConservativeMockRedactor


def test_invalid_cloud_json_falls_back_without_false_confidence(monkeypatch):
    monkeypatch.setattr(get_settings(), "ai_mode", "cloud")

    def invalid(*args):
        raise ValueError("invalid JSON")

    monkeypatch.setattr(CompatibleCloudProvider, "analyze", invalid)
    result = analyze_with_fallback(b"image", "Открытый люк", True)
    assert result["fallback"] is True
    assert result["mode"] == "mock"
    assert result["result"]["confidence"] == 0


def test_cloud_timeout_fallback_and_consent(monkeypatch):
    monkeypatch.setattr(get_settings(), "ai_mode", "cloud")
    calls = []

    def timeout(*args):
        calls.append(True)
        raise httpx.ReadTimeout("timeout")

    monkeypatch.setattr(CompatibleCloudProvider, "analyze", timeout)
    assert analyze_with_fallback(b"", "яма", False)["mode"] == "mock"
    assert not calls
    assert analyze_with_fallback(b"", "яма", True)["fallback"]
    assert calls


def test_strict_vision_validation():
    data = MockVisionAnalyzer().analyze(b"", "яма").model_dump()
    for update in [
        {"severity": 11},
        {"confidence": 1.1},
        {"category_code": "invented"},
        {"unexpected": True},
    ]:
        with pytest.raises(ValidationError):
            VisionResult.model_validate(data | update)


def test_redaction_strips_metadata_and_changes_pixels():
    source = Image.new("RGB", (240, 240), "white")
    for x in range(50, 70):
        for y in range(20, 220):
            source.putpixel((x, y), (0, 0, 0))
    exif = Image.Exif()
    exif[270] = "private metadata"
    stream = BytesIO()
    source.save(stream, "JPEG", exif=exif)
    redacted, thumbnail, method = ConservativeMockRedactor().redact(stream.getvalue())
    assert method == "whole_frame_mock_mosaic"
    assert redacted != stream.getvalue()
    with Image.open(BytesIO(redacted)) as image:
        assert not image.getexif()
    with Image.open(BytesIO(thumbnail)) as thumb:
        assert max(thumb.size) <= 320


def test_speech_mock_bilingual():
    provider = MockSpeechTranscriber()
    assert provider.transcribe(b"", "audio/wav", "ru").startswith("Тестовый")
    assert provider.transcribe(b"", "audio/wav", "kk").startswith("Сынақ")
