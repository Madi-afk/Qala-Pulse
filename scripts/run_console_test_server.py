"""Isolated browser-test server. Never uses the workspace .env, DB or storage."""

import argparse
import logging
import os
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18765)
    args = parser.parse_args()
    with TemporaryDirectory(prefix="qalapulse-console-test-") as temporary:
        from app.core.config import Settings

        Settings.model_config["env_file"] = None
        os.environ.update(
            ENVIRONMENT="test",
            DATABASE_URL=f"sqlite:///{Path(temporary).as_posix()}/console.db",
            STORAGE_MODE="local",
            STORAGE_PATH=str(Path(temporary) / "storage"),
            RATE_LIMIT_ENABLED="false",
            AI_MODE="mock",
            PRIVACY_MODE="local",
            PUBLIC_API_URL=f"http://127.0.0.1:{args.port}",
            JWT_SECRET="console-tests-only-not-for-deployment-0123456789",
        )
        import uvicorn
        from app.db.base import Base
        from app.db.models import Incident
        from app.db.session import SessionLocal, engine
        from app.main import app
        from app.seed import seed, seed_id

        logging.getLogger("qalapulse.http").setLevel(logging.WARNING)

        # Reset endpoint exists exclusively in this disposable, loopback test server.
        @app.post("/__test__/reset")
        def reset() -> dict[str, str]:
            Base.metadata.drop_all(engine)
            Base.metadata.create_all(engine)
            seed()
            with SessionLocal.begin() as db:
                first = db.get(Incident, seed_id("incident-0"))
                duplicate = db.get(Incident, seed_id("incident-7"))
                assert first is not None and duplicate is not None
                first.title = "Яма у школы № 12"
                duplicate.title = "Яма у школы № 12 — повтор"
                duplicate.description = first.description
                duplicate.status = "published"
                first.description = (
                    "<img src=x onerror=alert(1)> Проверка безопасного текста"
                )
                duplicate.description = first.description
            return {
                "incident": str(seed_id("incident-0")),
                "duplicate": str(seed_id("incident-7")),
            }

        reset()
        try:
            uvicorn.run(
                app,
                host="127.0.0.1",
                port=args.port,
                log_level="warning",
                access_log=False,
            )
        finally:
            engine.dispose()


if __name__ == "__main__":
    main()
