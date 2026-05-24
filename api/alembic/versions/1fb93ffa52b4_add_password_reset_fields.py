"""add_password_reset_fields

Revision ID: 1fb93ffa52b4
Revises: 0021
Create Date: 2026-03-27 14:04:32.303919

"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = '1fb93ffa52b4'
down_revision: str | None = '0021'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("password_reset_token", sa.String(), nullable=True))
    op.add_column("users", sa.Column("password_reset_expires", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "password_reset_expires")
    op.drop_column("users", "password_reset_token")
