"""HTTP routes for multi-agent trip planning.

The SSE orchestration now lives in `TripPlannerService.stream_plan()` — this
file is a thin HTTP adapter that turns the request into an `AsyncIterator[str]`
and wraps it in a `StreamingResponse`. LangGraph imports, state assembly,
event dedup and heartbeat logic all moved to the service.
"""

from __future__ import annotations

import contextlib
from datetime import date, time, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import AcceptPlanRequest, PlanTripRequest
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.integrations.aviation_data.service import AviationDataService
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.manual_flight import ManualFlight
from src.models.user import User
from src.services.trip_planner_service import TripPlannerService
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import logger

router = APIRouter(prefix="/v1/ai", tags=["AI Trip Planning"])

# ── IATA resolution (offline, deterministic) ──────────────────────────

_aviation = AviationDataService()


def _resolve_iata(city_name: str) -> str | None:
    """Resolve a city name to its primary IATA airport code (offline).

    Uses airportsdata — no API call, no LLM dependency.
    Returns None if the city can't be matched.
    """
    if not city_name or not city_name.strip():
        return None
    try:
        results = _aviation.search_by_keyword(city_name.strip(), sub_type="CITY,AIRPORT", limit=1)
        if results:
            loc = results[0]
            return loc.iataCode or (loc.address.cityCode if loc.address else None)
    except Exception:
        pass
    return None


