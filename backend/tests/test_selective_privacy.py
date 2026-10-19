from io import BytesIO
from pathlib import Path

import numpy as np
import pytest
from PIL import Image, ImageChops, ImageDraw

from app.core.config import get_settings
from app.services.privacy.detectors import (
    OpenCVRegionDetector,
    SensitiveRegion,
    get_region_detector,
)
from app.services.privacy.redactor import (
    LocalPrivacyRedactor,
    get_privacy_redactor,
    normalized_image,
    padded_box,
    redact_regions,
)
from tests.privacy_samples import street_scene

FIXTURES = Path(__file__).parent / "fixtures" / "privacy"


@pytest.mark.parametrize("kind,angle", [("face", 35), ("license_plate", 20)])
def test_tilted_detection_masks_the_correct_original_coordinates(kind, angle):
    if kind == "face":
        image = Image.open(FIXTURES / "astronaut.png").convert("RGB")
        box = (180, 70, 270, 155)
    else:
        image = street_scene()
        box = (625, 296, 855, 340)
    truth = Image.new("L", image.size)
    ImageDraw.Draw(truth).rectangle(box, fill=255)
    truth = truth.rotate(angle)
    image = image.rotate(angle, fillcolor=(90, 90, 90))
    regions = get_region_detector().detect(image)
    mask = Image.new("L", image.size)
    draw = ImageDraw.Draw(mask)
    for region in regions:
        if region.kind == kind:
            draw.rectangle(padded_box(region, image), fill=255)
    expected = np.asarray(truth) > 0
    assert ((np.asarray(mask) > 0) & expected).sum() / expected.sum() > 0.95
    result = redact_regions(image, regions)
    assert (
        np.abs(np.asarray(result).astype(float) - np.asarray(image).astype(float))[expected].mean()
        > 15
    )


def encoded(image, **kwargs):
    stream = BytesIO()
    image.save(stream, "PNG", **kwargs)
    return stream.getvalue()


def overlap(a, b):
    x, y = max(a.x, b[0]), max(a.y, b[1])
    right, bottom = min(a.x + a.width, b[2]), min(a.y + a.height, b[3])
    return max(0, right - x) * max(0, bottom - y) / ((b[2] - b[0]) * (b[3] - b[1]))


@pytest.mark.parametrize("scale", [1, 0.5])
def test_actual_face_detector_on_public_domain_portrait(scale):
    with Image.open(FIXTURES / "astronaut.png") as original:
        image = original.convert("RGB").resize((int(512 * scale), int(512 * scale)))
    expected = tuple(int(v * scale) for v in (175, 60, 280, 175))
    regions = get_region_detector().detect(image)
    assert any(r.kind == "face" and overlap(r, expected) > 0.5 for r in regions)
    public, thumbnail, method = LocalPrivacyRedactor().redact(encoded(image))
    assert method == "local_opencv_regions_v1"
    with Image.open(BytesIO(public)) as redacted:
        face_before = np.asarray(image.crop(expected)).astype(float)
        face_after = np.asarray(redacted.crop(expected)).astype(float)
        assert np.abs(face_before - face_after).mean() > 15
    with Image.open(BytesIO(thumbnail)) as small:
        assert max(small.size) <= 320


@pytest.mark.parametrize("scale", [1, 0.75, 0.5])
def test_actual_plate_detection_and_road_detail_preserved(scale):
    image = street_scene().resize((int(960 * scale), int(640 * scale)))
    expected = tuple(int(v * scale) for v in (615, 286, 868, 352))
    regions = get_region_detector().detect(image)
    assert any(r.kind == "license_plate" and overlap(r, expected) > 0.65 for r in regions)
    public, _, method = LocalPrivacyRedactor().redact(encoded(image))
    assert method == "local_opencv_regions_v1"
    with Image.open(BytesIO(public)) as redacted:
        plate = np.asarray(redacted.crop(expected)).astype(float)
        original_plate = np.asarray(image.crop(expected)).astype(float)
        assert np.abs(plate - original_plate).mean() > 20
        # The pothole and crossing remain readable (only JPEG loss is tolerated).
        road_box = tuple(int(v * scale) for v in (25, 390, 530, 610))
        road_error = np.abs(
            np.asarray(redacted.crop(road_box)).astype(float)
            - np.asarray(image.crop(road_box)).astype(float)
        ).mean()
        assert road_error < 4


def test_mask_only_changes_padded_regions_and_clips_at_edges():
    image = street_scene()
    regions = [
        SensitiveRegion(615, 286, 253, 66, "license_plate"),
        SensitiveRegion(0, 0, 24, 24, "face"),
    ]
    result = redact_regions(image, regions)
    assert (
        ImageChops.difference(
            image.crop((0, 400, 960, 640)), result.crop((0, 400, 960, 640))
        ).getbbox()
        is None
    )
    assert ImageChops.difference(image, result).getbbox() is not None


