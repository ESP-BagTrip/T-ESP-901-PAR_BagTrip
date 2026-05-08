"""W1 — "Inspire-me" destination orchestrator.

Pipeline:

1. Resolve the user's origin city to an IATA code (offline — :mod:`airportsdata`).
2. Hit Amadeus Flight Inspiration to get a real catalogue of destinations
   reachable from that origin, with a baseline price.
3. For the top N candidates, parallel-enrich with:
   - destination metadata (city / country / coords) via offline aviation data
   - real weather forecast (Open-Meteo)
4. Run a **single** LLM call that picks 3-4 best matches for the user
   profile and writes the narrative copy (``match_reason``,
   ``weather_summary``, ``top_activities``). The LLM cannot invent an
   IATA — its output is constrained to the candidate set via a strict
   JSON schema.
5. Fetch Unsplash cover images in parallel.

The orchestrator yields ``(event_type, data)`` tuples; the route layer
wraps them as Server-Sent Events. Degradation strategy is explicit:
when Amadeus inspiration fails, the orchestrator emits a ``warning``
event and falls back to the LLM-only path so the wizard still gets
something to render.
"""

from __future__ import annotations

import asyncio
import time
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from typing import Any

from src.agent.prompts import render
from src.agent.tools.weather import get_weather
from src.integrations.amadeus.types import (
    FlightInspirationSearchQuery,
    FlightOfferSearchQuery,
)
from src.integrations.aviation_data.service import (
    AviationDataService,
    Location,
)
from src.integrations.unsplash import unsplash_client
from src.services.amadeus_service import AmadeusService
from src.services.llm_router import LLMRouter
from src.utils.errors import AppError
from src.utils.locale import normalize_locale
from src.utils.logger import logger

# ── Config ─────────────────────────────────────────────────────────────

#: How many Amadeus inspiration candidates we enrich (weather + flight).
#: Higher = more LLM work but better coverage; lower = faster.
TOP_K_CANDIDATES = 8

#: How many destinations we ship to the client by default.
DEFAULT_PICK_COUNT = 4


# ── Public dataclass surface ───────────────────────────────────────────


@dataclass
class InspireRequest:
    """Trimmed-down trip prefs needed for the inspire workflow."""

    origin_city: str
    travel_types: str = ""
    duration_days: int = 7
    departure_date: str = ""
    return_date: str = ""
    season: str = ""
    companions: str = "solo"
    constraints: str = ""
    budget_preset: str = ""
    nb_travelers: int = 1
    locale: str = "en"
    pick_count: int = DEFAULT_PICK_COUNT


@dataclass
class _Candidate:
    """Working state for one Amadeus-suggested destination."""

    iata: str
    departure_date: str
    return_date: str | None = None
    inspire_price_eur: float | None = None
    location: Location | None = None
    weather: dict[str, Any] | None = None
    cheapest_price: dict[str, Any] | None = None
    image_url: str | None = None
    # Filled in after the LLM ranking pass.
    match_reason: str = ""
    weather_summary: str = ""
    top_activities: list[str] = field(default_factory=list)
    selected: bool = False

    @property
    def has_metadata(self) -> bool:
        return self.location is not None


# ── Service ────────────────────────────────────────────────────────────


