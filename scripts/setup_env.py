"""Generate local-only secrets without printing or overwriting existing configuration."""
import secrets
from pathlib import Path

root = Path(__file__).resolve().parents[1]
target = root / ".env"
if target.exists():
    print(".env already exists; preserved.")
else:
    database_secret, storage_secret = secrets.token_urlsafe(32), secrets.token_urlsafe(32)
    replacements = {
        "POSTGRES_PASSWORD": database_secret,
        "JWT_SECRET": secrets.token_urlsafe(64),
        "MINIO_ROOT_PASSWORD": storage_secret,
        "MINIO_SECRET_KEY": storage_secret,
        "DATABASE_URL": f"postgresql+psycopg://qalapulse:{database_secret}@localhost:55432/qalapulse",
    }
    lines = []
    for line in (root / ".env.example").read_text(encoding="utf-8").splitlines():
        key = line.split("=", 1)[0]
        lines.append(f"{key}={replacements[key]}" if key in replacements else line)
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Created .env with random local secrets. Never commit this file.")
