"""Private maintenance/worker exporter. No user data or exception messages in metrics."""

import json
import shutil
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from app.workers.tasks import celery_app


def metrics() -> str:
    lines = []
    for job in ("backup", "restore", "retention"):
        try:
            timestamp = float(
                json.loads(Path(f"/state/{job}.json").read_text())["success_timestamp"]
            )
        except (OSError, ValueError, KeyError):
            timestamp = 0.0
        lines.append(f"qalapulse_{job}_success_timestamp {timestamp}")
    try:
        available = bool(celery_app.control.ping(timeout=3))
    except Exception:
        available = False
    lines.append(f"qalapulse_worker_available {int(available)}")
    disk = shutil.disk_usage("/state")
    lines.append(f"qalapulse_disk_free_ratio {disk.free / disk.total}")
    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path != "/metrics":
            self.send_error(404)
            return
        payload = metrics().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args: object) -> None:
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 9108), Handler).serve_forever()
