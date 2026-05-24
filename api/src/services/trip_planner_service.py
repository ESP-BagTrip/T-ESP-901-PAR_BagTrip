"""SSE trip-planning orchestration.

The route handler stays HTTP-only. This service owns the whole stream
lifecycle:

- Mode dispatching (W1 ``destinations_only`` → :class:`InspireOrchestrator`,
  W2 full plan → :class:`FullPlanOrchestrator`).
- SSE serialisation, heartbeat, and the terminal ``done`` event.
- Server-side persistence of W2 drafts via :class:`PlanDraftService`,
  the deterministic feasibility pass and the AI-quota increment.
- Guaranteed cleanup via ``try / finally``.
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator

from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.models.user import User
from src.services.feasibility_pass import schedule_activities
from src.services.full_plan_orchestrator import (
    FullPlanOrchestrator,
    FullPlanRequest,
    TripDraftCommand,
)
from src.services.inspire_orchestrator import InspireOrchestrator, InspireRequest
from src.services.plan_draft_service import PlanDraftService
from src.services.plan_service import PlanService
from src.utils.logger import logger


def _sse(event: str, data: dict) -> str:
    """Format a Server-Sent Event line."""
    return f"event: {event}\ndata: {json.dumps(data, default=str, ensure_ascii=False)}\n\n"


def _to_inspire_request(request: PlanTripRequest) -> InspireRequest:
    """Map the wizard payload onto the inspire orchestrator's input."""
    return InspireRequest(
        origin_city=request.originCity or "",
        travel_types=request.travelTypes or "",
        duration_days=request.durationDays or 7,
        departure_date=request.departureDate or "",
        return_date=request.returnDate or "",
        season=request.season or "",
        companions=request.companions or "solo",
        constraints=request.constraints or "",
        budget_preset=request.budgetPreset or "",
        nb_travelers=request.nbTravelers or 1,
        locale=request.locale or "en",
    )


def _to_full_plan_request(request: PlanTripRequest) -> FullPlanRequest:
    """Map the wizard payload onto the W2 full-plan orchestrator's input."""
    return FullPlanRequest(
        origin_city=request.originCity or "",
        destination_city=request.destinationCity or "",
        destination_iata=request.destinationIata or "",
        travel_types=request.travelTypes or "",
        duration_days=request.durationDays or 7,
        departure_date=request.departureDate or "",
        return_date=request.returnDate or "",
        season=request.season or "",
        companions=request.companions or "solo",
        constraints=request.constraints or "",
        budget_preset=request.budgetPreset or "",
        nb_travelers=request.nbTravelers or 1,
        target_budget=request.targetBudget,
        locale=request.locale or "en",
    )


def _trip_draft_from_dict(payload: dict) -> TripDraftCommand:
    """Rebuild a :class:`TripDraftCommand` from the dict shipped in ``complete``.

    The orchestrator yields ``complete {"trip_draft": asdict(cmd)}`` so the
    SSE payload is JSON-serialisable. The persistence layer expects the
    typed dataclass, so we round-trip here through the same builders the
    orchestrator uses internally — that keeps the contract honest if
    fields are added later.
    """
    from src.services.full_plan_orchestrator import (
        AccommodationDraft,
        ActivityDraft,
        BaggageDraft,
        BudgetBreakdown,
        TransportLeg,
        WeatherSummary,
    )

    weather_payload = payload.get("weather")
    weather = WeatherSummary(**weather_payload) if weather_payload else None
    return TripDraftCommand(
        origin_iata=payload["origin_iata"],
        origin_city=payload["origin_city"],
        destination_iata=payload["destination_iata"],
        destination_city=payload["destination_city"],
        destination_country=payload["destination_country"],
        destination_country_code=payload["destination_country_code"],
        destination_lat=payload["destination_lat"],
        destination_lon=payload["destination_lon"],
        start_date=payload["start_date"],
        end_date=payload["end_date"],
        duration_days=payload["duration_days"],
        nb_travelers=payload["nb_travelers"],
        target_budget=payload.get("target_budget"),
        locale=payload["locale"],
        cover_image_url=payload.get("cover_image_url"),
        weather=weather,
        activities=[ActivityDraft(**a) for a in payload.get("activities", [])],
        accommodations=[AccommodationDraft(**a) for a in payload.get("accommodations", [])],
        transport=[TransportLeg(**t) for t in payload.get("transport", [])],
        baggage=[BaggageDraft(**b) for b in payload.get("baggage", [])],
        budget=BudgetBreakdown(**payload.get("budget", {})),
    )


class TripPlannerService:
    """SSE trip-planning orchestrator."""

    @staticmethod
    async def stream_plan(
        request: PlanTripRequest,
        user_id: str,
        db: Session,
    ) -> AsyncIterator[str]:
        """Yield SSE event strings for a single trip-plan request.

        - ``mode="destinations_only"`` → :class:`InspireOrchestrator`,
          forwarded verbatim. Nothing is persisted server-side; the
          wizard step that follows lets the user pick a destination
          before the W2 path.
        - default / ``mode="full"`` → :class:`FullPlanOrchestrator`
          followed by the deterministic feasibility pass and a server-
          side persist via :class:`PlanDraftService`. The orchestrator's
          own ``complete`` event is intentionally swallowed; we re-emit
          a richer one with the persisted ``tripId``.
        """
        try:
            if request.mode == "destinations_only":
                inspire_req = _to_inspire_request(request)
                async for ev_type, ev_data in InspireOrchestrator.stream(inspire_req):
                    yield _sse(ev_type, ev_data)
                return

            full_req = _to_full_plan_request(request)
            trip_draft_payload: dict | None = None
            async for ev_type, ev_data in FullPlanOrchestrator.stream(full_req):
                if ev_type == "complete":
                    # Capture the DTO; we re-emit ``complete`` after the
                    # feasibility pass + persistence so the client gets a
                    # ``tripId`` it can link to.
                    trip_draft_payload = ev_data.get("trip_draft")
                    continue
                yield _sse(ev_type, ev_data)

            if trip_draft_payload is None:
                # The orchestrator surfaced a fatal ``error`` event before
                # producing a draft; the ``finally`` below closes the
                # stream with ``done`` and we exit cleanly.
                return

            cmd = _trip_draft_from_dict(trip_draft_payload)
            cmd.activities = schedule_activities(cmd)
            user = db.query(User).filter(User.id == user_id).first()
            if user is None:
                raise RuntimeError(f"user {user_id} disappeared mid-stream")
            trip = PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
            yield _sse(
                "complete",
                {
                    "tripId": str(trip.id),
                    "status": str(trip.status),
                    "tripDraft": trip_draft_payload,
                },
            )
            try:
                PlanService.increment_ai_generation(db, user)
            except Exception as exc:
                logger.warn(f"Failed to increment AI generation count: {exc}")

        except Exception as exc:
            logger.error("Trip planning failed", {"error": str(exc)})
            yield _sse("error", {"message": str(exc)})
        finally:
            yield _sse("done", {"status": "complete"})
