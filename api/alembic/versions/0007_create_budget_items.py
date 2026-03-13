"""Create budget_items table.

Revision ID: 0007
Revises: 0006
Create Date: 2026-03-13
"""

import sqlalchemy as sa

from alembic import op

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "budget_items",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "trip_id",
            sa.dialects.postgresql.UUID(as_uuid=True),
            sa.ForeignKey("trips.id"),
            nullable=False,
            index=True,
        ),
        sa.Column("label", sa.String(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("category", sa.String(), nullable=False, server_default="OTHER"),
        sa.Column("date", sa.Date(), nullable=True),
        sa.Column("is_planned", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("budget_items")
