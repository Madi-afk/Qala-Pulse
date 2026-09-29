import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.deps import Db
from app.db.session import get_db


@pytest.mark.parametrize("commit_fails", [False, True])
def test_database_commit_precedes_http_response(commit_fails):
    events = []
    probe = FastAPI()

    def transaction():
        events.append("begin")
        yield object()
        events.append("commit")
        if commit_fails:
            raise RuntimeError("synthetic_commit_failure")

    probe.dependency_overrides[get_db] = transaction

    @probe.get("/probe")
    def endpoint(db: Db):
        events.append("handler")
        return {"ok": True}

    async def observed(scope, receive, send):
        async def capture(message):
            if message["type"] == "http.response.start":
                events.append("response")
            await send(message)

        await probe(scope, receive, capture)

    with TestClient(observed, raise_server_exceptions=False) as client:
        assert client.get("/probe").status_code == (500 if commit_fails else 200)
    assert events == ["begin", "handler", "commit", "response"]
