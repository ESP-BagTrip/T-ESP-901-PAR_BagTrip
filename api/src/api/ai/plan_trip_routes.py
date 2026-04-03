"""SSE endpoint for multi-agent trip planning."""

from __future__ import annotations

import asyncio
import contextlib
import json
from datetime import date, time, timedelta

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import AcceptPlanRequest, PlanTripRequest
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.config.env import settings
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.user import User
from src.services.plan_service import PlanService
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import logger
from src.utils.timeout import async_generator_with_timeout

router = APIRouter(prefix="/v1/ai", tags=["AI Trip Planning"])


def _sse_event(event: str, data: dict) -> str:
    """Format a Server-Sent Event string."""
    json_data = json.dumps(data, default=str, ensure_ascii=False)
    return f"event: {event}\ndata: {json_data}\n\n"


_QUICK_DESTINATIONS_PROMPT = """Suggest 3-4 travel destinations as a JSON object.
Consider the user's preferences and return ONLY a valid JSON object (no explanation):
{
  "destinations": [
    {"city": "...", "country": "...", "match_reason": "Short reason why this matches"}
  ]
}"""


async def _quick_destination_suggestions(state: dict) -> list[dict]:
    """Single LLM call to get destination suggestions — no tools, no ReAct."""
    from src.services.llm_service import LLMService

    parts = []
    if state.get("travel_types"):
        parts.append(f"Preferences: {state['travel_types']}")
    if state.get("budget_range") or state.get("budget_preset"):
        parts.append(f"Budget: {state.get('budget_preset') or state.get('budget_range')}")
    if state.get("duration_days"):
        parts.append(f"Duration: {state['duration_days']} days")
    if state.get("companions"):
        parts.append(f"Traveling with: {state['companions']}")
    if state.get("season"):
        parts.append(f"Season: {state['season']}")
    if state.get("constraints"):
        parts.append(f"Constraints: {state['constraints']}")
    if state.get("nb_travelers"):
        parts.append(f"Travelers: {state['nb_travelers']}")

    user_prompt = "\n".join(parts) if parts else "Suggest diverse travel destinations."

    llm_service = LLMService()
    result = await llm_service.acall_llm(_QUICK_DESTINATIONS_PROMPT, user_prompt)
    destinations = result.get("destinations", [])
    logger.info("Quick destination suggestions", {"count": len(destinations)})
    return destinations


