"""Create pending_invites table for link-based invitations.

Revision ID: 0025
Revises: 0024
Create Date: 2026-04-02

"""

import sqlalchemy as sa

from alembic import op

revision = "0025"
down_revision = "0024"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "pending_invites",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "trip_id",
            sa.dialects.postgresql.UUID(as_uuid=True),
            sa.ForeignKey("trips.id"),
            nullable=False,
            index=True,
        ),
        sa.Column("email", sa.String(), nullable=False, index=True),
        sa.Column("role", sa.String(), nullable=False, server_default="VIEWER"),
        sa.Column("token", sa.String(), nullable=False, unique=True, index=True),
        sa.Column("message", sa.String(), nullable=True),
        sa.Column(
            "invited_by",
            sa.dialects.postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("trip_id", "email", name="uq_pending_invites_trip_email"),
    )


def downgrade() -> None:
    op.drop_table("pending_invites")
