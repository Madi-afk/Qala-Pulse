from io import BytesIO
from typing import Protocol

from PIL import Image, ImageFilter, ImageOps

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
