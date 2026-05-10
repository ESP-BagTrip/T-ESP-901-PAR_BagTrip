"""Catalogue of canonical travel destinations + their precomputed embeddings.

The W3 post-trip suggester is a RAG flow grounded against this catalogue:
the user's recent feedback is embedded and we cosine-match against
:class:`DestinationCatalog` rows. The LLM never picks a destination —
it only narrates the match the deterministic step has chosen.

The embedding is stored as a JSON array (1024 floats — :data:`bge-m3`
output dimension) so we do not depend on the ``pgvector`` extension
being installed on the host. At our V1 catalogue size (~40 entries)
the cosine pass is microseconds in Python; we can pivot to pgvector
without a model change once the catalogue grows past a few hundred
rows.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import DateTime, Index, Integer, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class DestinationCatalog(Base):
    """One row per canonical destination available to the post-trip RAG."""

    __tablename__ = "destination_catalog"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Canonical identity — IATA is the primary key in the wizard payload.
    iata: Mapped[str] = mapped_column(String(3), nullable=False, unique=True)
    city: Mapped[str] = mapped_column(String, nullable=False)
    country: Mapped[str] = mapped_column(String, nullable=False)
    country_code: Mapped[str] = mapped_column(String(2), nullable=False)
    region: Mapped[str] = mapped_column(String, nullable=False)  # Europe / Asia / …

    # Travel-domain metadata used both as RAG features and as the LLM's
    # narrative grounding (the suggester promises ``highlightsMatch``
    # built from these fields).
    types_tags: Mapped[str] = mapped_column(String, nullable=False)  # CSV
    summary: Mapped[str] = mapped_column(String, nullable=False)
    avg_summer_temp_c: Mapped[int] = mapped_column(Integer, nullable=False)
    avg_winter_temp_c: Mapped[int] = mapped_column(Integer, nullable=False)
    daily_budget_eur: Mapped[int] = mapped_column(Integer, nullable=False)
    typical_duration_days: Mapped[int] = mapped_column(Integer, nullable=False)

    # Embedding of ``city + country + types_tags + summary`` produced by
    # the OVH ``bge-m3`` model (1024 floats). ``JSONB`` keeps the column
    # portable across Postgres deployments without pgvector.
    embedding: Mapped[list[float]] = mapped_column(JSONB, nullable=False)
    embedding_model: Mapped[str] = mapped_column(String, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (Index("ix_destination_catalog_iata", "iata"),)
