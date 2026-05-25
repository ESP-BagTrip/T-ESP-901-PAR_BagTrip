"""Track cover image source + alternative candidates (SMP-330).

Adds two columns to ``trips`` so the new no-API-key cover image system can:

- record which source the active cover came from (Wikipedia summary,
  Wikidata P18, Wikimedia Commons geosearch, OSM tile composition,
  user selection, legacy Unsplash). Useful for analytics, debugging,
  and to know when re-picking is worth it (a Wikipedia hit is better
  than an OSM map fallback).
- store the alternative candidates considered during the pick so the
  "Change cover" UI can offer a swap without re-querying every source.
  Candidates list is opaque JSON: ``[{"url": "...", "source": "..."}]``.

Revision ID: 0040
Revises: 0039
Create Date: 2026-05-24
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0040"
down_revision = "0039"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trips",
        sa.Column("cover_image_source", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "trips",
        sa.Column(
            "cover_image_candidates",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("trips", "cover_image_candidates")
    op.drop_column("trips", "cover_image_source")
