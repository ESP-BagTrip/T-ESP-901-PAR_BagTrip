"""Create manual_flights table.

Revision ID: 0014
Revises: 0013
Create Date: 2026-03-15
"""

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

from alembic import op

revision = "0014"
down_revision = "0013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "manual_flights",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("flight_number", sa.String(), nullable=False),
        sa.Column("airline", sa.String(), nullable=True),
        sa.Column("departure_airport", sa.String(), nullable=True),
        sa.Column("arrival_airport", sa.String(), nullable=True),
        sa.Column("departure_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("arrival_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("price", sa.Numeric(12, 2), nullable=True),
        sa.Column("currency", sa.String(), nullable=True, server_default="EUR"),
        sa.Column("notes", sa.String(), nullable=True),
        sa.Column("flight_type", sa.String(), nullable=False, server_default="MAIN"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("manual_flights")
