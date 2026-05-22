"""W2 — full trip plan orchestrator.

Replaces the LangGraph + manual ReAct pipeline with a code-only async
orchestrator. The pipeline is straightforward:

1. Resolve origin and destination via :class:`LocationResolver`
   (multilingual cascade — fixes audit C3 / Q3).
2. Fetch the destination weather from Open-Meteo (sequential, because
   the activity and baggage prompts read it).
3. Run the four heavy sub-tasks in parallel:
   - **activities** — single LLM call with a strict JSON schema; the
     model picks 6–9 ideas grounded in the user profile and the real
     weather. No ReAct loop, no JSON repair.
   - **accommodations** — Amadeus hotel list + offers, two-step.
   - **transport** — flight via Amadeus, or a deterministic train
     estimate when origin and destination are in the same country and
     within :data:`TRAIN_THRESHOLD_KM`. Tackles audit C2 (Marseille
     was getting a fictitious 800 EUR flight quote).
   - **baggage** — single LLM call, weather + activities aware.
4. Compose a :class:`TripDraftCommand` DTO. The dataclass is a clean
   handover surface to :mod:`plan_draft_service` (Phase 3c wires it).

Each step yields ``(event_type, data)`` tuples for the SSE layer.
Failures emit ``warning`` events with a stable code so the client
(and the eventual eval harness) can tell ``amadeus_inspire_down`` from
``llm_invalid_json`` without parsing free-form messages.
"""

from __future__ import annotations

import asyncio
import json
import math
import time
from collections.abc import AsyncIterator
from dataclasses import asdict, dataclass, field
from typing import Any

from src.agent.prompts import render
from src.agent.tools.weather import get_weather
from src.integrations.amadeus.types import (
    FlightOfferSearchQuery,
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)
from src.integrations.unsplash import unsplash_client
from src.services import currency_service
from src.services.amadeus_service import AmadeusService
from src.services.llm_router import LLMRouter
from src.services.location_resolver import LocationResolver, ResolvedLocation
from src.utils.errors import AppError
from src.utils.locale import normalize_locale
from src.utils.logger import logger

# ── Tunables ───────────────────────────────────────────────────────────

#: Same-country origin/destination pairs within this haversine distance
#: are routed via TRAIN by default. Beyond this we ask Amadeus for a
#: flight. The Marseille / Paris case (660 km, FR/FR) lands TRAIN.
TRAIN_THRESHOLD_KM = 1000.0

#: Per-day food + transport allowances by budget preset, used to derive
#: the deterministic ``food`` and ``transport`` lines of the budget
#: breakdown when no concrete data was gathered.
_BUDGET_PRESET_FOOD_PER_DAY = {
    "BACKPACKER": 25,
    "COMFORTABLE": 45,
    "PREMIUM": 90,
    "NO_LIMIT": 120,
}
_BUDGET_PRESET_TRANSPORT_PER_DAY = {
    "BACKPACKER": 8,
    "COMFORTABLE": 15,
    "PREMIUM": 30,
    "NO_LIMIT": 50,
}

#: Per-100km train estimate (EUR, round-trip) by budget preset. The
#: numbers are deliberately conservative — when the user has SNCF /
#: equivalent rail in place these are the cost bands they should expect.
_TRAIN_PER_100KM_EUR = {
    "BACKPACKER": 14.0,
    "COMFORTABLE": 22.0,
    "PREMIUM": 35.0,
    "NO_LIMIT": 50.0,
}

#: How many activity ideas the LLM produces. The feasibility pass in
#: Phase 3c will trim and schedule them.
ACTIVITY_BRAINSTORM_TARGET = 9

#: Maximum baggage items asked from the LLM.
BAGGAGE_TARGET = 14

#: Amadeus hotel ratings we accept (3–5 stars). Lower-tier listings
#: tend to come back with no offers and pollute the picker.
_AMADEUS_HOTEL_RATINGS = "3,4,5"

#: Canonical currency the deterministic budget breakdown is expressed in.
#: Amadeus quotes hotels/flights in the property's *local* currency, so
#: every line is converted to this before it is summed.
_BUDGET_CURRENCY = "EUR"

# ── Public DTOs ───────────────────────────────────────────────────────


