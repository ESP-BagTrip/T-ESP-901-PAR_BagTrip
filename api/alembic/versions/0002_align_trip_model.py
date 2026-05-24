"""Align Trip model: uppercase statuses, add budget_total and origin columns.

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-13
"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns
    op.add_column("trips", sa.Column("budget_total", sa.Numeric(12, 2), nullable=True))
    op.add_column(
        "trips",
        sa.Column("origin", sa.String(), nullable=True, server_default="MANUAL"),
    )

    # Migrate statuses to uppercase
    op.execute("UPDATE trips SET status = 'DRAFT' WHERE status = 'draft'")
    op.execute(
        "UPDATE trips SET status = 'PLANNED' WHERE status IN ('planning', 'planned')"
    )
    op.execute("UPDATE trips SET status = 'ONGOING' WHERE status = 'active'")
    op.execute(
        "UPDATE trips SET status = 'COMPLETED' WHERE status IN ('completed', 'archived')"
    )

    # Backfill origin
    op.execute("UPDATE trips SET origin = 'MANUAL' WHERE origin IS NULL")


def downgrade() -> None:
    # Revert statuses to lowercase
    op.execute("UPDATE trips SET status = 'draft' WHERE status = 'DRAFT'")
    op.execute("UPDATE trips SET status = 'planning' WHERE status = 'PLANNED'")
    op.execute("UPDATE trips SET status = 'active' WHERE status = 'ONGOING'")
    op.execute("UPDATE trips SET status = 'completed' WHERE status = 'COMPLETED'")

    # Drop columns
    op.drop_column("trips", "origin")
    op.drop_column("trips", "budget_total")
