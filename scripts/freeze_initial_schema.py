"""One-time developer utility: freeze SQL DDL; deployed migrations never import live models."""
from pathlib import Path
from sqlalchemy.dialects import postgresql
from sqlalchemy.schema import CreateIndex, CreateTable
from app.db.base import Base
from app.db import models  # noqa: F401

target = Path(__file__).resolve().parents[1] / "backend/app/db/migrations/versions/0001_initial.py"
if target.exists():
    raise SystemExit("Initial migration already exists; create a new revision instead.")
tables = list(Base.metadata.sorted_tables)
ddl = ["CREATE EXTENSION IF NOT EXISTS postgis"]
for table in tables:
    ddl.append(str(CreateTable(table).compile(dialect=postgresql.dialect())).strip())
    ddl.extend(str(CreateIndex(index).compile(dialect=postgresql.dialect())) for index in table.indexes)
ddl.append("CREATE INDEX ix_incidents_location_gist ON incidents USING GIST (location)")
target.parent.mkdir(parents=True, exist_ok=True)
body = '\n\n'.join(f"    op.execute({statement!r})" for statement in ddl)
down = '\n'.join(f"    op.drop_table({table.name!r})" for table in reversed(tables))
target.write_text('"""Initial frozen PostgreSQL/PostGIS schema."""\nfrom alembic import op\n\nrevision = "0001"\ndown_revision = None\nbranch_labels = None\ndepends_on = None\n\ndef upgrade() -> None:\n' + body + '\n\ndef downgrade() -> None:\n' + down + '\n', encoding="utf-8")
print("Frozen initial migration.")