@router.post("/plan-trip/stream")
async def plan_trip_stream(
    request: PlanTripRequest,
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Stream a multi-agent trip plan via SSE.

    Emits events: progress, destinations, activities, accommodations, baggage,
    budget, complete, heartbeat, error, done.
    """
    logger.info("Starting plan-trip/stream", {"user_id": str(current_user.id)})

    return StreamingResponse(
        TripPlannerService.stream_plan(request, str(current_user.id), db),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


TIME_OF_DAY_MAP = {
    "morning": time(9, 0),
    "afternoon": time(14, 0),
    "evening": time(19, 0),
}

_DEFAULT_BAGGAGE_I18N = {
    "en": [
        {"name": "Passport", "category": "DOCUMENTS", "quantity": 1},
        {"name": "Travel adapter", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Sunscreen", "category": "TOILETRIES", "quantity": 1},
        {"name": "First aid kit", "category": "HEALTH", "quantity": 1},
        {"name": "Phone charger", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Change of clothes", "category": "CLOTHING", "quantity": 3},
    ],
    "fr": [
        {"name": "Passeport", "category": "DOCUMENTS", "quantity": 1},
        {"name": "Adaptateur de voyage", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Creme solaire", "category": "TOILETRIES", "quantity": 1},
        {"name": "Trousse de premiers secours", "category": "HEALTH", "quantity": 1},
        {"name": "Chargeur de telephone", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Vetements de rechange", "category": "CLOTHING", "quantity": 3},
    ],
}


def _get_default_baggage(lang: str) -> list[dict]:
    return _DEFAULT_BAGGAGE_I18N.get(lang, _DEFAULT_BAGGAGE_I18N["en"])


def _parse_flight_route(route: str) -> tuple[str | None, str | None]:
    """Extract departure and arrival IATA codes from a route string.

    Handles formats like "CDG → JTR", "CDG -> JTR", "CDG - JTR".
    """
    import re

    codes = re.findall(r"\b([A-Z]{3})\b", route.upper())
    if len(codes) >= 2:
        return codes[0], codes[1]
    if len(codes) == 1:
        return codes[0], None
    return None, None


@router.post("/plan-trip/accept")
async def accept_plan(
    request: AcceptPlanRequest,
    raw_request: Request,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Create a DRAFT trip from the multi-agent plan.

    Supports ``selectedDestinationIndex`` to pick an alternative destination,
    AI-generated baggage items (with i18n fallback), IATA code persistence,
    and intelligent ``suggested_day`` + ``time_of_day`` activity scheduling.
    """
    try:
        suggestion = request.suggestion

        # --- Resolve destination (primary or alternative) ---
        dest_info = suggestion.get("destination", {})
        if isinstance(dest_info, dict):
            dest_city = dest_info.get("city", "")
            dest_country = dest_info.get("country", "")
            destination_name = f"{dest_city}, {dest_country}" if dest_country else dest_city
            destination_iata_value = dest_info.get("iata")
        else:
            # Backward compat: destination may be a plain string
            destination_name = str(dest_info) if dest_info else "Inconnu"
            destination_iata_value = None

        origin_iata_value = suggestion.get("origin_iata")

        # ── Server-side IATA resolution (don't rely on LLM) ──
        if not origin_iata_value and request.originCity:
            origin_iata_value = _resolve_iata(request.originCity)
            if origin_iata_value:
                logger.info(f"Resolved origin IATA: {request.originCity} → {origin_iata_value}")
        if not destination_iata_value and destination_name:
            destination_iata_value = _resolve_iata(destination_name.split(",")[0].strip())
            if destination_iata_value:
                logger.info(
                    f"Resolved destination IATA: {destination_name} → {destination_iata_value}"
                )

        # Handle alternative destination selection
        idx = request.selectedDestinationIndex
        alternatives = suggestion.get("alternatives", [])
        if idx > 0 and alternatives:
            alt_idx = idx - 1  # alternatives = destinations[1:]
            if alt_idx < len(alternatives):
                chosen = alternatives[alt_idx]
                dest_city = chosen.get("city", "")
                dest_country = chosen.get("country", "")
                destination_name = f"{dest_city}, {dest_country}" if dest_country else dest_city
                destination_iata_value = chosen.get("iata")

        # Auto-fetch cover image from Unsplash
        from src.integrations.unsplash import unsplash_client

        cover_image_url = await unsplash_client.fetch_cover_image(destination_name)
        if not cover_image_url:
            cover_image_url = unsplash_client.get_fallback_url(destination_name)

        # Resolve dates (safety net for month/flexible modes)
        start_date_value = request.startDate
        end_date_value = request.endDate
        if not start_date_value or not end_date_value:
            duration = suggestion.get("durationDays", 7) or 7
            start_date_value = start_date_value or str(date.today() + timedelta(days=30))
            end_date_value = end_date_value or str(
                date.fromisoformat(start_date_value) + timedelta(days=duration)
            )

        trip = TripsService.create_trip(
            db=db,
            user_id=current_user.id,
            title=f"Voyage à {destination_name}",
            origin_iata=origin_iata_value,
            destination_iata=destination_iata_value,
            destination_name=destination_name,
            description=suggestion.get("description"),
            budget_total=suggestion.get("budgetEur"),
            start_date=start_date_value,
            end_date=end_date_value,
            origin="AI",
            cover_image_url=cover_image_url,
            date_mode=request.dateMode or "EXACT",
        )

        # --- Create activities with intelligent scheduling ---
        activities_data = suggestion.get("activities", [])
        if activities_data:
            trip_start = None
            if start_date_value:
                with contextlib.suppress(ValueError):
                    trip_start = date.fromisoformat(start_date_value)

            duration_days = suggestion.get("durationDays", len(activities_data)) or len(
                activities_data
            )

            for i, act in enumerate(activities_data):
                suggested_day = act.get("suggested_day")
                if suggested_day and isinstance(suggested_day, int):
                    day_offset = (suggested_day - 1) % max(duration_days, 1)
                else:
                    day_offset = i % max(duration_days, 1)

                activity_date = (
                    trip_start + timedelta(days=day_offset)
                    if trip_start
                    else date.today() + timedelta(days=day_offset)
                )

                start_time_value = TIME_OF_DAY_MAP.get(act.get("time_of_day", ""))

                activity = Activity(
                    trip_id=trip.id,
                    title=act.get("title", f"Activite {i + 1}"),
                    description=act.get("description", ""),
                    date=activity_date,
                    start_time=start_time_value,
                    location=act.get("location"),
                    category=act.get("category", "OTHER"),
                    estimated_cost=act.get("estimatedCost"),
                    validation_status="SUGGESTED",
                )
                db.add(activity)

        # --- Persist accommodations ---
        accommodations_data = suggestion.get("accommodations", [])
        for acc in accommodations_data:
            accommodation = Accommodation(
                trip_id=trip.id,
                name=acc.get("name", "Hébergement"),
                address=acc.get("address"),
                price_per_night=acc.get("price_per_night"),
                currency=acc.get("currency", "EUR"),
                notes=acc.get("notes"),
            )
            db.add(accommodation)

        # --- Persist AI-suggested flight ---
        flight_data = suggestion.get("flight")
        if flight_data and isinstance(flight_data, dict):
            dep_airport, arr_airport = _parse_flight_route(flight_data.get("route", ""))
            flight = ManualFlight(
                trip_id=trip.id,
                flight_number="TBD",
                departure_airport=dep_airport,
                arrival_airport=arr_airport,
                price=flight_data.get("price"),
                currency="EUR",
                notes=f"AI suggestion ({flight_data.get('source', 'estimated')})",
                flight_type="AI_SUGGESTED",
            )
            db.add(flight)

        # --- Persist baggage items (AI-generated or i18n defaults) ---
        ai_baggage = suggestion.get("baggage", [])
        if not ai_baggage:
            lang = (raw_request.headers.get("accept-language") or "fr")[:2]
            ai_baggage = _get_default_baggage(lang)

        for bag in ai_baggage:
            item = BaggageItem(
                trip_id=trip.id,
                name=bag.get("name", "Item"),
                quantity=bag.get("quantity", 1),
                category=bag.get("category", "OTHER"),
            )
            db.add(item)

        db.commit()
        db.refresh(trip)

        return {
            "id": str(trip.id),
            "title": trip.title,
            "status": trip.status,
            "destinationName": trip.destination_name,
            "description": trip.description,
            "budgetTotal": trip.budget_total,
            "origin": trip.origin,
            "startDate": str(trip.start_date) if trip.start_date else None,
            "endDate": str(trip.end_date) if trip.end_date else None,
        }
    except AppError as e:
        raise create_http_exception(e) from e
