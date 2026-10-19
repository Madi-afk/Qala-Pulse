"""Reproduce local detector evidence on public-domain and synthetic fixtures."""

import json
import sys
from io import BytesIO
from pathlib import Path
from time import perf_counter

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))

import cv2
from app.services.privacy.detectors import get_region_detector
from app.services.privacy.redactor import LocalPrivacyRedactor
from PIL import Image
from tests.privacy_samples import street_scene


def main() -> None:
    directory = ROOT / "output" / "privacy-validation"
    directory.mkdir(parents=True, exist_ok=True)
    portrait = Image.open(
        ROOT / "backend/tests/fixtures/privacy/astronaut.png"
    ).convert("RGB")
    street = street_scene()
    cases = [
        ("portrait", portrait, "face", True),
        ("portrait-small", portrait.resize((256, 256)), "face", True),
        (
            "portrait-tilted-35deg",
            portrait.rotate(35, fillcolor=(90, 90, 90)),
            "face",
            True,
        ),
        ("synthetic-plate", street, "license_plate", True),
        ("synthetic-plate-small", street.resize((480, 320)), "license_plate", True),
        (
            "synthetic-plate-tilted-20deg",
            street.rotate(20, fillcolor=(90, 90, 90)),
            "license_plate",
            True,
        ),
        ("synthetic-clear-street", street_scene(plate=False), "license_plate", False),
    ]
    report = {
        "opencv": cv2.__version__,
        "scope": "Small controlled fixture set, not field accuracy",
        "cases": [],
    }
    detector = get_region_detector()
    for name, image, kind, present in cases:
        encoded = BytesIO()
        image.save(encoded, "PNG")
        start = perf_counter()
        regions = detector.detect(image)
        public, _, method = LocalPrivacyRedactor(detector).redact(encoded.getvalue())
        image.save(directory / f"{name}-before.png")
        (directory / f"{name}-after.jpg").write_bytes(public)
        report["cases"].append(
            {
                "case": name,
                "expected_kind": kind,
                "object_present": present,
                "detected_count": sum(r.kind == kind for r in regions),
                "method": method,
                "elapsed_ms": round((perf_counter() - start) * 1000),
            }
        )
    (directory / "report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
