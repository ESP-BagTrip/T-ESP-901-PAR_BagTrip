"""Add accommodations and baggage_items tables.

Revision ID: 0005
Revises: 0004
Create Date: 2026-03-13
"""

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

from alembic import op

# revision identifiers, used by Alembic.
revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create accommodations and baggage_items tables."""
    op.create_table(
        "accommodations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("name", sa.String, nullable=False),
        sa.Column("address", sa.String, nullable=True),
        sa.Column("check_in", sa.Date, nullable=True),
        sa.Column("check_out", sa.Date, nullable=True),
        sa.Column("price", sa.Numeric(12, 2), nullable=True),
        sa.Column("currency", sa.String(3), nullable=True, server_default="EUR"),
        sa.Column("booking_reference", sa.String, nullable=True),
        sa.Column("notes", sa.String, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "baggage_items",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=False, index=True),
        sa.Column("name", sa.String, nullable=False),
        sa.Column("quantity", sa.Integer, nullable=True, server_default="1"),
        sa.Column("is_packed", sa.Boolean, nullable=True, server_default="false"),
        sa.Column("category", sa.String, nullable=True),
        sa.Column("notes", sa.String, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    """Drop baggage_items and accommodations tables."""
    op.drop_table("baggage_items")
    op.drop_table("accommodations")
