"""Add travel_frequency to traveler_profiles.

Revision ID: 0022
Revises: 1fb93ffa52b4
Create Date: 2026-04-02

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "0022"
down_revision = "1fb93ffa52b4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "traveler_profiles",
        sa.Column("travel_frequency", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("traveler_profiles", "travel_frequency")
