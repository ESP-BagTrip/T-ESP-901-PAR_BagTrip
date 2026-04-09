"""Add destination_timezone to trips.

Revision ID: 0023
Revises: 0022
Create Date: 2026-04-02

"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "0023"
down_revision = "0022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column("destination_timezone", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("trips", "destination_timezone")
