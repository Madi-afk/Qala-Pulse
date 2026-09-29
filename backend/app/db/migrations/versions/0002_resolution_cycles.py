"""Preserve confirmation history and add safe publication cancellation fences."""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "incidents", sa.Column("resolution_cycle", sa.Integer(), nullable=False, server_default="0")
    )
    op.add_column(
        "incident_confirmations",
        sa.Column("resolution_cycle", sa.Integer(), nullable=False, server_default="0"),
    )
    # Legacy confirmations remain in historical cycle 0. A pending/completed repair
    # gets cycle 1 so earlier support cannot block its first post-upgrade evaluation.
    op.execute(
        "UPDATE incidents SET resolution_cycle = 1 WHERE status IN ('resolved_pending_confirmation', 'resolved')"
    )
    op.drop_constraint(
        "incident_confirmations_incident_id_user_id_status_key",
        "incident_confirmations",
        type_="unique",
    )
    op.create_unique_constraint(
        "uq_confirmation_cycle",
        "incident_confirmations",
        ["incident_id", "user_id", "status", "resolution_cycle"],
    )
    op.create_table(
        "publication_cancellations",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("key", sa.String(100), nullable=False),
        sa.UniqueConstraint("user_id", "key"),
    )


def downgrade() -> None:
    # Never delete history or cancellation fences to make a downgrade succeed.
    bind = op.get_bind()
    if bind.scalar(
        sa.text("SELECT EXISTS (SELECT 1 FROM publication_cancellations)")
    ) or bind.scalar(
        sa.text(
            "SELECT EXISTS (SELECT 1 FROM incident_confirmations GROUP BY incident_id, user_id, status HAVING count(*) > 1)"
        )
    ):
        raise RuntimeError(
            "Downgrade would discard confirmation history or publication fences; use a forward migration"
        )
    op.drop_table("publication_cancellations")
    op.drop_constraint("uq_confirmation_cycle", "incident_confirmations", type_="unique")
    op.create_unique_constraint(
        "incident_confirmations_incident_id_user_id_status_key",
        "incident_confirmations",
        ["incident_id", "user_id", "status"],
    )
    op.drop_column("incident_confirmations", "resolution_cycle")
    op.drop_column("incidents", "resolution_cycle")
