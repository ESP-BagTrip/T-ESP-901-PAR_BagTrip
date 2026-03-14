"""Cleanup data models: enums, nullable fixes, price→price_per_night, rating constraint.

Revision ID: 0012
Revises: 0011
Create Date: 2026-03-14
"""

from alembic import op

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Normalize legacy trip statuses
    op.execute("UPDATE trips SET status = 'DRAFT' WHERE status IN ('draft', 'planning') OR status IS NULL")
    op.execute("UPDATE trips SET status = 'PLANNED' WHERE status = 'planned'")
    op.execute("UPDATE trips SET status = 'ONGOING' WHERE status = 'active'")
    op.execute("UPDATE trips SET status = 'COMPLETED' WHERE status IN ('completed', 'archived')")

    # 2. Trip.status NOT NULL + DEFAULT
    op.alter_column("trips", "status", nullable=False, server_default="DRAFT")

    # 3. BaggageItem nullable fixes
    op.execute("UPDATE baggage_items SET quantity = 1 WHERE quantity IS NULL")
    op.execute("UPDATE baggage_items SET is_packed = false WHERE is_packed IS NULL")
    op.execute("UPDATE baggage_items SET category = 'OTHER' WHERE category IS NULL")

    op.alter_column("baggage_items", "quantity", nullable=False, server_default="1")
    op.alter_column("baggage_items", "is_packed", nullable=False, server_default="false")
    op.alter_column("baggage_items", "category", nullable=False, server_default="OTHER")

    # 4. Accommodation: rename price → price_per_night
    op.alter_column("accommodations", "price", new_column_name="price_per_night")

    # 5. Feedback CHECK constraint (rating 1-5)
    op.execute(
        "ALTER TABLE feedbacks ADD CONSTRAINT ck_feedbacks_rating "
        "CHECK (overall_rating >= 1 AND overall_rating <= 5)"
    )


def downgrade() -> None:
    # 5. Drop feedback CHECK constraint
    op.execute("ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS ck_feedbacks_rating")

    # 4. Rename back price_per_night → price
    op.alter_column("accommodations", "price_per_night", new_column_name="price")

    # 3. Revert BaggageItem nullable
    op.alter_column("baggage_items", "category", nullable=True, server_default=None)
    op.alter_column("baggage_items", "is_packed", nullable=True, server_default=None)
    op.alter_column("baggage_items", "quantity", nullable=True, server_default=None)

    # 2. Revert Trip.status nullable
    op.alter_column("trips", "status", nullable=True, server_default=None)
