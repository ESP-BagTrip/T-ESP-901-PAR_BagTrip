"""Add device_tokens.locale and migrate notifications.data to JSONB.

Revision ID: 0036
Revises: 0035
Create Date: 2026-05-21

SMP-326 — notification cleanup:

1. ``device_tokens.locale`` — stores the app locale ("fr"/"en") reported at
   token registration, so background jobs can localize push notifications
   (they have no request context to read an Accept-Language header from).
2. ``notifications.data`` JSON → JSONB — the deduplication query filters on
   ``data['<key>'].astext``; JSONB makes that operator-class indexable and is
   the preferred Postgres type for queried JSON payloads.
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision = "0036"
down_revision = "0035"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "device_tokens",
        sa.Column("locale", sa.String(), nullable=True),
    )
    op.alter_column(
        "notifications",
        "data",
        type_=postgresql.JSONB(astext_type=sa.Text()),
        existing_type=sa.JSON(),
        existing_nullable=True,
        postgresql_using="data::jsonb",
    )


def downgrade() -> None:
    op.alter_column(
        "notifications",
        "data",
        type_=sa.JSON(),
        existing_type=postgresql.JSONB(astext_type=sa.Text()),
        existing_nullable=True,
        postgresql_using="data::json",
    )
    op.drop_column("device_tokens", "locale")