async def _trip_plan_generator(request: PlanTripRequest, user_id: str, db: Session):
    """Async generator that runs the LangGraph pipeline and yields SSE events."""

    # Import here to avoid circular imports at module level
    from src.agent.graph import graph
    from src.agent.state import TripPlanState

    # Send initial progress
    yield _sse_event(
        "progress",
        {
            "phase": "starting",
            "message": "Starting trip planning...",
        },
    )

    # Build initial state
    initial_state: TripPlanState = {
        "travel_types": request.travelTypes or "",
        "budget_range": request.budgetRange or "",
        "duration_days": request.durationDays or 7,
        "companions": request.companions or "solo",
        "constraints": request.constraints or "",
        "departure_date": request.departureDate or "",
        "return_date": request.returnDate or "",
        "origin_city": request.originCity or "",
        "destination_city": request.destinationCity or "",
        "destination_iata": request.destinationIata or "",
        "travel_style": request.travelStyle or "",
        "season": request.season or "",
        "nb_travelers": request.nbTravelers or 1,
        "budget_preset": request.budgetPreset or "",
        "date_mode": request.dateMode or "",
        "events": [],
        "errors": [],
    }

    yield _sse_event(
        "progress",
        {
            "phase": "destination_research",
            "message": "Researching destinations...",
        },
    )

    # Fast path for destinations_only: single LLM call, no ReAct/tools
    if request.mode == "destinations_only":
        try:
            destinations = await _quick_destination_suggestions(initial_state)
            yield _sse_event("destinations", {"destinations": destinations})
            yield _sse_event(
                "complete",
                {"destinations": destinations, "mode": "destinations_only"},
            )
        except Exception as e:
            logger.error("Quick destination suggestions failed", {"error": str(e)})
            yield _sse_event("error", {"message": str(e)})
        yield _sse_event("done", {"status": "complete"})
        return

    # Select graph based on mode
    active_graph = graph

    # Run the graph with streaming
    last_heartbeat = asyncio.get_event_loop().time()
    sent_events = set()  # Track which event types we've already sent

    try:
        async for event in async_generator_with_timeout(
            active_graph.astream(initial_state, stream_mode="updates"),
            total_timeout_seconds=settings.GRAPH_TIMEOUT_SECONDS,
        ):
            # event is a dict: {node_name: state_update}
            for node_name, update in event.items():
                node_events = update.get("events", [])

                for evt in node_events:
                    event_type = evt.get("event", "")
                    event_data = evt.get("data", {})

                    # Avoid duplicate events
                    event_key = f"{event_type}:{node_name}"
                    if event_key in sent_events:
                        continue
                    sent_events.add(event_key)

                    yield _sse_event(event_type, event_data)

                    # Send progress for next phase
                    if event_type == "destinations":
                        yield _sse_event(
                            "progress",
                            {
                                "phase": "parallel_planning",
                                "message": "Planning activities, accommodation & packing...",
                            },
                        )
                    elif event_type in ("activities", "accommodations", "baggage"):
                        # Check if all 3 parallel nodes are done
                        parallel_done = {"activities", "accommodations", "baggage"}
                        done = {
                            e.split(":")[0] for e in sent_events if e.split(":")[0] in parallel_done
                        }
                        if done == parallel_done:
                            yield _sse_event(
                                "progress",
                                {
                                    "phase": "budget",
                                    "message": "Estimating budget...",
                                },
                            )

                # Log errors
                node_errors = update.get("errors", [])
                for err in node_errors:
                    logger.warn(f"Node {node_name} error: {err}")

            # Heartbeat every 15s
            now = asyncio.get_event_loop().time()
            if now - last_heartbeat > 15:
                yield _sse_event("heartbeat", {"ts": int(now)})
                last_heartbeat = now

        # Increment AI quota after successful completion
        try:
            PlanService.increment_ai_generation(
                db, db.query(User).filter(User.id == user_id).first()
            )
        except Exception as e:
            logger.warn(f"Failed to increment AI generation count: {e}")

    except TimeoutError:
        logger.error(
            "Trip planning graph timed out",
            {"timeout_seconds": settings.GRAPH_TIMEOUT_SECONDS},
        )
        yield _sse_event(
            "error",
            {"message": "Trip planning timed out. Please try again."},
        )
    except Exception as e:
        logger.error("Trip planning graph failed", {"error": str(e)})
        yield _sse_event("error", {"message": str(e)})

    # Final done signal
    yield _sse_event("done", {"status": "complete"})


@router.post("/plan-trip/stream")
async def plan_trip_stream(
    request: PlanTripRequest,
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Stream a multi-agent trip plan via SSE.

    Emits events: progress, destinations, activities, accommodations, baggage,
    budget, complete, heartbeat, error, done.
    """
    logger.info("Starting plan-trip/stream", {"user_id": str(current_user.id)})

    return StreamingResponse(
        _trip_plan_generator(request, str(current_user.id), db),
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


@router.post("/plan-trip/accept")
async def accept_plan(
    request: AcceptPlanRequest,
    raw_request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
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

        trip = TripsService.create_trip(
            db=db,
            user_id=current_user.id,
            title=f"Voyage à {destination_name}",
            origin_iata=origin_iata_value,
            destination_iata=destination_iata_value,
            destination_name=destination_name,
            description=suggestion.get("description"),
            budget_total=suggestion.get("budgetEur"),
            start_date=request.startDate,
            end_date=request.endDate,
            origin="AI",
            cover_image_url=cover_image_url,
        )

        # --- Create activities with intelligent scheduling ---
        activities_data = suggestion.get("activities", [])
        if activities_data:
            trip_start = None
            if request.startDate:
                with contextlib.suppress(ValueError):
                    trip_start = date.fromisoformat(request.startDate)

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
