"""Add feedbacks table for trip feedback.

Revision ID: 0008
Revises: 0007
Create Date: 2026-03-13
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision = "0008"
down_revision = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "feedbacks",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "trip_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("trips.id"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=False,
            index=True,
        ),
        sa.Column("overall_rating", sa.Integer(), nullable=False),
        sa.Column("highlights", sa.Text(), nullable=True),
        sa.Column("lowlights", sa.Text(), nullable=True),
        sa.Column("would_recommend", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint("trip_id", "user_id", name="uq_feedbacks_trip_user"),
    )


def downgrade() -> None:
    op.drop_table("feedbacks")
