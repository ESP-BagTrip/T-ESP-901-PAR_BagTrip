"""Add date_mode column to trips table.

Revision ID: 0019
Revises: 0018
Create Date: 2026-03-19

Supports 3 modes: EXACT (default), MONTH, FLEXIBLE.
"""

import sqlalchemy as sa

from alembic import op

revision = "0019"
down_revision = "0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column("date_mode", sa.String(), nullable=False, server_default="EXACT"),
    )


def downgrade() -> None:
    op.drop_column("trips", "date_mode")