@dataclass
class FullPlanRequest:
    """User-facing request shape — fed into :meth:`FullPlanOrchestrator.stream`."""

    origin_city: str
    destination_city: str
    destination_iata: str = ""
    travel_types: str = ""
    duration_days: int = 7
    departure_date: str = ""
    return_date: str = ""
    season: str = ""
    companions: str = "solo"
    constraints: str = ""
    budget_preset: str = ""
    nb_travelers: int = 1
    target_budget: float | None = None
    locale: str = "en"


@dataclass
class WeatherSummary:
    """Open-Meteo derived forecast — what the LLM prompts and the budget see."""

    avg_temp_c: float
    min_temp_c: float
    max_temp_c: float
    rain_probability: float
    description: str
    source: str = "open-meteo"


@dataclass
class ActivityDraft:
    """One activity idea — pre-feasibility-pass.

    ``suggested_day`` and ``time_of_day`` may be ``None`` when the LLM
    couldn't anchor the activity (FOOD recommendations, free
    side-trips). Phase 3c assigns / drops these.
    """

    title: str
    description: str
    category: str
    estimated_cost: float = 0.0
    suggested_day: int | None = None
    time_of_day: str | None = None
    location: str = ""


@dataclass
class AccommodationDraft:
    """One Amadeus-grounded hotel suggestion (or a placeholder when none found)."""

    name: str
    hotel_id: str = ""
    rating: float | None = None
    price_total: float | None = None
    price_per_night: float | None = None
    nights: int = 0
    adults: int = 1
    currency: str = "EUR"
    check_in: str = ""
    check_out: str = ""
    source: str = "amadeus"  # amadeus | estimated | deferred


@dataclass
class TransportLeg:
    """Outbound or return segment of the main transport (flight or train)."""

    mode: str  # FLIGHT | TRAIN
    direction: str  # OUTBOUND | RETURN
    carrier: str = ""
    code: str = ""
    origin_iata: str = ""
    destination_iata: str = ""
    origin_city: str = ""
    destination_city: str = ""
    departure_at: str = ""
    arrival_at: str = ""
    price: float | None = None
    currency: str = "EUR"
    source: str = "amadeus"  # amadeus | estimated | sncf


@dataclass
class BaggageDraft:
    """One packing-list item."""

    name: str
    quantity: int = 1
    category: str = "OTHER"
    reason: str = ""


@dataclass
class BudgetBreakdown:
    """Deterministic budget assembled from the gathered sub-task outputs."""

    transport: float = 0.0
    transport_source: str = "estimated"
    accommodation: float = 0.0
    accommodation_source: str = "estimated"
    food: float = 0.0
    activity: float = 0.0
    total_min: float = 0.0
    total_max: float = 0.0
    currency: str = "EUR"


@dataclass
class TripDraftCommand:
    """Cleanly typed handover surface for :mod:`plan_draft_service`."""

    origin_iata: str
    origin_city: str
    destination_iata: str
    destination_city: str
    destination_country: str
    destination_country_code: str
    destination_lat: float
    destination_lon: float
    start_date: str
    end_date: str
    duration_days: int
    nb_travelers: int
    target_budget: float | None
    locale: str
    cover_image_url: str | None
    weather: WeatherSummary | None
    activities: list[ActivityDraft] = field(default_factory=list)
    accommodations: list[AccommodationDraft] = field(default_factory=list)
    transport: list[TransportLeg] = field(default_factory=list)
    baggage: list[BaggageDraft] = field(default_factory=list)
    budget: BudgetBreakdown = field(default_factory=BudgetBreakdown)


# ── Orchestrator ──────────────────────────────────────────────────────


