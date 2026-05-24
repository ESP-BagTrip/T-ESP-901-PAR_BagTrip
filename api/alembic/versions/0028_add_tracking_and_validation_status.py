"""Add tracking flags on trips and validation_status on accommodations/manual_flights.

Revision ID: 0028
Revises: 0027
Create Date: 2026-04-18
"""

import sqlalchemy as sa

from alembic import op

revision = "0028"
down_revision = "0027"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column(
            "flights_tracking",
            sa.String(),
            nullable=False,
            server_default="TRACKED",
        ),
    )
    op.add_column(
        "trips",
        sa.Column(
            "accommodations_tracking",
            sa.String(),
            nullable=False,
            server_default="TRACKED",
        ),
    )
    op.add_column(
        "accommodations",
        sa.Column(
            "validation_status",
            sa.String(),
            nullable=False,
            server_default="MANUAL",
        ),
    )
    op.add_column(
        "manual_flights",
        sa.Column(
            "validation_status",
            sa.String(),
            nullable=False,
            server_default="MANUAL",
        ),
    )


def downgrade() -> None:
    op.drop_column("manual_flights", "validation_status")
    op.drop_column("accommodations", "validation_status")
    op.drop_column("trips", "accommodations_tracking")
    op.drop_column("trips", "flights_tracking")
