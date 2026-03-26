"""Add medical_constraints to traveler_profiles.

Revision ID: 0016
Revises: 0015
Create Date: 2026-03-15
"""

import sqlalchemy as sa
from alembic import op

revision = "0016"
down_revision = "0015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "traveler_profiles",
        sa.Column("medical_constraints", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("traveler_profiles", "medical_constraints")