class FullPlanOrchestrator:
    """Stateless — call :meth:`stream` per request."""

    @classmethod
    async def stream(cls, req: FullPlanRequest) -> AsyncIterator[tuple[str, dict]]:
        """Yield SSE-shaped events; final event includes the TripDraftCommand dict."""
        t_start = time.monotonic()
        yield "progress", {"phase": "starting", "message": "Resolving locations…"}

        # 1. Origin + destination resolution.
        origin = await LocationResolver.resolve(req.origin_city, locale=req.locale)
        if origin is None:
            yield (
                "error",
                {
                    "code": "ORIGIN_UNRESOLVED",
                    "message": f"Could not resolve origin '{req.origin_city}'.",
                },
            )
            return
        dest = await cls._resolve_destination(req)
        if dest is None:
            yield (
                "error",
                {
                    "code": "DESTINATION_UNRESOLVED",
                    "message": f"Could not resolve destination '{req.destination_city}'.",
                },
            )
            return
        yield (
            "progress",
            {
                "phase": "resolved",
                "originIata": origin.iata,
                "destinationIata": dest.iata,
                "destinationCity": dest.city,
                "destinationCountry": dest.country,
            },
        )

        # 2. Weather first — activities + baggage prompts feed on it.
        yield "progress", {"phase": "weather"}
        weather = await cls._fetch_weather(dest, req)

        # 3. Parallel sub-tasks. Each returns a typed result or raises;
        #    the orchestrator surfaces failures as ``warning`` events
        #    with stable codes.
        yield "progress", {"phase": "parallel_planning"}
        activities_task = cls._brainstorm_activities(dest, weather, req)
        accommodations_task = cls._search_accommodations(dest, req)
        transport_task = cls._build_transport(origin, dest, req)
        baggage_task = cls._advise_baggage(dest, weather, req)
        cover_task = cls._fetch_cover_image(dest)

        results = await asyncio.gather(
            activities_task,
            accommodations_task,
            transport_task,
            baggage_task,
            cover_task,
            return_exceptions=True,
        )
        raw_activities, raw_accommodations, raw_transport, raw_baggage, raw_cover = results

        warnings: list[dict[str, str]] = []
        activities: list[ActivityDraft] = []
        if isinstance(raw_activities, BaseException):
            logger.warn("FullPlan: activities failed", {"error": str(raw_activities)})
            warnings.append({"code": "ACTIVITIES_FAILED", "message": str(raw_activities)})
        else:
            activities = raw_activities

        accommodations: list[AccommodationDraft] = []
        if isinstance(raw_accommodations, BaseException):
            logger.warn("FullPlan: accommodations failed", {"error": str(raw_accommodations)})
            warnings.append(
                {"code": "ACCOMMODATIONS_AMADEUS_DOWN", "message": str(raw_accommodations)}
            )
        else:
            accommodations = raw_accommodations

        transport: list[TransportLeg] = []
        if isinstance(raw_transport, BaseException):
            logger.warn("FullPlan: transport failed", {"error": str(raw_transport)})
            warnings.append({"code": "TRANSPORT_AMADEUS_DOWN", "message": str(raw_transport)})
        else:
            transport = raw_transport

        baggage: list[BaggageDraft] = []
        if isinstance(raw_baggage, BaseException):
            logger.warn("FullPlan: baggage failed", {"error": str(raw_baggage)})
            warnings.append({"code": "BAGGAGE_FAILED", "message": str(raw_baggage)})
        else:
            baggage = raw_baggage

        cover_url: str | None = None
        if isinstance(raw_cover, BaseException):
            logger.warn("FullPlan: cover image fetch failed", {"error": str(raw_cover)})
        else:
            cover_url = raw_cover

        for w in warnings:
            yield "warning", w

        # 4. Deterministic budget assembly.
        budget = cls._compute_budget(
            transport=transport,
            accommodations=accommodations,
            activities=activities,
            weather=weather,
            req=req,
        )

        # 5. DTO assembly. Phase 3c hands this to PlanDraftService.
        start_date, end_date = cls._normalise_dates(req)
        cmd = TripDraftCommand(
            origin_iata=origin.iata,
            origin_city=origin.city,
            destination_iata=dest.iata,
            destination_city=dest.city,
            destination_country=dest.country,
            destination_country_code=dest.country_code,
            destination_lat=dest.lat,
            destination_lon=dest.lon,
            start_date=start_date,
            end_date=end_date,
            duration_days=req.duration_days,
            nb_travelers=req.nb_travelers,
            target_budget=req.target_budget,
            locale=req.locale,
            cover_image_url=cover_url,
            weather=weather,
            activities=activities,
            accommodations=accommodations,
            transport=transport,
            baggage=baggage,
            budget=budget,
        )

        yield (
            "destinations",
            {
                "destinations": [
                    {
                        "iata": dest.iata,
                        "city": dest.city,
                        "country": dest.country,
                        "lat": dest.lat,
                        "lon": dest.lon,
                    }
                ],
                "originIata": origin.iata,
            },
        )
        if weather is not None:
            yield "weather", asdict(weather)
        if activities:
            yield "activities", {"activities": [asdict(a) for a in activities]}
        if accommodations:
            yield "accommodations", {"accommodations": [asdict(a) for a in accommodations]}
        if transport:
            yield "transport", {"legs": [asdict(t) for t in transport]}
        if baggage:
            yield "baggage", {"items": [asdict(b) for b in baggage]}
        yield "budget", {"budget": asdict(budget)}
        yield (
            "complete",
            {
                "trip_draft": _command_to_dict(cmd),
                "elapsed_s": round(time.monotonic() - t_start, 2),
            },
        )

    # ── Resolution ────────────────────────────────────────────────────

    @staticmethod
    async def _resolve_destination(req: FullPlanRequest) -> ResolvedLocation | None:
        # IATA pre-supplied (e.g. coming from W1 inspire) → skip the
        # geocoding round-trip entirely.
        if req.destination_iata and len(req.destination_iata) == 3:
            return await LocationResolver.resolve(req.destination_iata, locale=req.locale)
        return await LocationResolver.resolve(req.destination_city, locale=req.locale)

    # ── Weather (sequential — feeds two LLM prompts) ──────────────────

    @staticmethod
    async def _fetch_weather(dest: ResolvedLocation, req: FullPlanRequest) -> WeatherSummary | None:
        if not req.departure_date:
            return None
        try:
            data = await get_weather(
                latitude=dest.lat,
                longitude=dest.lon,
                start_date=req.departure_date,
                end_date=req.return_date or req.departure_date,
            )
        except Exception as exc:
            logger.warn("FullPlan: get_weather failed", {"error": str(exc)})
            return None
        return WeatherSummary(
            avg_temp_c=float(data.get("avg_temp_c", 20)),
            min_temp_c=float(data.get("min_temp_c", 15)),
            max_temp_c=float(data.get("max_temp_c", 25)),
            rain_probability=float(data.get("rain_probability", 30)),
            description=str(data.get("description", "")),
            source=str(data.get("source", "open-meteo")),
        )

    # ── Activities (LLM, strict JSON schema) ──────────────────────────

    @classmethod
    async def _brainstorm_activities(
        cls,
        dest: ResolvedLocation,
        weather: WeatherSummary | None,
        req: FullPlanRequest,
    ) -> list[ActivityDraft]:
        locale = normalize_locale(req.locale)
        system_prompt = render(
            "activity_planner",
            locale=locale,
            target=ACTIVITY_BRAINSTORM_TARGET,
        )
        user_prompt = cls._compose_activity_user_prompt(dest, weather, req)
        schema = _activity_schema(target=ACTIVITY_BRAINSTORM_TARGET)
        payload = await LLMRouter.get().chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_schema", "json_schema": schema},
            temperature=0.5,
            max_tokens=1800,
        )
        raw = payload["choices"][0]["message"].get("content") or "{}"
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise AppError(
                "ACTIVITIES_INVALID_JSON",
                502,
                f"Activity brainstorm returned invalid JSON: {exc}",
            ) from exc
        return [_activity_from_dict(d) for d in parsed.get("activities", [])]

    @staticmethod
    def _compose_activity_user_prompt(
        dest: ResolvedLocation,
        weather: WeatherSummary | None,
        req: FullPlanRequest,
    ) -> str:
        lines = [f"Destination: {dest.city}, {dest.country} (IATA {dest.iata})"]
        if req.duration_days:
            lines.append(f"Duration: {req.duration_days} days")
        if req.travel_types:
            lines.append(f"Travel types: {req.travel_types}")
        if req.companions:
            lines.append(f"Companions: {req.companions}")
        if req.constraints:
            lines.append(f"Constraints: {req.constraints}")
        if req.budget_preset:
            lines.append(f"Budget preset: {req.budget_preset}")
        if req.nb_travelers:
            lines.append(f"Travelers: {req.nb_travelers}")
        if weather is not None:
            lines.append(
                f"Weather: avg {weather.avg_temp_c}°C "
                f"(min {weather.min_temp_c} / max {weather.max_temp_c}), "
                f"rain {weather.rain_probability:.0f}%, {weather.description}"
            )
        return "\n".join(lines)

    # ── Accommodations (Amadeus 2-step) ───────────────────────────────

    @staticmethod
    async def _search_accommodations(
        dest: ResolvedLocation, req: FullPlanRequest
    ) -> list[AccommodationDraft]:
        if not req.departure_date or not req.return_date:
            return []
        try:
            list_response = await AmadeusService.search_hotel_list(
                HotelListSearchQuery(cityCode=dest.iata, ratings=_AMADEUS_HOTEL_RATINGS)
            )
        except Exception as exc:
            raise AppError(
                "ACCOMMODATIONS_LIST_FAILED",
                502,
                f"Amadeus hotel list failed: {exc}",
            ) from exc
        hotel_ids = [h.hotelId for h in list_response.data[:10] if h.hotelId]
        if not hotel_ids:
            return []
        nights = _count_nights(req.departure_date, req.return_date)
        try:
            offers_response = await AmadeusService.search_hotel_offers(
                HotelOffersSearchQuery(
                    hotelIds=",".join(hotel_ids),
                    adults=req.nb_travelers,
                    checkInDate=req.departure_date,
                    checkOutDate=req.return_date,
                    currency="EUR",
                )
            )
        except Exception as exc:
            raise AppError(
                "ACCOMMODATIONS_OFFERS_FAILED",
                502,
                f"Amadeus hotel offers failed: {exc}",
            ) from exc

        out: list[AccommodationDraft] = []
        for entry in offers_response.data or []:
            hotel = entry.hotel or {}
            offers = entry.offers or []
            best_offer = offers[0] if offers else None
            if not hotel or best_offer is None or best_offer.price is None:
                continue
            try:
                price_total = float(best_offer.price.total) if best_offer.price.total else None
            except (ValueError, TypeError):
                price_total = None
            price_per_night = price_total / nights if price_total and nights else None
            rating_raw = hotel.get("rating")
            try:
                rating = float(rating_raw) if rating_raw is not None else None
            except (ValueError, TypeError):
                rating = None
            out.append(
                AccommodationDraft(
                    name=str(hotel.get("name") or ""),
                    hotel_id=str(hotel.get("hotelId") or ""),
                    rating=rating,
                    price_total=price_total,
                    price_per_night=price_per_night,
                    nights=nights,
                    adults=req.nb_travelers,
                    currency=best_offer.price.currency or "EUR",
                    check_in=req.departure_date,
                    check_out=req.return_date,
                    source="amadeus",
                )
            )
        return out

    # ── Transport (flight via Amadeus, train via heuristic) ───────────

    @classmethod
    async def _build_transport(
        cls,
        origin: ResolvedLocation,
        dest: ResolvedLocation,
        req: FullPlanRequest,
    ) -> list[TransportLeg]:
        mode = cls._pick_transport_mode(origin, dest, req)
        if mode == "TRAIN":
            return cls._build_train_legs(origin, dest, req)
        return await cls._build_flight_legs(origin, dest, req)

    @staticmethod
    def _pick_transport_mode(
        origin: ResolvedLocation,
        dest: ResolvedLocation,
        req: FullPlanRequest,
    ) -> str:
        # Constraint phrases like "TGV", "train" or "ferry" force the
        # rail/ground path explicitly. We also tag the constraint
        # signal for observability.
        c = (req.constraints or "").lower()
        if "tgv" in c or "train" in c or "rail" in c:
            return "TRAIN"
        if origin.country_code != dest.country_code:
            return "FLIGHT"
        dist = _haversine_km(origin.lat, origin.lon, dest.lat, dest.lon)
        return "TRAIN" if dist <= TRAIN_THRESHOLD_KM else "FLIGHT"

    @staticmethod
    def _build_train_legs(
        origin: ResolvedLocation,
        dest: ResolvedLocation,
        req: FullPlanRequest,
    ) -> list[TransportLeg]:
        dist_km = _haversine_km(origin.lat, origin.lon, dest.lat, dest.lon)
        per_100 = _TRAIN_PER_100KM_EUR.get(
            req.budget_preset or "COMFORTABLE",
            _TRAIN_PER_100KM_EUR["COMFORTABLE"],
        )
        round_trip = round(per_100 * (dist_km / 100.0) * 2, 2)
        leg_price = round(round_trip / 2, 2)
        legs: list[TransportLeg] = []
        if req.departure_date:
            legs.append(
                TransportLeg(
                    mode="TRAIN",
                    direction="OUTBOUND",
                    carrier="National rail",
                    code="",
                    origin_iata=origin.iata,
                    destination_iata=dest.iata,
                    origin_city=origin.city,
                    destination_city=dest.city,
                    departure_at=req.departure_date,
                    arrival_at=req.departure_date,
                    price=leg_price,
                    currency="EUR",
                    source="estimated",
                )
            )
        if req.return_date:
            legs.append(
                TransportLeg(
                    mode="TRAIN",
                    direction="RETURN",
                    carrier="National rail",
                    code="",
                    origin_iata=dest.iata,
                    destination_iata=origin.iata,
                    origin_city=dest.city,
                    destination_city=origin.city,
                    departure_at=req.return_date,
                    arrival_at=req.return_date,
                    price=leg_price,
                    currency="EUR",
                    source="estimated",
                )
            )
        return legs

    @staticmethod
    async def _build_flight_legs(
        origin: ResolvedLocation,
        dest: ResolvedLocation,
        req: FullPlanRequest,
    ) -> list[TransportLeg]:
        if not req.departure_date:
            return []
        try:
            response = await AmadeusService.search_flight_offers(
                FlightOfferSearchQuery(
                    originLocationCode=origin.iata,
                    destinationLocationCode=dest.iata,
                    departureDate=req.departure_date,
                    returnDate=req.return_date or None,
                    adults=req.nb_travelers,
                    currencyCode="EUR",
                    max=5,
                )
            )
        except Exception as exc:
            raise AppError(
                "TRANSPORT_FLIGHT_FAILED",
                502,
                f"Amadeus flight offers failed: {exc}",
            ) from exc

        offers = response.data or []
        if not offers:
            return []
        cheapest = min(
            offers,
            key=lambda o: float(o.price.total) if o.price and o.price.total else float("inf"),
        )
        legs: list[TransportLeg] = []
        try:
            total_price = float(cheapest.price.total) if cheapest.price else None
        except (ValueError, TypeError):
            total_price = None
        for idx, itinerary in enumerate(cheapest.itineraries):
            if not itinerary.segments:
                continue
            first = itinerary.segments[0]
            last = itinerary.segments[-1]
            direction = "OUTBOUND" if idx == 0 else "RETURN"
            leg_price = (
                round(total_price / len(cheapest.itineraries), 2)
                if total_price is not None
                else None
            )
            legs.append(
                TransportLeg(
                    mode="FLIGHT",
                    direction=direction,
                    carrier=first.carrierCode or "",
                    code=f"{first.carrierCode or ''}{first.number or ''}",
                    origin_iata=first.departure.iataCode,
                    destination_iata=last.arrival.iataCode,
                    origin_city=origin.city if direction == "OUTBOUND" else dest.city,
                    destination_city=dest.city if direction == "OUTBOUND" else origin.city,
                    departure_at=first.departure.at,
                    arrival_at=last.arrival.at,
                    price=leg_price,
                    currency=cheapest.price.currency if cheapest.price else "EUR",
                    source="amadeus",
                )
            )
        return legs

    # ── Baggage (LLM, strict JSON schema) ─────────────────────────────

    @classmethod
    async def _advise_baggage(
        cls,
        dest: ResolvedLocation,
        weather: WeatherSummary | None,
        req: FullPlanRequest,
    ) -> list[BaggageDraft]:
        locale = normalize_locale(req.locale)
        system_prompt = render("baggage", locale=locale, target=BAGGAGE_TARGET)
        user_prompt = cls._compose_baggage_user_prompt(dest, weather, req)
        schema = _baggage_schema(target=BAGGAGE_TARGET)
        payload = await LLMRouter.get().chat_completion(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_schema", "json_schema": schema},
            temperature=0.4,
            max_tokens=1200,
        )
        raw = payload["choices"][0]["message"].get("content") or "{}"
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise AppError(
                "BAGGAGE_INVALID_JSON",
                502,
                f"Baggage advisor returned invalid JSON: {exc}",
            ) from exc
        return [_baggage_from_dict(d) for d in parsed.get("items", [])]

    @staticmethod
    def _compose_baggage_user_prompt(
        dest: ResolvedLocation,
        weather: WeatherSummary | None,
        req: FullPlanRequest,
    ) -> str:
        lines = [f"Destination: {dest.city}, {dest.country}"]
        if req.duration_days:
            lines.append(f"Duration: {req.duration_days} days")
        if req.companions:
            lines.append(f"Companions: {req.companions}")
        if req.constraints:
            lines.append(f"Constraints: {req.constraints}")
        if weather is not None:
            lines.append(
                f"Weather: avg {weather.avg_temp_c}°C "
                f"(min {weather.min_temp_c} / max {weather.max_temp_c}), "
                f"rain {weather.rain_probability:.0f}%"
            )
        return "\n".join(lines)

    # ── Cover image ───────────────────────────────────────────────────

    @staticmethod
    async def _fetch_cover_image(dest: ResolvedLocation) -> str | None:
        query = f"{dest.city}, {dest.country}" if dest.country else dest.city
        url = await unsplash_client.fetch_cover_image(query)
        return url or unsplash_client.get_fallback_url(query)

    # ── Budget composition ────────────────────────────────────────────

    @staticmethod
    def _compute_budget(
        *,
        transport: list[TransportLeg],
        accommodations: list[AccommodationDraft],
        activities: list[ActivityDraft],
        weather: WeatherSummary | None,
        req: FullPlanRequest,
    ) -> BudgetBreakdown:
        nights = _count_nights(req.departure_date, req.return_date)
        days = max(req.duration_days or nights or 1, 1)

        # Transport: real prices when available, else estimated heuristic.
        # Each leg is normalised to the budget currency — Amadeus may quote
        # a leg in a foreign currency and a raw sum would mix units.
        transport_total = sum(
            currency_service.convert(leg.price or 0.0, from_=leg.currency, to=_BUDGET_CURRENCY)
            for leg in transport
            if leg.price is not None
        )
        transport_source = (
            "amadeus"
            if any(leg.source == "amadeus" for leg in transport)
            else "estimated"
            if transport
            else "deferred"
        )

        # Accommodation: cheapest Amadeus offer that has a real total.
        # Amadeus returns hotel prices in the property's *local* currency
        # (e.g. KRW for Seoul); we convert every offer to the budget
        # currency before picking the cheapest — otherwise a Seoul stay
        # ships as a six-figure "1 578 000 €" line.
        priced_accs = [a for a in accommodations if a.price_total is not None]
        accommodation_total = (
            min(
                currency_service.convert(
                    a.price_total or 0.0, from_=a.currency, to=_BUDGET_CURRENCY
                )
                for a in priced_accs
            )
            if priced_accs
            else 0.0
        )
        accommodation_source = "amadeus" if priced_accs else "deferred"

        # Activities: sum of estimated_cost across the brainstormed list.
        activity_total = sum(a.estimated_cost or 0.0 for a in activities)

        # Food: deterministic per-day-per-traveler band.
        food_per_day = _BUDGET_PRESET_FOOD_PER_DAY.get(
            req.budget_preset or "COMFORTABLE",
            _BUDGET_PRESET_FOOD_PER_DAY["COMFORTABLE"],
        )
        food_total = food_per_day * days * max(req.nb_travelers, 1)

        # Local transport (within destination): same shape.
        local_per_day = _BUDGET_PRESET_TRANSPORT_PER_DAY.get(
            req.budget_preset or "COMFORTABLE",
            _BUDGET_PRESET_TRANSPORT_PER_DAY["COMFORTABLE"],
        )
        local_transport_total = local_per_day * days * max(req.nb_travelers, 1)

        total = (
            transport_total
            + accommodation_total
            + activity_total
            + food_total
            + local_transport_total
        )
        # ±20% band — generous enough to absorb unbooked variance without
        # becoming meaningless. Phase 3c can revisit per preset.
        total_min = round(total * 0.85, 0)
        total_max = round(total * 1.15, 0)
        return BudgetBreakdown(
            transport=round(transport_total + local_transport_total, 2),
            transport_source=transport_source,
            accommodation=round(accommodation_total, 2),
            accommodation_source=accommodation_source,
            food=round(food_total, 2),
            activity=round(activity_total, 2),
            total_min=total_min,
            total_max=total_max,
            currency=_BUDGET_CURRENCY,
        )

    # ── Helpers ───────────────────────────────────────────────────────

    @staticmethod
    def _normalise_dates(req: FullPlanRequest) -> tuple[str, str]:
        # Phase 3c will reuse the W2 date guard; for now we trust the
        # caller (the wizard payload always carries explicit dates by
        # the time it reaches W2 — the W1 inspire mode is the one that
        # had to derive them).
        return req.departure_date, req.return_date