class InspireOrchestrator:
    """Stateless orchestrator — call :meth:`stream` per request."""

    _aviation = AviationDataService()

    @classmethod
    async def stream(cls, req: InspireRequest) -> AsyncIterator[tuple[str, dict]]:
        """Yield SSE-shaped events for one inspire run."""
        t_start = time.monotonic()
        yield "progress", {"phase": "starting", "message": "Looking for ideas…"}

        # 1. Origin IATA — offline lookup, fast.
        origin_iata = cls._resolve_origin_iata(req.origin_city)
        if not origin_iata:
            yield (
                "error",
                {
                    "code": "ORIGIN_UNRESOLVED",
                    "message": f"Could not resolve origin '{req.origin_city}' to an IATA code.",
                },
            )
            return
        yield "progress", {"phase": "resolving_origin", "originIata": origin_iata}

        # 2. Amadeus inspiration — fail soft. The Amadeus client raises
        # ``AppError`` (any 4xx/5xx wrapped uniformly) on failure; we widen
        # to ``Exception`` because the integration also raises connection
        # errors and the resolver shouldn't crash on any of them.
        try:
            inspirations = await cls._fetch_inspirations(origin_iata, req)
        except Exception as exc:
            logger.warn(
                "Inspire: Amadeus inspiration failed, falling back to LLM-only path",
                {"origin": origin_iata, "error": str(exc)},
            )
            yield (
                "warning",
                {
                    "code": "INSPIRE_AMADEUS_DOWN",
                    "message": "Live inventory unavailable; using offline suggestions.",
                },
            )
            inspirations = []

        # 3. If we got nothing usable from Amadeus, fall back to the
        #    LLM-only suggestion path. Otherwise continue with the
        #    enrichment pipeline.
        if not inspirations:
            picked = await cls._llm_only_fallback(req)
            yield "destinations", {"destinations": picked, "originIata": origin_iata}
            yield (
                "complete",
                {
                    "destinations": picked,
                    "mode": "destinations_only",
                    "originIata": origin_iata,
                    "source": "llm_only",
                    "elapsed_s": round(time.monotonic() - t_start, 2),
                },
            )
            return

        candidates = inspirations[:TOP_K_CANDIDATES]
        yield (
            "progress",
            {
                "phase": "enriching",
                "candidateCount": len(candidates),
                "originIata": origin_iata,
            },
        )

        # 4. Resolve metadata + parallel weather + cheapest-flight enrichment.
        await cls._enrich_candidates(origin_iata, candidates)
        usable = [c for c in candidates if c.has_metadata]
        if not usable:
            # Every IATA the inspire endpoint returned was unknown to
            # offline aviation data. Fall back rather than ship an empty
            # list to the client.
            picked = await cls._llm_only_fallback(req)
            yield "destinations", {"destinations": picked, "originIata": origin_iata}
            yield (
                "complete",
                {
                    "destinations": picked,
                    "mode": "destinations_only",
                    "originIata": origin_iata,
                    "source": "llm_only",
                    "elapsed_s": round(time.monotonic() - t_start, 2),
                },
            )
            return

        # 5. Single LLM call: rank + narrate.
        yield "progress", {"phase": "ranking", "message": "Choosing the best matches…"}
        try:
            await cls._rank_with_llm(req, usable)
        except AppError as exc:
            logger.warn("Inspire: LLM ranker failed", {"code": exc.code, "msg": exc.message})
            # Hard fail here — without ranking, we can't compose match reasons.
            yield "error", {"code": exc.code, "message": exc.message}
            return

        selected = [c for c in usable if c.selected][: req.pick_count]
        if not selected:
            # Defensive: LLM didn't pick anything valid → ship the top N
            # by Amadeus inspire price with a generic reason.
            for c in usable[: req.pick_count]:
                c.selected = True
                c.match_reason = c.match_reason or "Popular pick from your origin."
            selected = [c for c in usable if c.selected]

        # 6. Cover images, parallel.
        await cls._fetch_cover_images(selected)

        payload = [cls._serialize(c) for c in selected]
        yield "destinations", {"destinations": payload, "originIata": origin_iata}
        yield (
            "complete",
            {
                "destinations": payload,
                "mode": "destinations_only",
                "originIata": origin_iata,
                "source": "amadeus_inspire",
                "elapsed_s": round(time.monotonic() - t_start, 2),
            },
        )

    # ── Pipeline steps ────────────────────────────────────────────────

    @classmethod
    def _lookup_iata_for_city(cls, city: str, country_hint: str = "") -> Location | None:
        """City + optional country → best matching airportsdata Location.

        Disambiguates collisions like "Florence" (Italy vs South Carolina)
        by preferring matches whose country name or country code aligns
        with ``country_hint``. Falls back to the unfiltered top result
        when no country match is found, so monolingual matches still
        resolve.
        """
        results = cls._aviation.search_by_keyword(city, sub_type="CITY,AIRPORT", limit=10)
        if not results:
            return None
        if not country_hint:
            return results[0]

        ch_lower = country_hint.strip().lower()
        for loc in results:
            addr = loc.address
            if addr is None:
                continue
            if (addr.countryName and addr.countryName.lower() == ch_lower) or (
                addr.countryCode and addr.countryCode.lower() == ch_lower
            ):
                return loc
        # No country-aware match — degrade to the unfiltered best hit
        # rather than dropping the candidate entirely.
        return results[0]

    @classmethod
    def _resolve_origin_iata(cls, origin_city: str) -> str | None:
        if not origin_city or not origin_city.strip():
            return None
        results = cls._aviation.search_by_keyword(
            origin_city.strip(), sub_type="CITY,AIRPORT", limit=1
        )
        if not results:
            return None
        loc = results[0]
        return loc.iataCode or (loc.address.cityCode if loc.address else None)

    @staticmethod
    async def _fetch_inspirations(origin: str, req: InspireRequest) -> list[_Candidate]:
        query = FlightInspirationSearchQuery(
            origin=origin,
            departureDate=req.departure_date or None,
            duration=req.duration_days or None,
            viewBy="DESTINATION",
        )
        response = await AmadeusService.search_flight_destinations(query)
        candidates: list[_Candidate] = []
        for entry in response.data or []:
            try:
                price = float(entry.price.total)
            except (ValueError, TypeError, AttributeError):
                price = None
            candidates.append(
                _Candidate(
                    iata=entry.destination,
                    departure_date=entry.departureDate,
                    return_date=entry.returnDate,
                    inspire_price_eur=price,
                )
            )
        # Cheapest first — gives the LLM a budget-friendly bias by default.
        candidates.sort(key=lambda c: c.inspire_price_eur or float("inf"))
        return candidates

    @classmethod
    async def _enrich_candidates(cls, origin_iata: str, candidates: list[_Candidate]) -> None:
        # Resolve metadata first (cheap, sync, offline) so we can drop
        # candidates that don't map to a known airport before paying for
        # weather/flight calls.
        for c in candidates:
            c.location = cls._aviation.get_by_id(c.iata)

        usable = [c for c in candidates if c.has_metadata]
        if not usable:
            return

        # Parallel weather fetch. Open-Meteo has its own caching layer
        # (idempotency_cache) so re-runs are virtually free.
        async def _weather(c: _Candidate) -> None:
            assert c.location is not None
            if not c.departure_date:
                return
            try:
                c.weather = await get_weather(
                    latitude=c.location.geoCode.latitude,
                    longitude=c.location.geoCode.longitude,
                    start_date=c.departure_date,
                    end_date=c.return_date or c.departure_date,
                )
            except Exception as exc:
                logger.warn(
                    "Inspire: weather lookup failed",
                    {"iata": c.iata, "error": str(exc)},
                )

        await asyncio.gather(*[_weather(c) for c in usable])

    @classmethod
    async def _rank_with_llm(cls, req: InspireRequest, candidates: list[_Candidate]) -> None:
        """Single LLM call. Strict JSON schema constrains IATAs to the candidate set."""
        locale = normalize_locale(req.locale)
        system_prompt = render("inspire_rank", locale=locale, pick_count=req.pick_count)
        user_prompt = cls._compose_user_prompt(req, candidates)

        candidate_iatas = [c.iata for c in candidates]
        schema = {
            "name": "inspire_picks",
            "schema": {
                "type": "object",
                "properties": {
                    "destinations": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": req.pick_count,
                        "items": {
                            "type": "object",
                            "properties": {
                                "iata": {"type": "string", "enum": candidate_iatas},
                                "match_reason": {"type": "string"},
                                "weather_summary": {"type": "string"},
                                "top_activities": {
                                    "type": "array",
                                    "items": {"type": "string"},
                                    "minItems": 3,
                                    "maxItems": 5,
                                },
                            },
                            "required": [
                                "iata",
                                "match_reason",
                                "weather_summary",
                                "top_activities",
                            ],
                            "additionalProperties": False,
                        },
                    }
                },
                "required": ["destinations"],
                "additionalProperties": False,
            },
            "strict": True,
        }

        payload = await LLMRouter.get().chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_schema", "json_schema": schema},
            temperature=0.4,
            max_tokens=900,
        )
        raw = payload["choices"][0]["message"].get("content") or "{}"
        import json

        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise AppError(
                "INSPIRE_RANK_INVALID_JSON",
                502,
                f"LLM ranker returned invalid JSON: {exc}",
            ) from exc

        by_iata = {c.iata: c for c in candidates}
        for pick in parsed.get("destinations", []):
            iata = pick.get("iata")
            target = by_iata.get(iata)
            if target is None:
                # The LLM hallucinated an IATA outside the candidate set —
                # the strict schema should prevent this, but we still
                # defend against it.
                continue
            target.selected = True
            target.match_reason = pick.get("match_reason", "")
            target.weather_summary = pick.get("weather_summary", "")
            target.top_activities = list(pick.get("top_activities", []))

    @staticmethod
    def _compose_user_prompt(req: InspireRequest, candidates: list[_Candidate]) -> str:
        lines: list[str] = ["User profile:"]
        if req.travel_types:
            lines.append(f"- travel_types: {req.travel_types}")
        if req.companions:
            lines.append(f"- companions: {req.companions}")
        if req.duration_days:
            lines.append(f"- duration_days: {req.duration_days}")
        if req.season:
            lines.append(f"- season: {req.season}")
        if req.budget_preset:
            lines.append(f"- budget_preset: {req.budget_preset}")
        if req.constraints:
            lines.append(f"- constraints: {req.constraints}")
        if req.nb_travelers:
            lines.append(f"- nb_travelers: {req.nb_travelers}")

        lines.append("")
        lines.append("Candidates (pick from this list ONLY):")
        for c in candidates:
            assert c.location is not None
            city = c.location.address.cityName if c.location.address else c.iata
            country = (
                c.location.address.countryName
                if c.location.address and c.location.address.countryName
                else ""
            )
            price = (
                f"{round(c.inspire_price_eur)} EUR" if c.inspire_price_eur is not None else "n/a"
            )
            weather_bits: list[str] = []
            if c.weather:
                avg = c.weather.get("avg_temp_c")
                desc = c.weather.get("description") or ""
                if avg is not None:
                    weather_bits.append(f"avg {avg}°C")
                if desc:
                    weather_bits.append(desc)
            weather_str = "; ".join(weather_bits) or "n/a"
            line = (
                f"- iata={c.iata} city={city!r} country={country!r} "
                f"cheapest_from_origin={price} weather=({weather_str})"
            )
            lines.append(line)

        return "\n".join(lines)

    @staticmethod
    async def _fetch_cover_images(candidates: list[_Candidate]) -> None:
        async def _one(c: _Candidate) -> None:
            assert c.location is not None
            city = c.location.address.cityName if c.location.address else c.iata
            country = c.location.address.countryName if c.location.address else ""
            query = f"{city}, {country}" if country else city
            url = await unsplash_client.fetch_cover_image(query)
            c.image_url = url or unsplash_client.get_fallback_url(query)

        await asyncio.gather(*[_one(c) for c in candidates])

    @staticmethod
    def _serialize(c: _Candidate) -> dict[str, Any]:
        loc = c.location
        assert loc is not None
        addr = loc.address
        return {
            "iata": c.iata,
            "city": addr.cityName if addr else c.iata,
            "country": addr.countryName if addr else "",
            "country_code": addr.countryCode if addr else "",
            "lat": loc.geoCode.latitude,
            "lon": loc.geoCode.longitude,
            "match_reason": c.match_reason,
            "weather_summary": c.weather_summary,
            "topActivities": c.top_activities,
            "weather": c.weather,
            "price_from": (
                {
                    "amount": c.inspire_price_eur,
                    "currency": "EUR",
                    "source": "amadeus",
                }
                if c.inspire_price_eur is not None
                else None
            ),
            "image_url": c.image_url,
        }

    # ── LLM-only degradation path ─────────────────────────────────────

    @classmethod
    async def _llm_only_fallback(cls, req: InspireRequest) -> list[dict[str, Any]]:
        """When Amadeus is unreachable, fall back to a pure-LLM suggestion.

        We still try to attach an IATA via offline lookup so the client
        can later request a full plan against the right airport. Items
        for which the LLM's city is unknown to ``airportsdata`` are
        dropped rather than shipped without an IATA (audit C3 — the
        inspire response must always carry IATAs).
        """
        from src.utils.locale import normalize_locale

        locale = normalize_locale(req.locale)
        system_prompt = render("destination_quick", locale=locale)
        user_prompt = cls._compose_fallback_user_prompt(req)
        payload = await LLMRouter.get().chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.6,
            max_tokens=900,
        )
        import json

        raw = payload["choices"][0]["message"].get("content") or "{}"
        # Some smaller models still wrap JSON in markdown fences here —
        # destination_quick predates strict mode. Strip defensively.
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[-1]
            if raw.endswith("```"):
                raw = raw.rsplit("```", 1)[0]
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            return []

        out: list[dict[str, Any]] = []
        for entry in parsed.get("destinations", []) or []:
            city = (entry.get("city") or "").strip()
            if not city:
                continue
            country_hint = (entry.get("country") or "").strip()
            loc = cls._lookup_iata_for_city(city, country_hint)
            if loc is None:
                # No IATA → drop. Better to return 2 typed cards than 4 blanks.
                continue
            iata = loc.iataCode or (loc.address.cityCode if loc.address else None)
            if not iata:
                continue
            out.append(
                {
                    "iata": iata,
                    "city": loc.address.cityName if loc.address else city,
                    "country": loc.address.countryName if loc.address else "",
                    "country_code": loc.address.countryCode if loc.address else "",
                    "lat": loc.geoCode.latitude,
                    "lon": loc.geoCode.longitude,
                    "match_reason": entry.get("match_reason", ""),
                    "weather_summary": entry.get("weather_summary", ""),
                    "topActivities": entry.get("topActivities", []),
                    "weather": None,
                    "price_from": None,
                    "image_url": None,
                }
            )
            if len(out) >= req.pick_count:
                break

        # Best-effort cover images for the fallback path too.
        await cls._fill_fallback_images(out)
        return out

    @staticmethod
    def _compose_fallback_user_prompt(req: InspireRequest) -> str:
        lines: list[str] = []
        if req.travel_types:
            lines.append(f"- travel_types: {req.travel_types}")
        if req.companions:
            lines.append(f"- companions: {req.companions}")
        if req.duration_days:
            lines.append(f"- duration_days: {req.duration_days}")
        if req.season:
            lines.append(f"- season: {req.season}")
        if req.budget_preset:
            lines.append(f"- budget_preset: {req.budget_preset}")
        if req.constraints:
            lines.append(f"- constraints: {req.constraints}")
        return "\n".join(lines) if lines else "Suggest popular destinations."

    @staticmethod
    async def _fill_fallback_images(payload: list[dict[str, Any]]) -> None:
        async def _one(item: dict[str, Any]) -> None:
            city = item.get("city") or ""
            country = item.get("country") or ""
            if not city:
                return
            query = f"{city}, {country}" if country else city
            url = await unsplash_client.fetch_cover_image(query)
            item["image_url"] = url or unsplash_client.get_fallback_url(query)

        await asyncio.gather(*[_one(item) for item in payload])


# Re-exported for convenience.
__all__ = ["InspireOrchestrator", "InspireRequest"]


# Defensive: silence the "unused import" warning for FlightOfferSearchQuery.
# Phase 2.x will use it when we add the per-destination cheapest-flight
# refinement; keeping the import here documents the shape we expect.
_ = FlightOfferSearchQuery
