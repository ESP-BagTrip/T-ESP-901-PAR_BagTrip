"""Single source of truth for resolving a city / IATA code.

Why this exists
---------------
Until SMP-324 the agent reached IATA codes by handing the user-typed city
name to a single offline backend (``airportsdata``). That dataset only
indexes city names in English, so a French user picking *"Singapour"*
(or *"Lisbonne"*, *"Pékin"*, *"Le Caire"*…) silently produced empty IATA
strings, which then cascaded into a broken flight search and an empty
"ALLER" card on the trip detail screen.

The resolver below replaces that single-shot lookup with a deterministic
cascade: each step is cheap to add, each one logs which path produced
the answer, and a Redis cache covers steady-state load. Callers just see
``ResolvedCity | None``.

Cascade
-------
1. **Pre-validated IATA** — if the input looks like a 3-letter IATA
   code, ``airportsdata.get_by_id`` resolves it directly (O(1)).
2. **Cache hit** — Redis key ``loc:{locale}:{slug(name)}``, TTL 7 days.
   Locations don't churn so a long TTL is fine and we avoid hammering
   Open-Meteo for the same recurring city.
3. **English exact match** — ``airportsdata.search_by_keyword`` resolves
   any English-language city name without a network round-trip.
4. **Multilingual geocoding** — Open-Meteo Geocoding API accepts the
   raw locale-language query (``Singapour`` with ``language=fr``) and
   returns coordinates plus the canonical English place name. We then
   re-feed that English name into ``airportsdata.search_by_keyword`` to
   pick the right IATA, and as a final guard fall back to
   ``search_nearest()`` on the returned coordinates so a niche city
   without a name match still resolves to its closest airport.

Each successful step writes the result back to Redis with the original
locale-keyed slug so subsequent calls short-circuit.
"""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass

from src.integrations.aviation_data import aviation_data_service
from src.integrations.open_meteo import GeocodedPlace, search_places
from src.integrations.redis_client import get_redis_client
from src.utils.logger import logger

_CACHE_PREFIX = "loc"
_CACHE_TTL_SECONDS = 7 * 24 * 60 * 60  # 7 days
_IATA_PATTERN = re.compile(r"^[A-Za-z]{3}$")


@dataclass(frozen=True, slots=True)
class ResolvedCity:
    """Immutable view of a resolved location.

    ``source`` identifies which cascade step produced the answer so the
    metrics layer (SMP-324 commit 9) can compute LLM-vs-Amadeus-vs-other
    coverage, and so a caller debugging a bad result can grep logs for
    the right step.
    """

    iata: str
    city: str
    country: str
    country_code: str
    latitude: float
    longitude: float
    source: str


def _slug(value: str) -> str:
    """Normalize a city name into a stable cache key fragment.

    ASCII-folds, lowercases, and collapses anything non-alphanumeric to
    underscores. Two equivalent inputs (``"Saint-Pétersbourg"`` and
    ``"saint petersbourg"``) collapse to the same slug, so the Redis
    cache de-duplicates trivial spelling variants for free.
    """
    lowered = (value or "").strip().lower()
    # Strip diacritics by hand — we deliberately avoid `unicodedata` here
    # because the small explicit table is faster than NFD + filter and
    # makes the test fixtures readable.
    folded = (
        lowered.replace("à", "a")
        .replace("â", "a")
        .replace("ä", "a")
        .replace("ã", "a")
        .replace("á", "a")
        .replace("ç", "c")
        .replace("é", "e")
        .replace("è", "e")
        .replace("ê", "e")
        .replace("ë", "e")
        .replace("í", "i")
        .replace("ï", "i")
        .replace("î", "i")
        .replace("ó", "o")
        .replace("ô", "o")
        .replace("ö", "o")
        .replace("õ", "o")
        .replace("ú", "u")
        .replace("ü", "u")
        .replace("û", "u")
        .replace("ñ", "n")
        .replace("ß", "ss")
    )
    return re.sub(r"[^a-z0-9]+", "_", folded).strip("_")


def _cache_key(query: str, locale: str) -> str:
    return f"{_CACHE_PREFIX}:{locale}:{_slug(query)}"


def _read_cache(query: str, locale: str) -> ResolvedCity | None:
    client = get_redis_client()
    if client is None:
        return None
    try:
        raw = client.get(_cache_key(query, locale))
    except Exception as exc:  # pragma: no cover - cache must never break the resolver
        logger.warn("location_resolver: cache read failed", {"error": str(exc)})
        return None
    if not raw:
        return None
    try:
        payload = json.loads(raw if isinstance(raw, str) else raw.decode("utf-8"))
    except (ValueError, AttributeError):
        return None
    try:
        return ResolvedCity(**payload)
    except TypeError:
        # Schema drift between cache and code → ignore and re-resolve.
        return None


def _write_cache(query: str, locale: str, resolved: ResolvedCity) -> None:
    client = get_redis_client()
    if client is None:
        return
    try:
        client.set(
            _cache_key(query, locale),
            json.dumps(asdict(resolved)),
            ex=_CACHE_TTL_SECONDS,
        )
    except Exception as exc:  # pragma: no cover
        logger.warn("location_resolver: cache write failed", {"error": str(exc)})


