"""Add email verification fields to users.

Soft email verification (SMP-327 / SMP327-014): we persist a verification
token + expiry and a verified flag, but access is never gated on it.

Revision ID: 0038
Revises: 0037
Create Date: 2026-05-23
"""

import sqlalchemy as sa

from alembic import op

revision = "0038"
down_revision = "0037"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "email_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    op.add_column(
        "users",
        sa.Column("email_verification_token", sa.String(), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("email_verification_expires", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "email_verification_expires")
    op.drop_column("users", "email_verification_token")
    op.drop_column("users", "email_verified")
