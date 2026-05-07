"""Amadeus-first destination inspiration for the wizard's step 3.

Why this exists
---------------
Until SMP-324 commit 5 the ``destinations_only`` mode dispatched a
single LLM call that *invented* 3-4 destinations from scratch. The LLM
also invented the IATA, the weather, the activity titles, sometimes
the country. This produced bugs like the Singapour cascade
(SMP-324 commit 1) and verbose, hallucinated activity titles
(SMP-323 prompt tightening).

The flow below pivots the model:

    1. Resolve the user's origin city to an IATA via the unified
       LocationResolver (handles localized inputs through Open-Meteo).
    2. Ask Amadeus' Flight Inspiration Search for real destinations
       reachable from that origin within the user's budget. Each
       candidate already carries the IATA, flight price (real, in
       EUR) and travel dates.
    3. Enrich each candidate (parallel) with:
         - real coordinates from the offline aviation dataset,
         - real Points of Interest from Amadeus localized via ``lang``,
         - real weather from Open-Meteo over the trip dates.
    4. Hand the enriched list to the LLM with a strict ``rank_destinations``
       prompt: pick 3-4, write a one-sentence match_reason, summarize
       weather in <= 35 chars, pick 3-5 short POIs as activity chips.
       The LLM does not produce any factual field.
    5. Project the result back into the same dict shape the front-end
       used to consume so no Flutter change is required for this commit.

When any prerequisite is missing (no origin city, Amadeus down,
budget too low to return candidates, …), the service falls back to
the previous "LLM-only" path so the wizard keeps producing something
rather than 500ing.
"""

from __future__ import annotations

import asyncio
import json
from typing import Any

from src.agent.prompts import render
from src.integrations.amadeus.types import (
    FlightDestination,
    FlightInspirationSearchQuery,
    PoiSearchQuery,
)
from src.integrations.aviation_data import aviation_data_service
from src.services.amadeus_service import AmadeusService
from src.services.location_resolver import resolve_city
from src.utils.logger import logger

# Open-ended budget when the wizard didn't ask for one. Amadeus accepts
# absent ``maxPrice`` so we just skip the parameter in that case — the
# constant is here to keep the call-site readable.
_MAX_CANDIDATES_FROM_AMADEUS = 12
_MAX_CANDIDATES_TO_RANK = 8
_POI_RADIUS_KM = 5
_TOP_POIS_PER_CANDIDATE = 6

_LANGUAGE_LABEL: dict[str, str] = {
    "en": "English",
    "fr": "français",
}


async def inspire_then_rank(state: Any) -> list[dict] | None:
    """Run the Amadeus-first inspiration pipeline.

    Returns a list of front-end-shaped destination dicts on success,
    or ``None`` when any prerequisite is missing so the caller can
    fall back to the legacy LLM-only path.
    """
    locale = (state.get("locale") or "en").split("-", 1)[0].lower()[:2] or "en"
    origin_city = state.get("origin_city") or ""
    if not origin_city:
        logger.info("inspire_then_rank: no origin_city in state, skipping")
        return None

    origin = await resolve_city(origin_city, locale=locale)
    if origin is None:
        logger.info(
            "inspire_then_rank: could not resolve origin",
            {"origin_city": origin_city, "locale": locale},
        )
        return None

    # Pull real candidates from Amadeus.
    inspiration_query = FlightInspirationSearchQuery(
        origin=origin.iata,
        departureDate=state.get("departure_date") or None,
        duration=state.get("duration_days") or None,
        maxPrice=_max_price_from_state(state),
        viewBy="DESTINATION",
    )
    try:
        inspiration = await AmadeusService.search_flight_destinations(inspiration_query)
    except Exception as exc:
        logger.warn(
            "inspire_then_rank: Amadeus inspiration failed, falling back",
            {"error": str(exc), "origin": origin.iata},
        )
        return None

    raw_candidates = list(inspiration.data or [])[:_MAX_CANDIDATES_FROM_AMADEUS]
    if not raw_candidates:
        logger.info(
            "inspire_then_rank: Amadeus returned no candidates",
            {"origin": origin.iata},
        )
        return None

    # Enrich the top N in parallel — each branch tolerates partial failures.
    enriched = await asyncio.gather(
        *[_enrich_candidate(c, locale=locale) for c in raw_candidates[:_MAX_CANDIDATES_TO_RANK]],
        return_exceptions=False,
    )
    enriched = [e for e in enriched if e is not None]
    if not enriched:
        logger.info("inspire_then_rank: enrichment dropped every candidate")
        return None

    # Ask the LLM to pick + describe.
    ranked = await _rank_with_llm(enriched, state, locale)
    if not ranked:
        return None

    # Re-shape into the contract the wizard already consumes.
    return _project_for_frontend(ranked, enriched)