def test_clear_scene_remains_detailed_but_has_no_safety_claim():
    image = street_scene(plate=False)
    public, _, method = LocalPrivacyRedactor().redact(encoded(image))
    assert method == "local_opencv_no_regions_v1"
    with Image.open(BytesIO(public)) as processed:
        assert (
            np.abs(np.asarray(processed).astype(float) - np.asarray(image).astype(float)).mean() < 4
        )


def test_exif_orientation_and_metadata_are_removed():
    exif = Image.Exif()
    exif[274] = 6
    exif[270] = "private description"
    frame = normalized_image(encoded(Image.new("RGB", (90, 40), "red"), exif=exif))
    assert frame.size == (40, 90)
    assert not frame.info and not frame.getexif()
    public, thumb, _ = LocalPrivacyRedactor().redact(encoded(frame))
    for data in (public, thumb):
        with Image.open(BytesIO(data)) as result:
            assert not result.getexif()
            assert "icc_profile" not in result.info


def test_detector_failure_masks_whole_image_without_logging_data(caplog):
    class BrokenDetector:
        def detect(self, image):
            raise RuntimeError("private image path and number ABC123")

    image = street_scene()
    public, _, method = LocalPrivacyRedactor(BrokenDetector()).redact(encoded(image))
    assert method == "whole_frame_detector_fallback"
    assert "ABC123" not in caplog.text
    assert "private image path" not in caplog.text
    with Image.open(BytesIO(public)) as masked:
        assert (
            np.abs(np.asarray(masked).astype(float) - np.asarray(image).astype(float)).mean() > 10
        )


def test_missing_model_fails_closed(monkeypatch):
    monkeypatch.setattr(Path, "is_file", lambda _: False)
    with pytest.raises(RuntimeError, match="privacy_model_missing"):
        OpenCVRegionDetector()


def test_missing_dependency_uses_whole_frame_fallback(monkeypatch):
    def unavailable():
        raise ImportError("model unavailable")

    monkeypatch.setattr("app.services.privacy.redactor.get_region_detector", unavailable)
    image = street_scene()
    public, _, method = get_privacy_redactor().redact(encoded(image))
    assert method == "whole_frame_detector_fallback"
    with Image.open(BytesIO(public)) as masked:
        assert (
            np.abs(np.asarray(masked).astype(float) - np.asarray(image).astype(float)).mean() > 10
        )


def test_full_frame_setting_and_user_override(monkeypatch):
    data = encoded(street_scene())
    monkeypatch.setattr(get_settings(), "privacy_mode", "full_frame")
    assert get_privacy_redactor().redact(data)[2] == "whole_frame_mock_mosaic"
    monkeypatch.setattr(get_settings(), "privacy_mode", "local")
    assert get_privacy_redactor(full_frame=True).redact(data)[2] == "whole_frame_mock_mosaic"


def test_upload_preview_and_public_routes_never_serve_original(client, headers):
    data = encoded(street_scene())
    response = client.post(
        "/api/v1/uploads/images", headers=headers, files={"file": ("street.png", data, "image/png")}
    )
    assert response.status_code == 201
    upload = response.json()
    assert upload["privacy_review_required"] is True
    assert upload["privacy_method"] == "local_opencv_regions_v1"
    image_id = upload["id"]
    preview = client.get(f"/api/v1/uploads/{image_id}/preview", headers=headers)
    assert preview.status_code == 200 and preview.content != data
    assert client.get(f"/api/v1/uploads/{image_id}/preview").status_code == 401
    assert client.get(f"/api/v1/media/{image_id}/image").status_code == 404
    assert client.get(f"/api/v1/media/{image_id}/original").status_code == 422
    result = client.post(
        "/api/v1/incidents",
        headers={**headers, "Idempotency-Key": "privacy-photo-test"},
        json={
            "category_id": "road_damage",
            "title": "Test pothole",
            "description": "Synthetic scene",
            "latitude": 43.2389,
            "longitude": 76.8897,
            "severity": 7,
            "upload_ids": [image_id],
            "reviewed_by_user": True,
        },
    )
    assert result.status_code == 201, result.text
    assert client.get(f"/api/v1/media/{image_id}/image").content == preview.content
    response = client.post(
        "/api/v1/uploads/images",
        headers=headers,
        data={"full_frame": "true"},
        files={"file": ("street.png", data, "image/png")},
    )
    assert response.status_code == 201
    assert response.json()["privacy_method"] == "whole_frame_mock_mosaic"
