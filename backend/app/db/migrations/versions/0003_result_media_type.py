"""Allow the existing after_image discriminator without PostgreSQL truncation."""

import sqlalchemy as sa
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "incident_media",
        "media_type",
        existing_type=sa.String(10),
        type_=sa.String(20),
        existing_nullable=False,
    )


def downgrade() -> None:
    # Refuse truncation when result photos already exist; no data is silently lost.
    connection = op.get_bind()
    if connection.scalar(
        sa.text("SELECT count(*) FROM incident_media WHERE length(media_type) > 10")
    ):
        raise RuntimeError("Cannot downgrade while result photos use long media types")
    op.alter_column(
        "incident_media",
        "media_type",
        existing_type=sa.String(20),
        type_=sa.String(10),
        existing_nullable=False,
    )
