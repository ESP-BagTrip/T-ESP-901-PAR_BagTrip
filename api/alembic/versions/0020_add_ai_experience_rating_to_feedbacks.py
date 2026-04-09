"""Add ai_experience_rating column to feedbacks table.

Revision ID: 0020
Revises: 0019
Create Date: 2026-03-21

Nullable integer (1-5) for rating the AI planning experience.
"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "0020"
down_revision = "0019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "feedbacks",
        sa.Column("ai_experience_rating", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("feedbacks", "ai_experience_rating")