# ── Schemas + parsers (private helpers) ───────────────────────────────


_ACTIVITY_CATEGORIES = (
    "CULTURE",
    "NATURE",
    "FOOD",
    "SPORT",
    "SHOPPING",
    "NIGHTLIFE",
    "RELAXATION",
    "TRANSPORT",
    "OTHER",
)
_TIME_OF_DAY = ("morning", "afternoon", "evening")


def _activity_schema(*, target: int) -> dict[str, Any]:
    return {
        "name": "activity_brainstorm",
        "schema": {
            "type": "object",
            "properties": {
                "activities": {
                    "type": "array",
                    "minItems": max(3, target - 3),
                    "maxItems": target + 3,
                    "items": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string"},
                            "description": {"type": "string"},
                            "category": {
                                "type": "string",
                                "enum": list(_ACTIVITY_CATEGORIES),
                            },
                            "estimated_cost": {"type": "number"},
                            "suggested_day": {"anyOf": [{"type": "integer"}, {"type": "null"}]},
                            "time_of_day": {
                                "anyOf": [
                                    {"type": "string", "enum": list(_TIME_OF_DAY)},
                                    {"type": "null"},
                                ]
                            },
                            "location": {"type": "string"},
                        },
                        "required": ["title", "description", "category", "estimated_cost"],
                        "additionalProperties": False,
                    },
                }
            },
            "required": ["activities"],
            "additionalProperties": False,
        },
        "strict": True,
    }


