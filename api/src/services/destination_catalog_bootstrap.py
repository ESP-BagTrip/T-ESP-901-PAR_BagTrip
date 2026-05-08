"""Idempotently populate the ``destination_catalog`` table.

Called from :meth:`PostTripSuggester.suggest_next_trip` the first time
the table is empty so an operator does not have to remember to run a
seed script. Re-running the bootstrapper is safe — it only inserts
rows whose ``iata`` is not already present.

The embedding workload happens here (one BGE-M3 call per row) so the
heavy LLM cost is paid exactly once per deployment instead of on every
post-trip request. We embed sequentially with a progress log so an
on-call engineer can tail the run if the catalogue ever grows.
"""

from __future__ import annotations

from sqlalchemy.orm import Session

from src.config.env import settings
from src.models.destination_catalog import DestinationCatalog
from src.services.destination_catalog_data import CATALOG, CatalogEntry
from src.services.llm_router import LLMRouter
from src.utils.logger import logger


def _embedding_text(entry: CatalogEntry) -> str:
    """The corpus we embed for cosine matching against user feedback.

    City + country + region + free-form ``types_tags`` + the curated
    ``summary`` together form a stable vocabulary the BGE-M3 model
    can compare against the highlights / lowlights the user wrote.
    """
    return (
        f"{entry.city}, {entry.country} ({entry.region}). "
        f"Tags: {entry.types_tags}. "
        f"Summary: {entry.summary}"
    )


async def bootstrap_destination_catalog(db: Session, *, force: bool = False) -> int:
    """Insert any missing CATALOG entry into ``destination_catalog``.

    Returns the number of rows actually inserted (0 when the catalogue
    is already in sync). Setting ``force=True`` re-embeds existing
    rows — useful when the embedding model changes.
    """
    existing = {row.iata: row for row in db.query(DestinationCatalog).all()}
    missing = [entry for entry in CATALOG if entry.iata not in existing]

    if not missing and not force:
        return 0

    targets = CATALOG if force else missing
    inserts = 0
    router = LLMRouter.get()
    model = settings.LLM_EMBEDDING_MODEL
    for entry in targets:
        text = _embedding_text(entry)
        vectors = await router.embed(inputs=[text], model=model)
        if not vectors:
            logger.warn(
                "destination_catalog bootstrap: embed returned empty",
                {"iata": entry.iata},
            )
            continue
        embedding = vectors[0]
        if force and entry.iata in existing:
            row = existing[entry.iata]
            row.summary = entry.summary
            row.types_tags = entry.types_tags
            row.embedding = embedding
            row.embedding_model = model
        else:
            db.add(
                DestinationCatalog(
                    iata=entry.iata,
                    city=entry.city,
                    country=entry.country,
                    country_code=entry.country_code,
                    region=entry.region,
                    types_tags=entry.types_tags,
                    summary=entry.summary,
                    avg_summer_temp_c=entry.avg_summer_temp_c,
                    avg_winter_temp_c=entry.avg_winter_temp_c,
                    daily_budget_eur=entry.daily_budget_eur,
                    typical_duration_days=entry.typical_duration_days,
                    embedding=embedding,
                    embedding_model=model,
                )
            )
            inserts += 1

    db.commit()
    logger.info(
        "destination_catalog bootstrap done",
        {"inserts": inserts, "total_targets": len(targets), "force": force},
    )
    return inserts


__all__ = ["bootstrap_destination_catalog"]
