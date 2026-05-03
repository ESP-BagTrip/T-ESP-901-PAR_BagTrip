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
from typing import Any

from sqlalchemy.orm import Session

from src.agent.runtime_budget import BudgetExceeded
from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.config.env import settings
from src.integrations.unsplash import unsplash_client
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.logger import logger
from src.utils.timeout import async_generator_with_timeout


def _sse(event: str, data: dict) -> str:
    """Format a Server-Sent Event line."""
    return f"event: {event}\ndata: {json.dumps(data, default=str, ensure_ascii=False)}\n\n"


_QUICK_DESTINATION_LABELS: dict[str, dict[str, str]] = {
    "en": {
        "travel_types": "Preferences",
        "budget_preset": "Budget",
        "duration_days": "Duration",
        "duration_unit": "days",
        "companions": "Traveling with",
        "season": "Season",
        "constraints": "Constraints",
        "nb_travelers": "Travelers",
        "fallback": "Suggest diverse travel destinations.",
    },
    "fr": {
        "travel_types": "Préférences",
        "budget_preset": "Budget",
        "duration_days": "Durée",
        "duration_unit": "jours",
        "companions": "Accompagné de",
        "season": "Saison",
        "constraints": "Contraintes",
        "nb_travelers": "Voyageurs",
        "fallback": "Propose des destinations de voyage variées.",
    },
}


async def _quick_destination_suggestions(state: Any) -> list[dict]:
    """Generate destination suggestions for the wizard's step 3.

    Tries the Amadeus-first ``inspire_then_rank`` pipeline first
    (real flight inspiration + Amadeus POIs + Open-Meteo weather +
    LLM ranking only). Falls back to the legacy LLM-only path when
    the pipeline cannot proceed (no origin city, Amadeus down, …) so
    the wizard never ends up empty-handed.
    """
    from src.services.destination_inspiration_service import inspire_then_rank
    from src.utils.locale import normalize_locale

    locale = normalize_locale(state.get("locale"))

    amadeus_first = await inspire_then_rank(state)
    if amadeus_first is not None:
        logger.info(
            "Quick destination suggestions (amadeus_first)",
            {"count": len(amadeus_first), "locale": locale},
        )
        return amadeus_first

    # ── Legacy fallback path — keeps the wizard producing something even
    # when Amadeus inspiration is unavailable or the user did not provide
    # an origin city.
    return await _legacy_llm_only_destinations(state, locale)


async def _legacy_llm_only_destinations(state: Any, locale: str) -> list[dict]:
    """Single LLM call (no ReAct, no tools) — pre-SMP-324 behavior."""
    from src.agent.prompts import render
    from src.services.llm_service import LLMService

    labels = _QUICK_DESTINATION_LABELS.get(locale, _QUICK_DESTINATION_LABELS["en"])

    system_prompt = render("destination_quick", locale=locale)

    parts: list[str] = []
    if state.get("travel_types"):
        parts.append(f"{labels['travel_types']}: {state['travel_types']}")
    if state.get("budget_preset"):
        parts.append(f"{labels['budget_preset']}: {state['budget_preset']}")
    if state.get("duration_days"):
        parts.append(
            f"{labels['duration_days']}: {state['duration_days']} {labels['duration_unit']}"
        )
    if state.get("companions"):
        parts.append(f"{labels['companions']}: {state['companions']}")
    if state.get("season"):
        parts.append(f"{labels['season']}: {state['season']}")
    if state.get("constraints"):
        parts.append(f"{labels['constraints']}: {state['constraints']}")
    if state.get("nb_travelers"):
        parts.append(f"{labels['nb_travelers']}: {state['nb_travelers']}")

    user_prompt = "\n".join(parts) if parts else labels["fallback"]

    llm_service = LLMService()
    result = await llm_service.acall_llm(system_prompt, user_prompt)
    destinations = result.get("destinations", [])
    logger.info(
        "Quick destination suggestions (llm_fallback)",
        {"count": len(destinations), "locale": locale},
    )
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
        # Topic 01 — numeric target the user committed to in the wizard.
        # Threaded into the agent state so nodes can render it in prompts
        # and `_compute_fallback_budget` can use it as a sanity ceiling.
        "target_budget": request.targetBudget,
        "date_mode": request.dateMode or "",
        "events": [],
        "errors": [],
        # Budget tracking — `time.monotonic()` is strictly increasing so we
        # don't need tz-aware math. Consumed seconds accrues as each node
        # finishes via `src.agent.runtime_budget.track`.
        "budget_deadline_monotonic": time.monotonic() + settings.GRAPH_TIMEOUT_SECONDS,
        "budget_consumed_seconds": 0.0,
        # Locale picked up by every node's `prompts.render(name, locale=...)` call.
        "locale": request.locale or "en",
    }


async def _enrich_destinations_with_images(destinations: list[dict]) -> list[dict]:
    """Fetch Unsplash cover images for each destination (parallel, with fallback)."""

    async def _fetch_one(dest: dict) -> dict:
        city = dest.get("city", "")
        if not city:
            return dest
        country = dest.get("country", "")
        query = f"{city}, {country}" if country else city
        url = await unsplash_client.fetch_cover_image(query)
        if not url:
            url = unsplash_client.get_fallback_url(query)
        dest["image_url"] = url
        return dest

    await asyncio.gather(*[_fetch_one(d) for d in destinations])
    return destinations


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
                    await _enrich_destinations_with_images(destinations)
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
        initial_state: Any,
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

                    # Enrich destinations with Unsplash cover images
                    if event_type == "destinations":
                        dests = event_data.get("destinations", [])
                        if dests:
                            await _enrich_destinations_with_images(dests)

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
