import logging
from io import BytesIO
from typing import Protocol

from PIL import Image, ImageFilter, ImageOps

from app.core.config import get_settings
from app.services.privacy.detectors import RegionDetector, SensitiveRegion, get_region_detector

Image.MAX_IMAGE_PIXELS = 20_000_000


class PrivacyRedactor(Protocol):
    def redact(self, data: bytes) -> tuple[bytes, bytes, str]: ...


class ConservativeMockRedactor:
    """Fail closed: erase identifying detail across the entire frame, strip metadata."""

    def redact(self, data: bytes) -> tuple[bytes, bytes, str]:
        with Image.open(BytesIO(data)) as original:
            original.load()
            frame = ImageOps.exif_transpose(original).convert("RGB")
            frame.thumbnail((1600, 1600))
            # Coarse whole-frame mosaic covers unrecognized plates and faces too.
            frame = frame.resize((12, 12), Image.Resampling.BILINEAR).resize(
                frame.size, Image.Resampling.NEAREST
            )
            frame = frame.filter(ImageFilter.GaussianBlur(12))
            result, thumbnail = BytesIO(), BytesIO()
            frame.save(result, "JPEG", quality=85)
            frame.thumbnail((320, 320))
            frame.save(thumbnail, "JPEG", quality=75)
            return result.getvalue(), thumbnail.getvalue(), "whole_frame_mock_mosaic"


def normalized_image(data: bytes) -> Image.Image:
    with Image.open(BytesIO(data)) as original:
        original.load()
        frame = ImageOps.exif_transpose(original).convert("RGB")
        frame.thumbnail((1600, 1600))
        # Copy pixels into a clean image, without EXIF, ICC, comments or XMP.
        return Image.frombytes("RGB", frame.size, frame.tobytes())


def padded_box(region: SensitiveRegion, image: Image.Image) -> tuple[int, int, int, int]:
    if region.width <= 0 or region.height <= 0:
        raise ValueError("invalid_privacy_region")
    margin = 0.22 if region.kind == "face" else 0.18
    dx, dy = max(4, round(region.width * margin)), max(4, round(region.height * margin))
    box = (
        max(0, region.x - dx),
        max(0, region.y - dy),
        min(image.width, region.x + region.width + dx),
        min(image.height, region.y + region.height + dy),
    )
    if box[0] >= box[2] or box[1] >= box[3]:
        raise ValueError("privacy_region_outside_image")
    return box


def redact_regions(image: Image.Image, regions: list[SensitiveRegion]) -> Image.Image:
    result = image.copy()
    for region in regions:
        box = padded_box(region, image)
        crop = image.crop(box)
        # A fixed, very coarse grid destroys text/face detail before softening edges.
        grid = (4, 2) if region.kind == "license_plate" else (5, 5)
        crop = crop.resize(grid, Image.Resampling.BILINEAR).resize(
            crop.size, Image.Resampling.NEAREST
        )
        crop = crop.filter(ImageFilter.GaussianBlur(max(8, min(crop.size) / 4)))
        result.paste(crop, box)
    return result


def encode_images(frame: Image.Image) -> tuple[bytes, bytes]:
    result, thumbnail = BytesIO(), BytesIO()
    frame.save(result, "JPEG", quality=92, subsampling=0)
    small = frame.copy()
    small.thumbnail((320, 320))
    small.save(thumbnail, "JPEG", quality=85)
    return result.getvalue(), thumbnail.getvalue()


class LocalPrivacyRedactor:
    def __init__(self, detector: RegionDetector | None = None) -> None:
        self.detector = detector

    def redact(self, data: bytes) -> tuple[bytes, bytes, str]:
        # Invalid images are rejected by the upload handler, not retried as clear originals.
        frame = normalized_image(data)
        try:
            regions = (self.detector or get_region_detector()).detect(frame)
            if len(regions) > 200:
                raise ValueError("privacy_region_limit")
            frame = redact_regions(frame, regions)
        except Exception as error:
            logging.getLogger("qalapulse").warning(
                "privacy_detection_fallback", extra={"error_type": type(error).__name__}
            )
            public, thumbnail, _ = ConservativeMockRedactor().redact(data)
            return public, thumbnail, "whole_frame_detector_fallback"
        public, thumbnail = encode_images(frame)
        method = "local_opencv_regions_v1" if regions else "local_opencv_no_regions_v1"
        return public, thumbnail, method


def get_privacy_redactor(*, full_frame: bool = False) -> PrivacyRedactor:
    if full_frame or get_settings().privacy_mode == "full_frame":
        return ConservativeMockRedactor()
    return LocalPrivacyRedactor()
