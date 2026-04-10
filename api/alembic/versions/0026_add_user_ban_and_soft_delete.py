"""Add banned_at, ban_reason, deleted_at to users table.

Revision ID: 0026
Revises: 1fb93ffa52b4
Create Date: 2026-04-10
"""

from alembic import op
import sqlalchemy as sa


revision = "0026"
down_revision = "1fb93ffa52b4"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("banned_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("ban_reason", sa.String(), nullable=True))
    op.add_column("users", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "deleted_at")
    op.drop_column("users", "ban_reason")
    op.drop_column("users", "banned_at")
