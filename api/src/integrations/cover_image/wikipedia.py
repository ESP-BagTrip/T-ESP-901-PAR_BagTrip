"""Wikipedia REST summary client — primary cover image source (SMP-330).

The ``/api/rest_v1/page/summary/{title}`` endpoint returns the lead image
of a Wikipedia article along with a short extract and coordinates. We use
it because it:

- requires no API key and has no per-IP quota for normal traffic;
- mirrors content in dozens of languages, so a French user gets a
  destination's French article (with a French-curated lead image) when
  available;
- exposes the article's ``coordinates`` block, which lets the orchestrator
  feed the Commons geosearch fallback even when this call succeeds.

The summary type can be ``"standard"`` (a real article) or ``"disambiguation"``
(Wikipedia is asking *which* Tokyo). Only the standard case yields a usable
image; disambiguation pages embed a generic illustration we want to skip.
"""

from __future__ import annotations

from typing import Any
from urllib.parse import quote

from src.integrations.cover_image._http import DEFAULT_TIMEOUT_S, WIKIMEDIA_HEADERS
from src.integrations.cover_image.types import CoverCandidate
from src.integrations.http_client import get_http_client
from src.utils.logger import logger


def _base_url(locale: str) -> str:
    # ``commons.wikipedia.org`` would 404 — Wikipedia's REST API is per-wiki.
    # Only language code is variable; ``simple`` (Simple English) is the
    # documented fallback but not useful for destinations.
    return f"https://{locale}.wikipedia.org/api/rest_v1/page/summary"


class WikipediaCoverClient:
    """REST summary lookup."""

    @staticmethod
    async def fetch_summary(title: str, *, locale: str = "en") -> dict[str, Any] | None:
        """Fetch a summary object or ``None`` on miss / disambiguation / error."""
        if not title.strip():
            return None
        encoded = quote(title.strip().replace(" ", "_"), safe="")
        url = f"{_base_url(locale)}/{encoded}"
        try:
            client = get_http_client()
            resp = await client.get(url, headers=WIKIMEDIA_HEADERS, timeout=DEFAULT_TIMEOUT_S)
        except Exception as exc:
            logger.warn(f"Wikipedia summary fetch failed for '{title}' ({locale}): {exc}")
            return None

        if resp.status_code == 404:
            return None
        if resp.status_code >= 400:
            logger.warn(f"Wikipedia summary returned {resp.status_code} for '{title}' ({locale})")
            return None

        try:
            data = resp.json()
        except ValueError:
            return None

        # Disambiguation pages carry a stock icon, not a destination photo.
        if data.get("type") == "disambiguation":
            return None
        return data

    @staticmethod
    def candidate_from_summary(summary: dict[str, Any]) -> CoverCandidate | None:
        """Promote a summary payload to a CoverCandidate, or None if no image."""
        image_block = summary.get("originalimage") or summary.get("thumbnail")
        if not image_block or not image_block.get("source"):
            return None
        title = summary.get("displaytitle") or summary.get("title")
        page_url = summary.get("content_urls", {}).get("desktop", {}).get("page")
        attribution = f"Wikipedia — {title}" if title else "Wikipedia"
        return CoverCandidate(
            url=image_block["source"],
            source="wikipedia",
            title=title,
            attribution=attribution,
            width=image_block.get("width"),
            height=image_block.get("height"),
            extra={"page_url": page_url} if page_url else {},
        )

    @staticmethod
    def extract_coords(summary: dict[str, Any]) -> tuple[float, float] | None:
        """Return ``(lat, lng)`` from the summary block when present."""
        coords = summary.get("coordinates")
        if not coords:
            return None
        lat = coords.get("lat")
        lon = coords.get("lon")
        if lat is None or lon is None:
            return None
        try:
            return float(lat), float(lon)
        except (TypeError, ValueError):
            return None

    @classmethod
    async def fetch_candidates(
        cls, query: str, *, locale: str = "en"
    ) -> tuple[list[CoverCandidate], tuple[float, float] | None]:
        """Return ``(candidates, coords)`` for a destination query.

        ``coords`` is forwarded to downstream providers (Commons geosearch,
        OSM map render) so they can target the same place even when this
        provider had nothing visual to offer.
        """
        summary = await cls.fetch_summary(query, locale=locale)
        if summary is None and locale != "en":
            # Many destinations only have a stub on minority-language wikis;
            # fall back to the English article (which is what the previous
            # Unsplash flow effectively used).
            summary = await cls.fetch_summary(query, locale="en")
        if summary is None:
            return [], None
        coords = cls.extract_coords(summary)
        candidate = cls.candidate_from_summary(summary)
        return ([candidate] if candidate else [], coords)


wikipedia_cover_client = WikipediaCoverClient()
