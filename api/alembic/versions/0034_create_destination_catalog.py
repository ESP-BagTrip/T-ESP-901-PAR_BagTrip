"""Create the destination_catalog table for the W3 post-trip RAG.

Revision ID: 0034
Revises: 0033
Create Date: 2026-05-08

The W3 ("post-trip suggestion") flow now grounds the LLM against a
canonical catalogue of destinations. Each row holds:

- the destination identity (IATA + city + country + region),
- short travel-domain metadata used both as RAG features and as the
  LLM's narrative grounding (``types_tags``, ``summary``, climate
  bands, typical daily budget),
- the BGE-M3 embedding precomputed over ``city + country + types_tags
  + summary`` (1024 floats) stored as JSONB so we don't depend on the
  ``pgvector`` extension at our V1 catalogue size.

Seeding the rows is the responsibility of
``src/services/destination_catalog_bootstrap.py`` — the migration
keeps the schema concern separate from the embedding workload.
"""

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision = "0034"
down_revision = "0033"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "destination_catalog",
        sa.Column(
            "id",
            sa.dialects.postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("iata", sa.String(length=3), nullable=False, unique=True),
        sa.Column("city", sa.String(), nullable=False),
        sa.Column("country", sa.String(), nullable=False),
        sa.Column("country_code", sa.String(length=2), nullable=False),
        sa.Column("region", sa.String(), nullable=False),
        sa.Column("types_tags", sa.String(), nullable=False),
        sa.Column("summary", sa.String(), nullable=False),
        sa.Column("avg_summer_temp_c", sa.Integer(), nullable=False),
        sa.Column("avg_winter_temp_c", sa.Integer(), nullable=False),
        sa.Column("daily_budget_eur", sa.Integer(), nullable=False),
        sa.Column("typical_duration_days", sa.Integer(), nullable=False),
        sa.Column("embedding", JSONB(), nullable=False),
        sa.Column("embedding_model", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_index("ix_destination_catalog_iata", "destination_catalog", ["iata"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_destination_catalog_iata", table_name="destination_catalog")
    op.drop_table("destination_catalog")
