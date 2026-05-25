"""Wikidata entity lookup — disambiguation-resistant cover source (SMP-330).

Wikipedia summaries fail in two cases that Wikidata fixes:

- the destination is a disambiguation page (``Paris`` → Paris, Texas vs
  Paris, France). Wikidata's full-text search ranks entities by
  ``sitelinks``, so the most-linked-to ``Paris`` comes first;
- the article lacks a lead image but the entity has ``P18`` (Image)
  populated from a Commons file (common for small towns).

The flow is two calls:

1. ``wbsearchentities`` to resolve the free-text query to a QID;
2. ``Special:EntityData/{QID}.json`` to read ``claims.P18`` and
   coordinates (``P625``).

Both endpoints are unauthenticated and share Wikipedia's lenient quota
for well-behaved User-Agents.
"""

from __future__ import annotations

from typing import Any
from urllib.parse import quote

from src.integrations.cover_image._http import DEFAULT_TIMEOUT_S, WIKIMEDIA_HEADERS
from src.integrations.cover_image.types import CoverCandidate
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_SEARCH_URL = "https://www.wikidata.org/w/api.php"
_ENTITY_BASE = "https://www.wikidata.org/wiki/Special:EntityData"
# Commons proxy resolves a bare file name to its full-resolution URL
# without us needing to compute the hash-based path ourselves.
_COMMONS_FILE_URL = "https://commons.wikimedia.org/wiki/Special:FilePath"


def _commons_url(file_name: str, *, width: int = 1280) -> str:
    """Build a direct image URL from a Commons file name."""
    return f"{_COMMONS_FILE_URL}/{quote(file_name)}?width={width}"


class WikidataCoverClient:
    """Free-text → QID → P18 image lookup."""

    @staticmethod
    async def search_entity(query: str, *, locale: str = "en") -> str | None:
        """Resolve a free-text query to the best-matching Wikidata QID."""
        if not query.strip():
            return None
        try:
            client = get_http_client()
            resp = await client.get(
                _SEARCH_URL,
                params={
                    "action": "wbsearchentities",
                    "search": query.strip(),
                    "language": locale,
                    "uselang": locale,
                    "format": "json",
                    "limit": 1,
                    "type": "item",
                },
                headers=WIKIMEDIA_HEADERS,
                timeout=DEFAULT_TIMEOUT_S,
            )
        except Exception as exc:
            logger.warn(f"Wikidata search failed for '{query}': {exc}")
            return None
        if resp.status_code >= 400:
            return None
        try:
            data = resp.json()
        except ValueError:
            return None
        results = data.get("search", [])
        if not results:
            return None
        return results[0].get("id")

    @staticmethod
    async def fetch_entity(qid: str) -> dict[str, Any] | None:
        """Fetch the raw entity JSON for a QID."""
        url = f"{_ENTITY_BASE}/{qid}.json"
        try:
            client = get_http_client()
            resp = await client.get(url, headers=WIKIMEDIA_HEADERS, timeout=DEFAULT_TIMEOUT_S)
        except Exception as exc:
            logger.warn(f"Wikidata entity fetch failed for {qid}: {exc}")
            return None
        if resp.status_code >= 400:
            return None
        try:
            data = resp.json()
        except ValueError:
            return None
        return data.get("entities", {}).get(qid)

    @staticmethod
    def _extract_p18(entity: dict[str, Any]) -> str | None:
        """Extract the first ``P18`` (image) claim's Commons file name."""
        claims = entity.get("claims", {})
        p18 = claims.get("P18") or []
        for claim in p18:
            value = claim.get("mainsnak", {}).get("datavalue", {}).get("value")
            if isinstance(value, str) and value:
                return value
        return None

    @staticmethod
    def _extract_coords(entity: dict[str, Any]) -> tuple[float, float] | None:
        """Extract the first ``P625`` (coordinate location) claim."""
        claims = entity.get("claims", {})
        p625 = claims.get("P625") or []
        for claim in p625:
            value = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {})
            lat = value.get("latitude")
            lon = value.get("longitude")
            if lat is None or lon is None:
                continue
            try:
                return float(lat), float(lon)
            except (TypeError, ValueError):
                continue
        return None

    @staticmethod
    def _extract_label(entity: dict[str, Any], locale: str) -> str | None:
        labels = entity.get("labels", {})
        for code in (locale, "en"):
            block = labels.get(code)
            if block and block.get("value"):
                return block["value"]
        return None

    @classmethod
    async def fetch_candidates(
        cls, query: str, *, locale: str = "en"
    ) -> tuple[list[CoverCandidate], tuple[float, float] | None]:
        """Return ``(candidates, coords)`` resolved via Wikidata."""
        qid = await cls.search_entity(query, locale=locale)
        if not qid:
            return [], None
        entity = await cls.fetch_entity(qid)
        if not entity:
            return [], None
        coords = cls._extract_coords(entity)
        file_name = cls._extract_p18(entity)
        if not file_name:
            return [], coords
        label = cls._extract_label(entity, locale)
        attribution = f"Wikimedia Commons / Wikidata ({qid})"
        return (
            [
                CoverCandidate(
                    url=_commons_url(file_name),
                    source="wikidata",
                    title=label,
                    attribution=attribution,
                    extra={"qid": qid, "file": file_name},
                )
            ],
            coords,
        )


wikidata_cover_client = WikidataCoverClient()
