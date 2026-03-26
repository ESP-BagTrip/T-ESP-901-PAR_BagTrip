"""Migrate accommodation check_in/check_out from Date to DateTime.

Revision ID: 0021
Revises: 0020
Create Date: 2026-03-22

Supports check-in/check-out times (not just dates).
"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "0021"
down_revision = "0020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "accommodations",
        "check_in",
        type_=sa.DateTime(timezone=True),
        existing_type=sa.Date(),
    )
    op.alter_column(
        "accommodations",
        "check_out",
        type_=sa.DateTime(timezone=True),
        existing_type=sa.Date(),
    )


def downgrade() -> None:
    op.alter_column(
        "accommodations",
        "check_in",
        type_=sa.Date(),
        existing_type=sa.DateTime(timezone=True),
    )
    op.alter_column(
        "accommodations",
        "check_out",
        type_=sa.Date(),
        existing_type=sa.DateTime(timezone=True),
    )
