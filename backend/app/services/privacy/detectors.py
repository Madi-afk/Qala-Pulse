"""Local region detection. No OCR, identity recognition or network requests."""

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from threading import Lock
from typing import Any, Literal, Protocol

from PIL import Image


@dataclass(frozen=True)
class SensitiveRegion:
    x: int
    y: int
    width: int
    height: int
    kind: Literal["face", "license_plate"]


class RegionDetector(Protocol):
    def detect(self, image: Image.Image) -> list[SensitiveRegion]: ...


class OpenCVRegionDetector:
    """Haar faces/profiles/plates plus high-contrast plate candidates.

    The bundled plate cascade is not trained specifically on Kazakhstan plates.
    The extra geometric pass finds light rectangular plates with aligned dark
    characters. Both passes can miss objects; a successful run is not clearance.
    """

    def __init__(self) -> None:
        import cv2
        import numpy as np

        self.cv: Any = cv2
        self.np: Any = np
        self._lock = Lock()
        directory = Path(self.cv.data.haarcascades)
        self.face = self._load(directory / "haarcascade_frontalface_default.xml")
        self.profile = self._load(directory / "haarcascade_profileface.xml")
        self.plate = self._load(directory / "haarcascade_russian_plate_number.xml")

    def _load(self, path: Path) -> Any:
        if not path.is_file():
            raise RuntimeError("privacy_model_missing")
        classifier = self.cv.CascadeClassifier(str(path))
        if classifier.empty():
            raise RuntimeError("privacy_model_invalid")
        return classifier

    def detect(self, image: Image.Image) -> list[SensitiveRegion]:
        gray = self.cv.cvtColor(self.np.asarray(image), self.cv.COLOR_RGB2GRAY)
        equalized = self.cv.equalizeHist(gray)
        regions: list[SensitiveRegion] = []
        # Cascade instances are shared by HTTP threads, not concurrently mutated.
        with self._lock:
            for model, pixels, mirrored, kind, minimum in [
                (self.face, equalized, False, "face", (24, 24)),
                (self.profile, equalized, False, "face", (24, 24)),
                (self.profile, self.cv.flip(equalized, 1), True, "face", (24, 24)),
                (self.plate, gray, False, "license_plate", (40, 12)),
            ]:
                boxes = model.detectMultiScale(
                    pixels, scaleFactor=1.08, minNeighbors=4, minSize=minimum
                )
                for x, y, width, height in boxes:
                    left = image.width - int(x) - int(width) if mirrored else int(x)
                    regions.append(
                        SensitiveRegion(
                            left,
                            int(y),
                            int(width),
                            int(height),
                            "face" if kind == "face" else "license_plate",
                        )
                    )
        regions.extend(self._light_plate_candidates(gray))
        # Haar and geometric candidates are orientation-sensitive. Rotate pixels
        # for additional passes, then map all four box corners back to the photo.
        for angle in (-30, 30):
            tilted, inverse = self._rotate(equalized, angle)
            with self._lock:
                faces = self.face.detectMultiScale(
                    tilted, scaleFactor=1.08, minNeighbors=4, minSize=(24, 24)
                )
            for x, y, width, height in faces:
                region = SensitiveRegion(int(x), int(y), int(width), int(height), "face")
                regions.append(self._unrotate(region, inverse, image.size))
        for angle in (-20, 20):
            tilted, inverse = self._rotate(gray, angle)
            for region in self._light_plate_candidates(tilted):
                regions.append(self._unrotate(region, inverse, image.size))
        return regions

    def _rotate(self, gray: Any, angle: int) -> tuple[Any, Any]:
        height, width = gray.shape
        transform = self.cv.getRotationMatrix2D((width / 2, height / 2), angle, 1.0)
        return (
            self.cv.warpAffine(gray, transform, (width, height), borderValue=127),
            self.cv.invertAffineTransform(transform),
        )

    def _unrotate(
        self, region: SensitiveRegion, inverse: Any, size: tuple[int, int]
    ) -> SensitiveRegion:
        x, y, width, height = region.x, region.y, region.width, region.height
        corners = (
            self.np.array(
                [[x, y, 1], [x + width, y, 1], [x, y + height, 1], [x + width, y + height, 1]],
                dtype=float,
            )
            @ inverse.T
        )
        left, top = self.np.floor(corners.min(axis=0)).astype(int)
        right, bottom = self.np.ceil(corners.max(axis=0)).astype(int)
        left, top = max(0, int(left)), max(0, int(top))
        right, bottom = min(size[0], int(right)), min(size[1], int(bottom))
        return SensitiveRegion(left, top, right - left, bottom - top, region.kind)

    def _light_plate_candidates(self, gray: Any) -> list[SensitiveRegion]:
        cv = self.cv
        _, light = cv.threshold(gray, 175, 255, cv.THRESH_BINARY)
        light = cv.morphologyEx(light, cv.MORPH_CLOSE, self.np.ones((3, 3), self.np.uint8))
        contours, _ = cv.findContours(light, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE)
        regions = []
        image_area = gray.shape[0] * gray.shape[1]
        for contour in contours:
            x, y, width, height = cv.boundingRect(contour)
            if not (width >= 60 and height >= 16 and 2 <= width / height <= 6.5):
                continue
            if width * height > image_area * 0.2 or cv.contourArea(contour) < width * height * 0.65:
                continue
            plate = gray[y : y + height, x : x + width]
            _, dark = cv.threshold(plate, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU)
            chars, _ = cv.findContours(dark, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE)
            glyphs = []
            for char in chars:
                cx, cy, cw, ch = cv.boundingRect(char)
                if (
                    height * 0.28 <= ch <= height * 0.90
                    and 0.08 <= cw / ch <= 1.25
                    and cx > 0
                    and cy > 0
                    and cx + cw < width
                    and cy + ch < height
                ):
                    glyphs.append((cx, cy + ch / 2, ch))
            if len(glyphs) < 4:
                continue
            # Require a row of comparable glyphs, not arbitrary dark road texture.
            for _, center, char_height in glyphs:
                aligned = [
                    g
                    for g in glyphs
                    if abs(g[1] - center) < height * 0.2 and 0.65 < g[2] / char_height < 1.5
                ]
                if len(aligned) >= 4:
                    regions.append(SensitiveRegion(x, y, width, height, "license_plate"))
                    break
        return regions


@lru_cache(maxsize=1)
def get_region_detector() -> OpenCVRegionDetector:
    return OpenCVRegionDetector()
