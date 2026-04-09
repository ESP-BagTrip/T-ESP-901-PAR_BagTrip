"""Add payment_id and ticket_url to flight_orders.

Revision ID: 0013
Revises: 0012
Create Date: 2026-03-14
"""

import sqlalchemy as sa

from alembic import op

revision = "0013"
down_revision = "0012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("flight_orders", sa.Column("payment_id", sa.String(), nullable=True))
    op.add_column("flight_orders", sa.Column("ticket_url", sa.String(), nullable=True))

    # Backfill payment_id from linked booking_intents
    op.execute(
        """
        UPDATE flight_orders fo
        SET payment_id = bi.stripe_payment_intent_id
        FROM booking_intents bi
        WHERE fo.booking_intent_id = bi.id
        AND bi.stripe_payment_intent_id IS NOT NULL
        """
    )


def downgrade() -> None:
    op.drop_column("flight_orders", "ticket_url")
    op.drop_column("flight_orders", "payment_id")
