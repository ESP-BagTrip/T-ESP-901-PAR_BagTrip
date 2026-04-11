"""SSE trip-planning orchestration — extracted from `plan_trip_routes.py`.

The LangGraph streaming logic used to live inline in the route handler. That
was a CLAUDE.md violation ("routes are HTTP-only, pas d'orchestration LangGraph
inline") and also made the route impossible to test without spinning up the
full FastAPI stack. This service is now the single owner of:

- State assembly from the incoming `PlanTripRequest`
- Mode dispatching (`destinations_only` fast path vs. full ReAct graph)
- SSE event dedup, heartbeat, and timeout
- AI quota increment on success
- Guaranteed cleanup via `try / finally`

The route is a pass-through: it wraps `stream_plan()` in an `EventSourceResponse`
/`StreamingResponse` and nothing else.
"""

from __future__ import annotations

import asyncio
import json
import time
from collections.abc import AsyncIterator
from datetime import date, timedelta

from sqlalchemy.orm import Session

from src.agent.budget import BudgetExceeded
from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.config.env import settings
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.logger import logger
from src.utils.timeout import async_generator_with_timeout


def _sse(event: str, data: dict) -> str:
    """Format a Server-Sent Event line."""
    return f"event: {event}\ndata: {json.dumps(data, default=str, ensure_ascii=False)}\n\n"


async def _quick_destination_suggestions(state: dict) -> list[dict]:
    """Single LLM call (no ReAct, no tools) for `destinations_only` mode."""
    # Local import: LLMService drags optional deps we don't want at module load.
    from src.services.llm_service import LLMService

    prompt = """Suggest 3-4 travel destinations as a JSON object.
Consider the user's preferences and return ONLY a valid JSON object (no explanation):
{
  "destinations": [
    {"city": "...", "country": "...", "match_reason": "Short reason why this matches"}
  ]
}"""

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
    result = await llm_service.acall_llm(prompt, user_prompt)
    destinations = result.get("destinations", [])
    logger.info("Quick destination suggestions", {"count": len(destinations)})
    return destinations


def _build_initial_state(request: PlanTripRequest) -> dict:
    """Build the LangGraph `TripPlanState` seed from an incoming request."""
    dep_date = request.departureDate or ""
    ret_date = request.returnDate or ""
    duration = request.durationDays or 7

    # Safety net: derive dates for month/flexible modes if client didn't send them.
    if not dep_date or not ret_date:
        if request.preferredMonth and request.preferredYear:
            start = date(request.preferredYear, request.preferredMonth, 15)
            dep_date = str(start)
            ret_date = str(start + timedelta(days=duration))
        elif request.dateMode in ("month", "flexible"):
            start = date.today() + timedelta(days=30)
            dep_date = str(start)
            ret_date = str(start + timedelta(days=duration))

    return {
        "travel_types": request.travelTypes or "",
        "budget_range": request.budgetRange or "",
        "duration_days": duration,
        "companions": request.companions or "solo",
        "constraints": request.constraints or "",
        "departure_date": dep_date,
        "return_date": ret_date,
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
        # Budget tracking — `time.monotonic()` is strictly increasing so we
        # don't need tz-aware math. Consumed seconds accrues as each node
        # finishes via `src.agent.budget.track`.
        "budget_deadline_monotonic": time.monotonic() + settings.GRAPH_TIMEOUT_SECONDS,
        "budget_consumed_seconds": 0.0,
    }


class TripPlannerService:
    """SSE trip-planning orchestrator."""

    @staticmethod
    async def stream_plan(
        request: PlanTripRequest,
        user_id: str,
        db: Session,
    ) -> AsyncIterator[str]:
        """Yield SSE event strings for a single trip-plan request.

        This is the whole LangGraph pipeline from prompt state to completion,
        wrapped in a ``try/finally`` so cleanup runs even if the client
        disconnects or the graph raises.

        Events emitted (in rough order):
            ``progress`` → ``destinations`` → ``progress`` →
            ``activities`` / ``accommodations`` / ``baggage`` (parallel) →
            ``progress`` (budget) → ``budget`` → ``complete`` → ``done``.
            Plus ``heartbeat`` every 15 s and ``error`` on failure paths.
        """
        # Local import — the graph drags LangChain state machinery we don't
        # want loaded at module import time (slower boot + circular risk).
        from src.agent.graph import graph
        from src.agent.state import TripPlanState

        yield _sse("progress", {"phase": "starting", "message": "Starting trip planning..."})

        initial_state: TripPlanState = _build_initial_state(request)  # type: ignore[assignment]

        yield _sse(
            "progress",
            {"phase": "destination_research", "message": "Researching destinations..."},
        )

        try:
            # Fast path — destinations_only mode skips the full graph entirely.
            if request.mode == "destinations_only":
                try:
                    destinations = await _quick_destination_suggestions(initial_state)
                    yield _sse("destinations", {"destinations": destinations})
                    yield _sse(
                        "complete",
                        {"destinations": destinations, "mode": "destinations_only"},
                    )
                except Exception as exc:
                    logger.error("Quick destination suggestions failed", {"error": str(exc)})
                    yield _sse("error", {"message": str(exc)})
                return

            async for event in TripPlannerService._stream_graph(graph, initial_state):
                yield event

            # Successful completion → increment quota (best-effort — a failed
            # counter update must not prevent the user from receiving events).
            try:
                user = db.query(User).filter(User.id == user_id).first()
                if user is not None:
                    PlanService.increment_ai_generation(db, user)
            except Exception as exc:
                logger.warn(f"Failed to increment AI generation count: {exc}")

        except BudgetExceeded as exc:
            logger.warn(
                "Trip planning graph exhausted its time budget",
                {"timeout_seconds": settings.GRAPH_TIMEOUT_SECONDS, "error": str(exc)},
            )
            yield _sse(
                "error",
                {
                    "message": "Trip planning exceeded its time budget. Please try again.",
                    "code": "GRAPH_BUDGET_EXHAUSTED",
                },
            )
        except TimeoutError:
            logger.error(
                "Trip planning graph timed out",
                {"timeout_seconds": settings.GRAPH_TIMEOUT_SECONDS},
            )
            yield _sse("error", {"message": "Trip planning timed out. Please try again."})
        except Exception as exc:
            logger.error("Trip planning graph failed", {"error": str(exc)})
            yield _sse("error", {"message": str(exc)})
        finally:
            # Always send the done signal so the client can close the SSE
            # connection cleanly even on errors.
            yield _sse("done", {"status": "complete"})

    @staticmethod
    async def _stream_graph(
        graph_obj,
        initial_state: dict,
    ) -> AsyncIterator[str]:
        """Iterate the LangGraph stream, dedup events, emit SSE + heartbeats."""
        last_heartbeat = asyncio.get_event_loop().time()
        sent_events: set[str] = set()  # Track which event types we've already sent

        async for event in async_generator_with_timeout(
            graph_obj.astream(initial_state, stream_mode="updates"),
            total_timeout_seconds=settings.GRAPH_TIMEOUT_SECONDS,
        ):
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

                    yield _sse(event_type, event_data)

                    # Send progress for next phase
                    if event_type == "destinations":
                        yield _sse(
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
                            yield _sse(
                                "progress",
                                {"phase": "budget", "message": "Estimating budget..."},
                            )

                node_errors = update.get("errors", [])
                for err in node_errors:
                    logger.warn(f"Node {node_name} error: {err}")

            # Heartbeat every 15s
            now = asyncio.get_event_loop().time()
            if now - last_heartbeat > 15:
                yield _sse("heartbeat", {"ts": int(now)})
                last_heartbeat = now
