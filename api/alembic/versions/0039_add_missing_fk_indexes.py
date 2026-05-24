"""Add missing FK indexes (SMP327-070).

Two foreign-key columns were declared without an index, forcing sequential
scans whenever rows are filtered/joined by them:

- ``flight_orders.flight_offer_id`` — joined on every FlightOffer relationship
  load (``FlightOffer.orders`` back_populates).
- ``bookings.user_id`` — still read by the (deprecated) bookings listing.

Index names match SQLAlchemy's auto-generated ``ix_<table>_<column>`` so the
model ``index=True`` declarations stay in sync with the schema.

Revision ID: 0039
Revises: 0038
Create Date: 2026-05-23
"""

from alembic import op

revision = "0039"
down_revision = "0038"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_index(
        "ix_flight_orders_flight_offer_id",
        "flight_orders",
        ["flight_offer_id"],
        unique=False,
    )
    op.create_index(
        "ix_bookings_user_id",
        "bookings",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_bookings_user_id", table_name="bookings")
    op.drop_index("ix_flight_orders_flight_offer_id", table_name="flight_orders")
