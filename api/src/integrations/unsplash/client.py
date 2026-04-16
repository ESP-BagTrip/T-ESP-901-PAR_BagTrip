"""Client Unsplash pour les images de couverture automatiques."""

import time

from src.config.env import settings
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_CACHE: dict[str, dict] = {}
_CACHE_TTL = 3600  # 1 hour

# Continent fallback URLs (royalty-free landscape defaults)
_CONTINENT_FALLBACKS: dict[str, str] = {
    "europe": "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1080",
    "asia": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1080",
    "north_america": "https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=1080",
    "south_america": "https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=1080",
    "africa": "https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=1080",
    "oceania": "https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?w=1080",
    "default": "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=1080",
}

# Keywords to detect continent from destination name
_CONTINENT_KEYWORDS: dict[str, list[str]] = {
    "europe": [
        "paris",
        "london",
        "rome",
        "berlin",
        "madrid",
        "barcelona",
        "amsterdam",
        "vienna",
        "prague",
        "lisbon",
        "athens",
        "zurich",
        "brussels",
        "dublin",
        "stockholm",
        "oslo",
        "copenhagen",
        "helsinki",
        "warsaw",
        "budapest",
        "france",
        "spain",
        "italy",
        "germany",
        "portugal",
        "greece",
        "uk",
        "england",
        "switzerland",
        "netherlands",
        "belgium",
        "austria",
        "sweden",
        "norway",
        "denmark",
        "finland",
        "poland",
        "hungary",
        "czech",
    ],
    "asia": [
        "tokyo",
        "beijing",
        "shanghai",
        "bangkok",
        "singapore",
        "seoul",
        "mumbai",
        "delhi",
        "dubai",
        "istanbul",
        "hong kong",
        "taipei",
        "kuala lumpur",
        "hanoi",
        "bali",
        "jakarta",
        "japan",
        "china",
        "thailand",
        "india",
        "vietnam",
        "indonesia",
        "malaysia",
        "korea",
        "taiwan",
        "philippines",
        "uae",
        "turkey",
    ],
    "north_america": [
        "new york",
        "los angeles",
        "chicago",
        "miami",
        "san francisco",
        "toronto",
        "vancouver",
        "mexico city",
        "cancun",
        "montreal",
        "usa",
        "canada",
        "mexico",
        "united states",
    ],
    "south_america": [
        "rio",
        "buenos aires",
        "lima",
        "bogota",
        "santiago",
        "sao paulo",
        "brazil",
        "argentina",
        "colombia",
        "peru",
        "chile",
    ],
    "africa": [
        "cairo",
        "cape town",
        "marrakech",
        "nairobi",
        "lagos",
        "casablanca",
        "egypt",
        "morocco",
        "south africa",
        "kenya",
        "nigeria",
        "tunisia",
    ],
    "oceania": [
        "sydney",
        "melbourne",
        "auckland",
        "fiji",
        "bora bora",
        "australia",
        "new zealand",
    ],
}


def _detect_continent(destination_name: str) -> str:
    """Detect continent from destination name keywords."""
    lower = destination_name.lower()
    for continent, keywords in _CONTINENT_KEYWORDS.items():
        if any(kw in lower for kw in keywords):
            return continent
    return "default"


class UnsplashClient:
    """Client pour l'API Unsplash."""

    BASE_URL = "https://api.unsplash.com"

    @staticmethod
    async def fetch_cover_image(destination_name: str) -> str | None:
        """Fetch a landscape cover image for a destination.

        Returns the image URL or None if unavailable.
        """
        if not settings.UNSPLASH_ACCESS_KEY:
            return None

        cache_key = destination_name.lower().strip()

        # Check cache
        cached = _CACHE.get(cache_key)
        if cached and (time.time() - cached["fetched_at"]) < _CACHE_TTL:
            return cached["url"]

        try:
            client = get_http_client()
            resp = await client.get(
                f"{UnsplashClient.BASE_URL}/search/photos",
                params={
                    "query": destination_name,
                    "orientation": "landscape",
                    "per_page": 1,
                },
                headers={
                    "Authorization": f"Client-ID {settings.UNSPLASH_ACCESS_KEY}",
                },
                timeout=10.0,
            )
            resp.raise_for_status()

            data = resp.json()
            results = data.get("results", [])
            if not results:
                return None

            url = results[0]["urls"]["regular"]
            _CACHE[cache_key] = {"url": url, "fetched_at": time.time()}
            return url
        except Exception as e:
            logger.warn(f"Unsplash fetch failed for '{destination_name}': {e}")
            return None

    @staticmethod
    def get_fallback_url(destination_name: str) -> str:
        """Get a static fallback URL based on detected continent."""
        continent = _detect_continent(destination_name)
        return _CONTINENT_FALLBACKS[continent]


unsplash_client = UnsplashClient()