def _activity_from_dict(payload: dict[str, Any]) -> ActivityDraft:
    return ActivityDraft(
        title=str(payload.get("title", "")).strip(),
        description=str(payload.get("description", "")).strip(),
        category=str(payload.get("category", "OTHER")).upper(),
        estimated_cost=float(payload.get("estimated_cost") or 0.0),
        suggested_day=payload.get("suggested_day"),
        time_of_day=payload.get("time_of_day"),
        location=str(payload.get("location", "")).strip(),
    )


_BAGGAGE_CATEGORIES = (
    "DOCUMENTS",
    "CLOTHING",
    "ELECTRONICS",
    "TOILETRIES",
    "HEALTH",
    "ACCESSORIES",
    "OTHER",
)


def _baggage_schema(*, target: int) -> dict[str, Any]:
    return {
        "name": "baggage_advisor",
        "schema": {
            "type": "object",
            "properties": {
                "items": {
                    "type": "array",
                    "minItems": max(5, target - 4),
                    "maxItems": target + 4,
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string"},
                            "quantity": {"type": "integer", "minimum": 1},
                            "category": {
                                "type": "string",
                                "enum": list(_BAGGAGE_CATEGORIES),
                            },
                            "reason": {"type": "string"},
                        },
                        "required": ["name", "quantity", "category", "reason"],
                        "additionalProperties": False,
                    },
                }
            },
            "required": ["items"],
            "additionalProperties": False,
        },
        "strict": True,
    }