def _max_price_from_state(state: Any) -> int | None:
    """Translate the wizard's budget intent into Amadeus' maxPrice (EUR)."""
    target = state.get("target_budget")
    if target:
        try:
            value = int(float(target))
            if value > 0:
                return value
        except (TypeError, ValueError):
            pass

    # Fallback: rough budget preset bands. Tightened intentionally — Amadeus
    # filters this on round-trip flight price only, so the band has to leave
    # headroom for hotel + activities downstream.
    preset = (state.get("budget_preset") or "").lower()
    return {
        "low": 500,
        "mid": 1500,
        "premium": 4000,
    }.get(preset)


async def _enrich_candidate(candidate: FlightDestination, *, locale: str) -> dict | None:
    """Resolve coords + POIs + weather for a single Amadeus candidate."""
    iata = candidate.destination
    aviation = aviation_data_service.get_by_id(iata)
    if aviation is None:
        # The candidate's IATA is not in our offline dataset — without
        # coords we can't pull POIs / weather, so the LLM would have
        # nothing real to write about. Drop it.
        logger.warn(
            "inspire_then_rank: aviation lookup miss",
            {"iata": iata},
        )
        return None
    lat = float(aviation.geoCode.latitude)
    lon = float(aviation.geoCode.longitude)

    pois_task = _fetch_pois_safely(lat, lon, locale)
    weather_task = _fetch_weather_safely(
        lat,
        lon,
        candidate.departureDate,
        candidate.returnDate or candidate.departureDate,
    )
    pois, weather = await asyncio.gather(pois_task, weather_task)

    try:
        flight_price_eur = float(candidate.price.total)
    except (TypeError, ValueError):
        flight_price_eur = 0.0

    return {
        "iata": iata,
        "city": aviation.address.cityName or iata,
        "country": aviation.address.countryName or "",
        "country_code": aviation.address.countryCode or "",
        "lat": lat,
        "lon": lon,
        "departure_date": candidate.departureDate,
        "return_date": candidate.returnDate,
        "flight_price_eur": round(flight_price_eur, 2),
        "weather": weather,
        "top_pois": pois,
    }


async def _fetch_pois_safely(lat: float, lon: float, locale: str) -> list[dict]:
    """Pull POIs without blowing up the pipeline on Amadeus quota errors."""
    try:
        results = await AmadeusService.search_pois(
            PoiSearchQuery(
                latitude=lat,
                longitude=lon,
                radius=_POI_RADIUS_KM,
                lang=locale,
                page_limit=_TOP_POIS_PER_CANDIDATE,
            )
        )
    except Exception as exc:
        logger.warn("inspire_then_rank: POI fetch failed", {"error": str(exc)})
        return []
    return [{"name": p.name, "category": p.category, "tags": p.tags} for p in results]


async def _fetch_weather_safely(lat: float, lon: float, start: str | None, end: str | None) -> dict:
    """Pull weather; on any failure return a minimal dict."""
    if not start or not end:
        return {}
    try:
        from src.agent.tools.weather import get_weather

        return await get_weather(latitude=lat, longitude=lon, start_date=start, end_date=end)
    except Exception as exc:
        logger.warn("inspire_then_rank: weather fetch failed", {"error": str(exc)})
        return {}


