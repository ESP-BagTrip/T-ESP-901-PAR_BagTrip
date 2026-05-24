"""Add validation_status to activities.

Revision ID: 0015
Revises: 0014
Create Date: 2026-03-15
"""

import sqlalchemy as sa

from alembic import op

revision = "0015"
down_revision = "0014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "activities",
        sa.Column("validation_status", sa.String(), nullable=False, server_default="MANUAL"),
    )


def downgrade() -> None:
    op.drop_column("activities", "validation_status")
