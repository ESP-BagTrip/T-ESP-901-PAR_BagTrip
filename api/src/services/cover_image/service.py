"""Cover-image orchestrator (SMP-330).

Public surface:

- ``CoverImageService.pick_cover(destination, *, locale)`` — used by trip
  creation and AI plan flows. Returns a ``CoverResult`` with a rehosted
  primary URL plus a few rehosted alternatives.
- ``CoverImageService.refresh_cover(destination, *, locale, exclude_urls)``
  — used by the ``POST /trips/{id}/cover/refresh`` endpoint. Forces a
  fresh pick (bypasses cache) and excludes the URLs the user already saw.

The orchestrator is the only layer aware of all three providers, the
``LocalCoverStore`` and the ``DistributedCache``. Callers stay completely
unaware of where the image came from.
"""

from __future__ import annotations

import asyncio
from dataclasses import asdict, dataclass
from typing import Any

from src.integrations.cover_image.commons import commons_geo_cover_client
from src.integrations.cover_image.types import CoverCandidate, CoverSource
from src.integrations.cover_image.wikidata import wikidata_cover_client
from src.integrations.cover_image.wikipedia import wikipedia_cover_client
from src.integrations.distributed_cache import DistributedCache
from src.services.cover_image.local_store import LocalCoverStore, local_cover_store
from src.services.cover_image.scorer import rank_candidates
from src.utils.logger import logger

# Cap how many alternatives we rehost up-front. Empirically the user
# either keeps the primary or swaps to one of the first 3 alternatives;
# more than that is disk noise. ``primary + 4 alternatives = 5`` matches
# the slot count in the mobile bottom sheet.
_MAX_REHOSTED = 5


@dataclass(frozen=True)
class CoverResult:
    """Resolved cover plus the alternatives surfaced to the picker UI."""

    primary_url: str
    primary_source: CoverSource
    candidates: list[CoverCandidate]

    def as_db_payload(self) -> dict[str, object]:
        """Project to the (cover_image_url, cover_image_source, cover_image_candidates) trio."""
        return {
            "cover_image_url": self.primary_url,
            "cover_image_source": self.primary_source,
            "cover_image_candidates": [asdict(c) for c in self.candidates],
        }


class CoverImageService:
    """No-API-key cover picker with local re-hosting and Redis cache."""

    _cache = DistributedCache("cover_image", ttl_seconds=7 * 24 * 3600)

    def __init__(self, store: LocalCoverStore | None = None) -> None:
        self._store = store or local_cover_store

    # ── Public API ────────────────────────────────────────────────────

    async def pick_cover(
        self,
        destination: str,
        *,
        locale: str = "en",
    ) -> CoverResult | None:
        """Resolve a cover for ``destination``. Returns ``None`` if every
        provider missed — callers fall back to the existing client-side
        gradient placeholder.
        """
        cache_key = self._cache_key(destination, locale)
        cached = self._cache.get(cache_key)
        if cached is not None:
            return self._result_from_cache(cached)

        candidates = await self._collect_candidates(destination, locale=locale)
        if not candidates:
            return None

        ranked = await rank_candidates(destination, candidates)
        result = await self._rehost(ranked)
        if result is None:
            return None
        self._cache.set(cache_key, self._result_to_cache(result))
        return result

    async def refresh_cover(
        self,
        destination: str,
        *,
        locale: str = "en",
        exclude_urls: set[str] | None = None,
    ) -> CoverResult | None:
        """Force a fresh pick — bypasses the cache and skips ``exclude_urls``.

        Used by ``POST /trips/{id}/cover/refresh`` to give the user a new
        batch when they exhausted the initially-surfaced alternatives.
        """
        candidates = await self._collect_candidates(destination, locale=locale)
        if exclude_urls:
            candidates = [c for c in candidates if c.url not in exclude_urls]
        if not candidates:
            return None
        ranked = await rank_candidates(destination, candidates)
        return await self._rehost(ranked)

    # ── Pipeline ──────────────────────────────────────────────────────

    async def _collect_candidates(
        self,
        destination: str,
        *,
        locale: str,
    ) -> list[CoverCandidate]:
        """Fan out to all providers and concatenate their candidates.

        Wikipedia and Wikidata run in parallel — they don't depend on
        each other and both produce coords usable by Commons geosearch.
        Commons is awaited last because its query depends on the
        coordinates either of the previous two produced.
        """
        wiki_task = asyncio.create_task(
            wikipedia_cover_client.fetch_candidates(destination, locale=locale)
        )
        wd_task = asyncio.create_task(
            wikidata_cover_client.fetch_candidates(destination, locale=locale)
        )
        (wiki_candidates, wiki_coords), (wd_candidates, wd_coords) = await asyncio.gather(
            wiki_task, wd_task
        )

        coords = wiki_coords or wd_coords
        commons_candidates: list[CoverCandidate] = []
        if coords is not None:
            commons_candidates = await commons_geo_cover_client.fetch_candidates(
                lat=coords[0], lng=coords[1], limit=_MAX_REHOSTED
            )

        # Deduplicate by URL — the same Commons file can surface as both
        # Wikidata's P18 and a Commons geosearch hit.
        seen: set[str] = set()
        merged: list[CoverCandidate] = []
        for c in [*wiki_candidates, *wd_candidates, *commons_candidates]:
            if c.url in seen:
                continue
            seen.add(c.url)
            merged.append(c)
        return merged

    async def _rehost(self, candidates: list[CoverCandidate]) -> CoverResult | None:
        """Download top-N candidates, swap their URLs for the local ones."""
        top = candidates[:_MAX_REHOSTED]
        rehosted_urls = await asyncio.gather(
            *(self._store.fetch_and_store(c.url) for c in top),
            return_exceptions=False,
        )
        rehosted: list[CoverCandidate] = []
        for original, new_url in zip(top, rehosted_urls, strict=True):
            if not new_url:
                continue
            rehosted.append(
                CoverCandidate(
                    url=new_url,
                    source=original.source,
                    title=original.title,
                    attribution=original.attribution,
                    width=original.width,
                    height=original.height,
                    extra=original.extra,
                )
            )
        if not rehosted:
            logger.warn("All candidates failed to rehost; no cover available")
            return None
        primary = rehosted[0]
        return CoverResult(
            primary_url=primary.url,
            primary_source=primary.source,
            candidates=rehosted,
        )

    # ── Cache helpers ─────────────────────────────────────────────────

    @staticmethod
    def _cache_key(destination: str, locale: str) -> str:
        return f"{locale}:{destination.strip().lower()}"

    @staticmethod
    def _result_to_cache(result: CoverResult) -> dict[str, Any]:
        return {
            "primary_url": result.primary_url,
            "primary_source": result.primary_source,
            "candidates": [asdict(c) for c in result.candidates],
        }

    @staticmethod
    def _result_from_cache(raw: dict[str, Any]) -> CoverResult:
        return CoverResult(
            primary_url=str(raw["primary_url"]),
            primary_source=raw["primary_source"],
            candidates=[CoverCandidate(**c) for c in raw["candidates"]],
        )


cover_image_service = CoverImageService()
