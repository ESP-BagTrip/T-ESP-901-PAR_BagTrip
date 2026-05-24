"""Add user plan, subscription and AI quota columns.

Revision ID: 0011
Revises: 0010
Create Date: 2026-03-13
"""

import sqlalchemy as sa

from alembic import op

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("plan", sa.String(10), nullable=False, server_default="FREE"),
    )
    op.execute(
        "ALTER TABLE users ADD CONSTRAINT ck_users_plan CHECK (plan IN ('FREE','PREMIUM','ADMIN'))"
    )
    op.add_column(
        "users",
        sa.Column("stripe_subscription_id", sa.String(), nullable=True),
    )
    op.create_index("ix_users_stripe_subscription_id", "users", ["stripe_subscription_id"])
    op.add_column(
        "users",
        sa.Column("plan_expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("ai_generations_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "users",
        sa.Column("ai_generations_reset_at", sa.DateTime(timezone=True), nullable=True),
    )
    # Seed admin
    op.execute("UPDATE users SET plan = 'ADMIN' WHERE email = 'admin@bagtrip.com'")


def downgrade() -> None:
    op.drop_column("users", "ai_generations_reset_at")
    op.drop_column("users", "ai_generations_count")
    op.drop_column("users", "plan_expires_at")
    op.drop_index("ix_users_stripe_subscription_id", table_name="users")
    op.drop_column("users", "stripe_subscription_id")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS ck_users_plan")
    op.drop_column("users", "plan")