async def _rank_with_llm(enriched: list[dict], state: Any, locale: str) -> list[dict] | None:
    """Hand the enriched list to the LLM with a strict ranking prompt."""
    from src.services.llm_service import LLMService

    profile_block = _build_profile_block(state)
    candidates_block = _build_candidates_block(enriched)
    language_label = _LANGUAGE_LABEL.get(locale, _LANGUAGE_LABEL["en"])

    system_prompt = render(
        "rank_destinations",
        locale=locale,
        profile_block=profile_block,
        candidates_block=candidates_block,
        language_label=language_label,
    )

    try:
        result = await LLMService().acall_llm(system_prompt, "")
    except Exception as exc:
        logger.warn(
            "inspire_then_rank: LLM ranking failed, falling back",
            {"error": str(exc)},
        )
        return None

    ranked = result.get("destinations") or []
    if not isinstance(ranked, list) or not ranked:
        return None
    return ranked


def _build_profile_block(state: Any) -> str:
    """Compact, label-translated bullet list for the LLM prompt."""
    rows: list[str] = []
    if state.get("travel_types"):
        rows.append(f"- preferences: {state['travel_types']}")
    if state.get("budget_preset"):
        rows.append(f"- budget tier: {state['budget_preset']}")
    if state.get("target_budget"):
        rows.append(f"- numeric target budget (EUR): {state['target_budget']}")
    if state.get("duration_days"):
        rows.append(f"- duration (days): {state['duration_days']}")
    if state.get("companions"):
        rows.append(f"- companions: {state['companions']}")
    if state.get("nb_travelers"):
        rows.append(f"- travelers: {state['nb_travelers']}")
    if state.get("season"):
        rows.append(f"- season: {state['season']}")
    if state.get("constraints"):
        rows.append(f"- constraints: {state['constraints']}")
    return "\n".join(rows) if rows else "- (no profile details)"


def _build_candidates_block(enriched: list[dict]) -> str:
    """Serialize enriched candidates as compact JSON for the LLM."""
    compact = [
        {
            "iata": e["iata"],
            "city": e["city"],
            "country": e["country"],
            "flight_price_eur": e["flight_price_eur"],
            "weather": _compact_weather(e.get("weather") or {}),
            "top_pois": [p["name"] for p in e.get("top_pois") or [] if p.get("name")],
        }
        for e in enriched
    ]
    return json.dumps(compact, ensure_ascii=False, indent=2)


def _compact_weather(weather: dict) -> dict:
    """Trim the weather payload to the fields the LLM should reference."""
    keys = ("avg_temp_c", "min_temp_c", "max_temp_c", "rain_probability")
    return {k: weather[k] for k in keys if k in weather}


def _project_for_frontend(ranked: list[dict], enriched: list[dict]) -> list[dict]:
    """Merge LLM-written copy with Amadeus-resolved facts.

    The LLM picks by IATA — anything it returns whose IATA is not in
    the enriched list is silently dropped (defensive: would otherwise
    leak a hallucinated destination back to the wizard).
    """
    by_iata = {e["iata"]: e for e in enriched}
    output: list[dict] = []

    for ranked_entry in ranked:
        iata = (ranked_entry.get("iata") or "").upper()
        base = by_iata.get(iata)
        if base is None:
            logger.warn(
                "inspire_then_rank: LLM returned unknown IATA, dropping",
                {"iata": iata},
            )
            continue
        output.append(
            {
                "iata": iata,
                "city": base["city"],
                "country": base["country"],
                "match_reason": ranked_entry.get("match_reason") or "",
                "weather_summary": ranked_entry.get("weather_summary") or "",
                "topActivities": ranked_entry.get("topActivities") or [],
                # Carried through for downstream consumers (budget chip,
                # acceptInspiration). The wizard model already understands
                # these fields.
                "flight_price_eur": base["flight_price_eur"],
                "weather": base["weather"],
                "lat": base["lat"],
                "lon": base["lon"],
            }
        )

    if not output:
        logger.warn("inspire_then_rank: every ranked entry was dropped")
        return []
    return output
