import math
import re
from datetime import UTC
from typing import Any, Protocol

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.base import utcnow
from app.repositories.incidents import nearby, serialize
from app.schemas.common import DuplicateSearch
from app.services.ai.providers import CompatibleCloudProvider
from app.services.geospatial.priority import distance_meters


class DuplicateDetector(Protocol):
    def search(self, db: Session, data: DuplicateSearch) -> list[dict[str, Any]]: ...


def text_similarity(a: str, b: str) -> float:
    words_a, words_b = set(re.findall(r"\w+", a.casefold())), set(re.findall(r"\w+", b.casefold()))
    return len(words_a & words_b) / len(words_a | words_b) if words_a | words_b else 0


class GeoTextDuplicateDetector:
    def search(self, db: Session, data: DuplicateSearch) -> list[dict[str, Any]]:
        settings = get_settings()
        candidates = nearby(
            db,
            data.latitude,
            data.longitude,
            settings.duplicate_radius_meters,
            data.category_id,
            settings.duplicate_days,
            limit=100,
        )
        source_text = f"{data.title} {data.description}"
        similarities = [
            text_similarity(source_text, f"{i.title} {i.description}") for i in candidates
        ]
        if (
            candidates
            and settings.ai_mode == "cloud"
            and data.cloud_consent
            and settings.ai_embedding_model
        ):
            try:
                vectors = CompatibleCloudProvider().embeddings(
                    [source_text] + [f"{i.title} {i.description}" for i in candidates]
                )

                def cosine(a: list[float], b: list[float]) -> float:
                    norm = math.sqrt(sum(x * x for x in a) * sum(y * y for y in b))
                    return (
                        max(0, min(1, sum(x * y for x, y in zip(a, b, strict=True)) / norm))
                        if norm
                        else 0
                    )

                similarities = [cosine(vectors[0], v) for v in vectors[1:]]
                if len(similarities) != len(candidates):
                    raise ValueError("embedding_count")
            except Exception:
                similarities = [
                    text_similarity(source_text, f"{i.title} {i.description}") for i in candidates
                ]
        result: list[dict[str, Any]] = []
        for item, text_score in zip(candidates, similarities, strict=True):
            if item.status in ("resolved", "rejected"):
                continue
            distance = distance_meters(data.latitude, data.longitude, item.latitude, item.longitude)
            geo = max(0, 1 - distance / settings.duplicate_radius_meters)
            age = max(0, (utcnow() - item.created_at.replace(tzinfo=UTC)).total_seconds() / 86400)
            temporal = max(0, 1 - age / settings.duplicate_days)
            score = geo * 0.4 + text_score * 0.3 + 0.2 + temporal * 0.1
            if score >= settings.duplicate_threshold:
                result.append(
                    {
                        "incident": serialize(db, item),
                        "similarity_score": round(score, 4),
                        "distance_meters": round(distance, 1),
                        "text_similarity": round(text_score, 4),
                        "image_similarity": None,
                    }
                )
        return sorted(result, key=lambda i: i["similarity_score"], reverse=True)[:10]
