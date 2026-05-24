"""Wikimedia Commons geosearch — extra candidates around coordinates (SMP-330).

Given lat/lng, ``action=query&list=geosearch`` returns Commons files within
a radius. We then fetch ``imageinfo`` for the top N to get usable URLs and
metadata. This is the only provider that can offer *several* alternatives,
which is what feeds the "Change cover" bottom sheet — the user usually
ends up picking one of these because they're real photos of the actual
place (vs the Wikipedia lead image which is often a postcard view).
"""

from __future__ import annotations

from src.integrations.cover_image._http import DEFAULT_TIMEOUT_S, WIKIMEDIA_HEADERS
from src.integrations.cover_image.types import CoverCandidate
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_API_URL = "https://commons.wikimedia.org/w/api.php"


class CommonsGeoCoverClient:
    """Geo-anchored Commons photo discovery."""

    @staticmethod
    async def fetch_candidates(
        lat: float,
        lng: float,
        *,
        radius_m: int = 10_000,
        limit: int = 5,
    ) -> list[CoverCandidate]:
        """Return up to ``limit`` photo candidates around ``(lat, lng)``.

        Only landscape-ish files (width >= height, width >= 800) are
        kept. Sub-800px thumbnails make ugly hero covers on modern
        screens, and portrait-orientation Commons photos break the
        hero aspect ratio in the Flutter UI.
        """
        if not (-90 <= lat <= 90 and -180 <= lng <= 180):
            return []

        try:
            client = get_http_client()
            geo_resp = await client.get(
                _API_URL,
                params={
                    "action": "query",
                    "list": "geosearch",
                    "gscoord": f"{lat}|{lng}",
                    "gsradius": str(radius_m),
                    "gsnamespace": "6",  # File: namespace
                    "gslimit": str(max(limit * 4, 20)),
                    "format": "json",
                    "formatversion": "2",
                },
                headers=WIKIMEDIA_HEADERS,
                timeout=DEFAULT_TIMEOUT_S,
            )
        except Exception as exc:
            logger.warn(f"Commons geosearch failed at ({lat},{lng}): {exc}")
            return []

        if geo_resp.status_code >= 400:
            return []
        try:
            geo_data = geo_resp.json()
        except ValueError:
            return []

        results = geo_data.get("query", {}).get("geosearch", [])
        if not results:
            return []

        # Batch image info lookup — pipe-joined titles is the documented
        # multi-page form and keeps us to a single round trip.
        titles = [item["title"] for item in results if item.get("title")]
        if not titles:
            return []

        try:
            client = get_http_client()
            info_resp = await client.get(
                _API_URL,
                params={
                    "action": "query",
                    "prop": "imageinfo",
                    "titles": "|".join(titles),
                    "iiprop": "url|size|extmetadata",
                    "iiurlwidth": "1280",
                    "format": "json",
                    "formatversion": "2",
                },
                headers=WIKIMEDIA_HEADERS,
                timeout=DEFAULT_TIMEOUT_S,
            )
        except Exception as exc:
            logger.warn(f"Commons imageinfo failed: {exc}")
            return []

        if info_resp.status_code >= 400:
            return []
        try:
            info_data = info_resp.json()
        except ValueError:
            return []

        pages = info_data.get("query", {}).get("pages", [])
        candidates: list[CoverCandidate] = []
        for page in pages:
            infos = page.get("imageinfo") or []
            if not infos:
                continue
            info = infos[0]
            width = info.get("thumbwidth") or info.get("width")
            height = info.get("thumbheight") or info.get("height")
            if not width or not height:
                continue
            if width < 800 or width < height:
                continue
            url = info.get("thumburl") or info.get("url")
            if not url:
                continue
            meta = info.get("extmetadata", {})
            artist = (meta.get("Artist", {}) or {}).get("value", "")
            license_short = (meta.get("LicenseShortName", {}) or {}).get("value", "")
            file_title = page.get("title", "")
            attribution_parts = ["Wikimedia Commons"]
            if artist:
                attribution_parts.append(artist)
            if license_short:
                attribution_parts.append(license_short)
            candidate = CoverCandidate(
                url=url,
                source="commons_geo",
                title=file_title.replace("File:", "").replace("_", " "),
                attribution=" / ".join(attribution_parts),
                width=width,
                height=height,
                extra={"file": file_title},
            )
            candidates.append(candidate)
            if len(candidates) >= limit:
                break
        return candidates


commons_geo_cover_client = CommonsGeoCoverClient()
