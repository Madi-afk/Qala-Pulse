import json
import logging
from datetime import UTC, datetime


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps(
            {
                "time": datetime.now(UTC).isoformat(),
                "level": record.levelname,
                "event": record.getMessage(),
                **{
                    key: getattr(record, key)
                    for key in (
                        "request_id",
                        "method",
                        "route",
                        "status",
                        "duration_ms",
                        "error_type",
                    )
                    if hasattr(record, key)
                },
            },
            ensure_ascii=False,
        )


def configure_logging() -> None:
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())
    logger = logging.getLogger("qalapulse")
    logger.handlers = [handler]
    logger.setLevel(logging.INFO)
    logger.propagate = False
    logging.getLogger("httpx").setLevel(logging.WARNING)