def _baggage_from_dict(payload: dict[str, Any]) -> BaggageDraft:
    return BaggageDraft(
        name=str(payload.get("name", "")).strip(),
        quantity=int(payload.get("quantity") or 1),
        category=str(payload.get("category", "OTHER")).upper(),
        reason=str(payload.get("reason", "")).strip(),
    )


# ── Maths ─────────────────────────────────────────────────────────────


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance in km."""
    radius = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dl / 2) ** 2
    return radius * 2 * math.asin(math.sqrt(a))


def _count_nights(check_in: str, check_out: str) -> int:
    """Number of nights between two YYYY-MM-DD strings (>=0)."""
    if not check_in or not check_out:
        return 0
    from datetime import date

    try:
        a = date.fromisoformat(check_in)
        b = date.fromisoformat(check_out)
    except ValueError:
        return 0
    return max((b - a).days, 0)


def _command_to_dict(cmd: TripDraftCommand) -> dict[str, Any]:
    """``asdict`` would coerce nested dataclasses to plain dicts — exactly what
    we need for SSE serialisation. The override here is purely for clarity."""
    return asdict(cmd)


__all__ = [
    "AccommodationDraft",
    "ActivityDraft",
    "BaggageDraft",
    "BudgetBreakdown",
    "FullPlanOrchestrator",
    "FullPlanRequest",
    "TransportLeg",
    "TripDraftCommand",
    "WeatherSummary",
]
