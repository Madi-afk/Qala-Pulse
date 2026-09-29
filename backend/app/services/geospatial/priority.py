import math
from datetime import UTC, datetime
from typing import Any, Protocol

from app.db.base import utcnow


def distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    a = (
        math.sin((p2 - p1) / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lon2 - lon1) / 2) ** 2
    )
    return 6371008.8 * 2 * math.asin(min(1, math.sqrt(a)))


class SensitiveLocationProvider(Protocol):
    def score(self, latitude: float, longitude: float) -> float: ...


class DemoSensitiveLocations:
    # Synthetic zones; these are not verified schools, hospitals or transit stops.
    zones = [
        (43.2389, 76.8897, 8),
        (43.241, 76.892, 7),
        (43.235, 76.886, 5),
        (43.245, 76.900, 4),
        (43.232, 76.894, 6),
    ]

    def score(self, latitude: float, longitude: float) -> float:
        return max(
            (
                score
                for lat, lon, score in self.zones
                if distance_meters(latitude, longitude, lat, lon) <= 150
            ),
            default=0,
        )


def priority(
    base: int,
    severity: int,
    confirmations: int,
    created_at: datetime,
    latitude: float,
    longitude: float,
) -> tuple[float, dict[str, Any]]:
    age_days = max(0, (utcnow() - created_at.replace(tzinfo=UTC)).total_seconds() / 86400)
    parts = {
        "category": base * 4,
        "severity": severity * 3,
        "confirmations": min(confirmations, 20) * 1.5,
        "recency": round(max(0, 10 - age_days), 2),
        "sensitive_location": DemoSensitiveLocations().score(latitude, longitude),
    }
    score = round(sum(parts.values()), 2)
    return score, {
        "components": parts,
        "ru": f"{'Высокий' if score >= 65 else 'Обычный'} приоритет: опасность {severity}/10, подтверждений жителей: {confirmations}. Близость к тестовой зоне: +{parts['sensitive_location']}.",
        "kk": f"{'Жоғары' if score >= 65 else 'Қалыпты'} басымдық: қауіп {severity}/10, тұрғындар растауы: {confirmations}. Сынақ аймағы: +{parts['sensitive_location']}.",
    }
