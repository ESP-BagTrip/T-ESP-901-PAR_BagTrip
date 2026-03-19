"""SSE endpoint for multi-agent trip planning."""

from __future__ import annotations

import asyncio
import json

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.logger import logger

router = APIRouter(prefix="/v1/ai", tags=["AI Trip Planning"])


def _sse_event(event: str, data: dict) -> str:
    """Format a Server-Sent Event string."""
    json_data = json.dumps(data, default=str, ensure_ascii=False)
    return f"event: {event}\ndata: {json_data}\n\n"


async def _trip_plan_generator(request: PlanTripRequest, user_id: str, db: Session):
    """Async generator that runs the LangGraph pipeline and yields SSE events."""

    # Import here to avoid circular imports at module level
    from src.agent.graph import graph
    from src.agent.state import TripPlanState

    # Send initial progress
    yield _sse_event("progress", {
        "phase": "starting",
        "message": "Starting trip planning...",
    })

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
        "events": [],
        "errors": [],
    }

    yield _sse_event("progress", {
        "phase": "destination_research",
        "message": "Researching destinations...",
    })

    # Run the graph with streaming
    last_heartbeat = asyncio.get_event_loop().time()
    sent_events = set()  # Track which event types we've already sent

    try:
        async for event in graph.astream(initial_state, stream_mode="updates"):
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
                        yield _sse_event("progress", {
                            "phase": "parallel_planning",
                            "message": "Planning activities, accommodation & packing...",
                        })
                    elif event_type in ("activities", "accommodations", "baggage"):
                        # Check if all 3 parallel nodes are done
                        parallel_done = {"activities", "accommodations", "baggage"}
                        done = {e.split(":")[0] for e in sent_events if e.split(":")[0] in parallel_done}
                        if done == parallel_done:
                            yield _sse_event("progress", {
                                "phase": "budget",
                                "message": "Estimating budget...",
                            })

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
            PlanService.increment_ai_generation(db, db.query(User).filter(User.id == user_id).first())
        except Exception as e:
            logger.warn(f"Failed to increment AI generation count: {e}")

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