def _from_aviation_location(loc, source: str) -> ResolvedCity | None:
    """Convert the Pydantic Amadeus-shaped Location into a ResolvedCity."""
    iata = (loc.iataCode or getattr(loc.address, "cityCode", "") or "").upper()
    if not iata:
        return None
    return ResolvedCity(
        iata=iata,
        city=loc.address.cityName or "",
        country=loc.address.countryName or "",
        country_code=getattr(loc.address, "countryCode", "") or "",
        latitude=float(loc.geoCode.latitude),
        longitude=float(loc.geoCode.longitude),
        source=source,
    )


def _try_iata_passthrough(query: str) -> ResolvedCity | None:
    candidate = query.strip().upper()
    if not _IATA_PATTERN.match(candidate):
        return None
    loc = aviation_data_service.get_by_id(candidate)
    if loc is None:
        return None
    return _from_aviation_location(loc, source="airportsdata.iata")


def _try_airportsdata_keyword(query: str) -> ResolvedCity | None:
    locations = aviation_data_service.search_by_keyword(
        query.strip(), sub_type="CITY,AIRPORT", limit=1
    )
    if not locations:
        return None
    return _from_aviation_location(locations[0], source="airportsdata.keyword")


async def _try_open_meteo_then_airportsdata(query: str, locale: str) -> ResolvedCity | None:
    places = await search_places(query, language=locale, count=3)
    if not places:
        return None
    place = places[0]

    # Re-attempt airportsdata with the canonical English name returned by
    # Open-Meteo — covers the FR→EN gap (Singapour → Singapore).
    canonical = _try_airportsdata_keyword(place.name)
    if canonical:
        return ResolvedCity(
            iata=canonical.iata,
            city=place.name,
            country=place.country or canonical.country,
            country_code=place.country_code or canonical.country_code,
            latitude=place.latitude,
            longitude=place.longitude,
            source="open_meteo+airportsdata",
        )

    # Last-resort: nearest airport to the geocoded coordinates. Useful
    # for niche cities whose English name still misses airportsdata
    # (small islands, alternative spellings).
    return _try_nearest_airport(place)


def _try_nearest_airport(place: GeocodedPlace) -> ResolvedCity | None:
    nearest = aviation_data_service.search_nearest(
        latitude=place.latitude, longitude=place.longitude, limit=1
    )
    if not nearest:
        return None
    nearest_resolved = _from_aviation_location(nearest[0], source="open_meteo+nearest")
    if nearest_resolved is None:
        return None
    return ResolvedCity(
        iata=nearest_resolved.iata,
        city=place.name,
        country=place.country or nearest_resolved.country,
        country_code=place.country_code or nearest_resolved.country_code,
        latitude=place.latitude,
        longitude=place.longitude,
        source="open_meteo+nearest",
    )


async def resolve_city(name_or_iata: str, *, locale: str = "en") -> ResolvedCity | None:
    """Resolve a free-form city name (or IATA) to a structured location.

    Args:
        name_or_iata: User input — IATA code, English city name,
            localized city name. Whitespace-trimmed; empty input
            returns ``None``.
        locale: 2-letter language code controlling which language to
            ask Open-Meteo with. The resolved ``city`` field will keep
            the localized name when the cascade ends on Open-Meteo,
            otherwise it stays in English.

    Returns:
        A ``ResolvedCity`` when at least one cascade step succeeds,
        otherwise ``None``. Callers should treat ``None`` as
        "user must re-enter or pick from a different list" — the
        resolver never raises.
    """
    if not name_or_iata or not name_or_iata.strip():
        return None

    query = name_or_iata.strip()
    locale_code = (locale or "en").split("-", 1)[0].lower()[:2] or "en"

    # 1. Direct IATA passthrough.
    iata_hit = _try_iata_passthrough(query)
    if iata_hit:
        logger.info(
            "location_resolver: resolved via IATA passthrough",
            {"query": query, "iata": iata_hit.iata},
        )
        _write_cache(query, locale_code, iata_hit)
        return iata_hit

    # 2. Cache.
    cached = _read_cache(query, locale_code)
    if cached:
        logger.info(
            "location_resolver: resolved via cache",
            {"query": query, "iata": cached.iata, "source": cached.source},
        )
        return cached

    # 3. English keyword lookup (free, instant).
    en_hit = _try_airportsdata_keyword(query)
    if en_hit:
        logger.info(
            "location_resolver: resolved via airportsdata keyword",
            {"query": query, "iata": en_hit.iata},
        )
        _write_cache(query, locale_code, en_hit)
        return en_hit

    # 4. Multilingual geocoding fallback.
    geo_hit = await _try_open_meteo_then_airportsdata(query, locale_code)
    if geo_hit:
        logger.info(
            "location_resolver: resolved via geocoding",
            {"query": query, "locale": locale_code, "iata": geo_hit.iata, "source": geo_hit.source},
        )
        _write_cache(query, locale_code, geo_hit)
        return geo_hit

    logger.warn(
        "location_resolver: all cascade steps exhausted",
        {"query": query, "locale": locale_code},
    )
    return None
