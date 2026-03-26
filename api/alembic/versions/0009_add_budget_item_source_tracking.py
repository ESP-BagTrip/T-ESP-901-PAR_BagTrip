"""Add source_type and source_id to budget_items for auto-sync.

Revision ID: 0009
Revises: 0008
Create Date: 2025-05-01
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

# revision identifiers
revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("budget_items", sa.Column("source_type", sa.String(), nullable=True))
    op.add_column("budget_items", sa.Column("source_id", UUID(as_uuid=True), nullable=True))
    op.create_index("ix_budget_items_source", "budget_items", ["source_type", "source_id"])


def downgrade() -> None:
    op.drop_index("ix_budget_items_source", table_name="budget_items")
    op.drop_column("budget_items", "source_id")
    op.drop_column("budget_items", "source_type")
