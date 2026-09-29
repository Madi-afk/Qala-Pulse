import json

import httpx

from app.core.config import get_settings
from app.services.ai.providers import CompatibleCloudProvider, MockVisionAnalyzer


def test_cloud_retries_invalid_schema_then_accepts_valid_json(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "ai_base_url", "https://ai.example.com/v1")
    monkeypatch.setattr(settings, "ai_api_key", "test-key-only")
    monkeypatch.setattr(settings, "ai_vision_model", "test-vision")
    valid = MockVisionAnalyzer().analyze(b"", "открытый люк").model_dump()
    captured = []

    def handler(request):
        captured.append(json.loads(request.content))
        content = '{"severity":99}' if len(captured) == 1 else json.dumps(valid)
        return httpx.Response(200, json={"choices": [{"message": {"content": content}}]})

    original_client = httpx.Client
    monkeypatch.setattr(
        httpx,
        "Client",
        lambda **kwargs: original_client(transport=httpx.MockTransport(handler), **kwargs),
    )
    result = CompatibleCloudProvider().analyze(b"fake-test-image", "открытый люк")
    assert result.category_code == "open_manhole"
    assert len(captured) == 2
    assert captured[0]["response_format"]["json_schema"]["strict"] is True
    assert captured[0]["messages"][1]["content"][1]["image_url"]["url"].startswith(
        "data:image/jpeg;base64,"
    )


def test_cloud_speech_passes_language_and_validates_result(monkeypatch):
    settings = get_settings()
    monkeypatch.setattr(settings, "ai_base_url", "https://ai.example.com/v1")
    monkeypatch.setattr(settings, "ai_api_key", "test-key-only")
    captured = []

    def handler(request):
        captured.append(request)
        return httpx.Response(200, json={"text": "Жолда шұңқыр бар"})

    original_client = httpx.Client
    monkeypatch.setattr(
        httpx,
        "Client",
        lambda **kwargs: original_client(transport=httpx.MockTransport(handler), **kwargs),
    )
    assert (
        CompatibleCloudProvider().transcribe(b"RIFF-test", "audio/wav", "kk") == "Жолда шұңқыр бар"
    )
    assert b'name="language"\r\n\r\nkk' in captured[0].content
