"""Multilingual city → :class:`Location` resolver.

The :mod:`airportsdata` catalogue indexes airports by their English /
local name (``Firenze``, ``München``, ``Singapore``). When the wizard
sends a French / Spanish / Chinese / … city name we fall through that
index and either pick a wrong-country namesake (Florence, SC instead of
Florence, IT — audit Q3) or return nothing at all (Singapour stalls
with no IATA — audit C3).

This resolver implements the cascade described in the SMP-325 RFC:

1. **Cache** — Redis-backed idempotency cache (5 minute TTL). Cheap.
2. **Offline keyword match** (``airportsdata``) — fast, no network call,
   handles English-name and IATA-pass-through queries.
3. **Open-Meteo geocoding** — free, no API key, multilingual (the
   ``language`` query param accepts ISO-639 codes). Returns coordinates
   plus a country code.
4. **Nearest airport by haversine** (``search_nearest``) — picks the
   closest scheduled airport to the geocoded coords.

The resolver always returns a :class:`Location` whose ``iataCode`` is
populated, or ``None`` if every step misses. Callers MUST handle the
``None`` case explicitly — silent fallbacks are what the audit flagged
as the worst quality issue (audit C5/C6).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from src.config.env import settings
from src.integrations.aviation_data.service import AviationDataService, Location
from src.integrations.http_client import get_http_client
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


@dataclass
class ResolvedLocation:
    """Trimmed-down resolver output — what call sites actually need.

    Why not return the raw :class:`Location` directly? Because the
    cascade can produce a hit that has different ``city`` / ``country``
    fields from the user input (e.g. user typed "Singapour" in FR; we
    resolved to airport SIN whose ``cityName`` is "Singapore"). Callers
    almost always want the original user-facing name *and* the resolved
    technical attributes. Bundling both here keeps the contract honest.
    """

    iata: str
    city: str  # canonical city name (English from airportsdata)
    country: str  # canonical country name
    country_code: str  # ISO 3166-1 alpha-2
    lat: float
    lon: float
    source: str  # "cache" | "airportsdata" | "open-meteo+nearest"
    raw_query: str  # what the user originally typed
    raw_locale: str  # locale used during resolution


class LocationResolver:
    """Stateless cascade resolver. Use :meth:`resolve` per query."""

    _aviation = AviationDataService()
    _CACHE_TOOL = "location_resolver"

    @classmethod
    async def resolve(
        cls,
        name: str,
        *,
        country_hint: str = "",
        locale: str = "en",
    ) -> ResolvedLocation | None:
        """Resolve ``name`` (free-form city, IATA code, or "City, Country").

        ``country_hint`` is consumed when ``name`` could match airports
        in multiple countries (Manchester GB vs US). It accepts both the
        country name and the ISO 3166-1 code (case insensitive).

        ``locale`` is forwarded to Open-Meteo geocoding when the local
        catalogue misses; pass the wizard locale (``"fr"``, ``"en"``,
        …) so non-English queries resolve correctly.
        """
        cleaned = (name or "").strip()
        if not cleaned:
            return None

        cache_key = {"name": cleaned, "country": country_hint, "locale": locale}
        cached = idempotency_cache.get(cls._CACHE_TOOL, cache_key)
        if cached is not None:
            return _from_cache(cached)

        # 1. IATA pass-through.
        if len(cleaned) == 3 and cleaned.isalpha():
            loc = cls._aviation.get_by_id(cleaned.upper())
            if loc is not None:
                resolved = _from_location(loc, source="airportsdata", raw=name, locale=locale)
                cls._cache(cache_key, resolved)
                return resolved

        # 2. Offline keyword + optional country disambiguation.
        # ``airportsdata`` only knows English-language names. When the user
        # typed in another locale ("Singapour", "Pékin", "Lisbonne"), an
        # English keyword match is almost always a wrong-country namesake
        # (Florence, SC instead of Firenze) — we skip step 2 and let the
        # multilingual geocoder in step 3 do the work.
        is_english_query = (locale or "en").lower().startswith("en")
        if is_english_query:
            offline = cls._aviation.search_by_keyword(cleaned, sub_type="CITY,AIRPORT", limit=10)
            offline_match = _pick_with_country(offline, country_hint)
            if offline_match is not None:
                resolved = _from_location(
                    offline_match, source="airportsdata", raw=name, locale=locale
                )
                cls._cache(cache_key, resolved)
                return resolved

        # 3. Open-Meteo geocoding (multilingual).
        geo = await _geocode_open_meteo(cleaned, locale=locale)
        if geo is None:
            logger.warn(
                "LocationResolver: every step missed",
                {"name": cleaned, "country": country_hint, "locale": locale},
            )
            return None

        # 4. Nearest scheduled airport from the geocoded coords.
        nearest = cls._aviation.search_nearest(latitude=geo["lat"], longitude=geo["lon"], limit=10)
        if not nearest:
            return None

        target_cc = geo.get("country_code", "").upper()
        chosen = _pick_best_nearby_airport(nearest, target_cc, geo["lat"], geo["lon"])
        resolved = ResolvedLocation(
            iata=chosen.iataCode or (chosen.address.cityCode if chosen.address else ""),
            city=geo.get("name") or (chosen.address.cityName if chosen.address else cleaned),
            country=geo.get("country") or (chosen.address.countryName if chosen.address else ""),
            country_code=target_cc or (chosen.address.countryCode if chosen.address else ""),
            lat=geo["lat"],
            lon=geo["lon"],
            source="open-meteo+nearest",
            raw_query=name,
            raw_locale=locale,
        )
        if not resolved.iata:
            return None
        cls._cache(cache_key, resolved)
        return resolved

    # ── Cache helpers ─────────────────────────────────────────────────

    @classmethod
    def _cache(cls, key: dict[str, Any], resolved: ResolvedLocation) -> None:
        idempotency_cache.set(cls._CACHE_TOOL, key, _to_cache(resolved))


# ── Module-level helpers (kept module-private; no public API drift) ───


_MILITARY_KEYWORDS = (
    "air base",
    "air force",
    "military",
    "naval air",
    "air station",
    "aerodrome",
)


def _is_military(loc: Location) -> bool:
    name = (loc.name or "").lower()
    return any(kw in name for kw in _MILITARY_KEYWORDS)


#: Maximum distance (km) within which an "International" tag still
#: implies the user's intended airport. Beyond that, the closer civilian
#: airport in the same country wins even if its name doesn't tag as
#: international (Lisbon Portela LIS for Lisbon, Florence Peretola FLR
#: for Florence — both well-served commercial hubs without that tag).
_INTL_CITY_RADIUS_KM = 40.0


def _pick_best_nearby_airport(
    candidates: list[Location],
    target_cc: str,
    geo_lat: float,
    geo_lon: float,
) -> Location:
    """Pick the most realistic commercial airport for a reverse-geocoded city.

    ``search_nearest`` orders by haversine distance only, which surfaces
    military / private airfields (Paya Lebar QPG, Tengah TGA…) before
    the international airport that actually serves scheduled traffic.

    Heuristic (best-first):
      1. Drop military / training bases — never recommend ``QPG`` for
         Singapore.
      2. Among the remaining airports, restrict to the geocoded country
         and prefer those with a populated ``cityName``.
      3. If a civilian airport whose name contains "International" sits
         within :data:`_INTL_CITY_RADIUS_KM` of the geocoded coords,
         pick it (this fixes Singapore: SIN beats Seletar XSP).
      4. Otherwise pick the closest civilian airport in the country
         (this fixes Lisbon: LIS beats Beja BYJ; Florence: FLR beats
         Pisa PSA — both 80–130 km away with the "International" tag).
    """
    from src.integrations.aviation_data.service import _haversine

    civilian = [c for c in candidates if not _is_military(c)]
    if not civilian:
        # All near-by entries are military — fall back to the raw nearest
        # so we never return ``None`` from this stage.
        return candidates[0]

    same_cc_with_city = [
        c
        for c in civilian
        if c.address and c.address.countryCode == target_cc and c.address.cityName
    ]
    pool = same_cc_with_city or civilian

    nearby_intl = [
        c
        for c in pool
        if "international" in (c.name or "").lower()
        and _haversine(geo_lat, geo_lon, c.geoCode.latitude, c.geoCode.longitude)
        <= _INTL_CITY_RADIUS_KM
    ]
    if nearby_intl:
        return nearby_intl[0]
    return pool[0]


def _pick_with_country(candidates: list[Location], country_hint: str) -> Location | None:
    if not candidates:
        return None
    if not country_hint:
        return candidates[0]
    ch_lower = country_hint.strip().lower()
    for loc in candidates:
        addr = loc.address
        if addr is None:
            continue
        if (addr.countryName and addr.countryName.lower() == ch_lower) or (
            addr.countryCode and addr.countryCode.lower() == ch_lower
        ):
            return loc
    return candidates[0]


async def _geocode_open_meteo(name: str, *, locale: str) -> dict[str, Any] | None:
    """Hit Open-Meteo's geocoding API and return the top hit (or None on miss).

    The endpoint is free and shaped exactly for our cascade — we ask for
    the user's locale so "Singapour" resolves directly. We fall back to
    English on a miss so an unknown locale (``"es"``, ``"de"``) still
    has a chance.
    """
    base = settings.OPEN_METEO_GEOCODING_BASE_URL
    url = f"{base}/v1/search"
    locales_to_try = [locale or "en"]
    if "en" not in locales_to_try:
        locales_to_try.append("en")
    client = get_http_client()
    for lang in locales_to_try:
        try:
            response = await client.get(
                url,
                params={"name": name, "count": 5, "language": lang, "format": "json"},
                timeout=8.0,
            )
        except Exception as exc:
            logger.warn(
                "LocationResolver: Open-Meteo geocoding network error",
                {"name": name, "locale": lang, "error": str(exc)},
            )
            return None
        if response.status_code != 200:
            logger.warn(
                "LocationResolver: Open-Meteo geocoding non-200",
                {"name": name, "locale": lang, "status": response.status_code},
            )
            continue
        data = response.json()
        results = data.get("results") or []
        # Prefer political capitals / admin divisions (PPLC / PPLA) over
        # tiny populated places (PPL) when both match — bigger places
        # have airports we can map to.
        results.sort(
            key=lambda r: (
                0 if r.get("feature_code") in ("PPLC", "PPLA", "PPLA2") else 1,
                -(r.get("population") or 0),
            )
        )
        if not results:
            continue
        best = results[0]
        return {
            "name": best.get("name"),
            "lat": best.get("latitude"),
            "lon": best.get("longitude"),
            "country": best.get("country"),
            "country_code": (best.get("country_code") or "").upper(),
        }
    return None


def _from_location(loc: Location, *, source: str, raw: str, locale: str) -> ResolvedLocation:
    addr = loc.address
    return ResolvedLocation(
        iata=loc.iataCode or (addr.cityCode if addr else ""),
        city=addr.cityName if addr else raw,
        country=addr.countryName if addr else "",
        country_code=addr.countryCode if addr else "",
        lat=loc.geoCode.latitude,
        lon=loc.geoCode.longitude,
        source=source,
        raw_query=raw,
        raw_locale=locale,
    )


def _to_cache(resolved: ResolvedLocation) -> dict[str, Any]:
    return resolved.__dict__.copy()


def _from_cache(payload: dict[str, Any]) -> ResolvedLocation:
    return ResolvedLocation(
        iata=payload["iata"],
        city=payload["city"],
        country=payload["country"],
        country_code=payload["country_code"],
        lat=payload["lat"],
        lon=payload["lon"],
        source="cache",
        raw_query=payload["raw_query"],
        raw_locale=payload["raw_locale"],
    )


__all__ = ["LocationResolver", "ResolvedLocation"]
