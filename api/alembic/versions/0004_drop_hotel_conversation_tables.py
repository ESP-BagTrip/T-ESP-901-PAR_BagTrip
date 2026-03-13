"""Drop hotel and conversation tables.

Revision ID: 0004
Revises: 0003
Create Date: 2026-03-13
"""

from alembic import op

# revision identifiers, used by Alembic.
revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Drop hotel_bookings, hotel_offers, hotel_searches, contexts, messages, conversations tables."""
    op.drop_table("contexts")
    op.drop_table("messages")
    op.drop_table("conversations")
    op.drop_table("hotel_bookings")
    op.drop_table("hotel_offers")
    op.drop_table("hotel_searches")


def downgrade() -> None:
    """Cannot recreate dropped tables — data is lost."""
    raise NotImplementedError("Downgrade not supported: tables were dropped with data loss")
