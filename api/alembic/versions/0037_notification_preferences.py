"""Add notification_preferences table.

Revision ID: 0037
Revises: 0036
Create Date: 2026-05-23

SMP-327 — per-user notification preferences:

One row per user (PK = user_id). Every category flag defaults to TRUE so the
absence of a row means "everything enabled". ``push_enabled`` is the master
switch gating the whole dispatch (system ADMIN notifications excepted). The
FK cascades on user deletion as a safety net alongside the explicit cleanup
in ``delete_me``.
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision = "0037"
down_revision = "0036"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "notification_preferences",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "push_enabled", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
        sa.Column(
            "flight_reminders", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
        sa.Column(
            "activity_reminders", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
        sa.Column(
            "trip_updates", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
        sa.Column(
            "budget_alerts", sa.Boolean(), nullable=False, server_default=sa.true()
        ),
        sa.Column("social", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id"),
    )


def downgrade() -> None:
    op.drop_table("notification_preferences")
