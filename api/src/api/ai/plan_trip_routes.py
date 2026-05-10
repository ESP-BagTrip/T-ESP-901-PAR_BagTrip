"""HTTP route for the multi-agent trip planner.

The single route is a thin SSE adapter — :class:`TripPlannerService.stream_plan`
owns the whole pipeline (W1 inspire / W2 full plan), persists server-side
when the run succeeds and emits a ``complete`` event with the resulting
``tripId``. The legacy ``POST /v1/ai/plan-trip/accept`` route was removed
in SMP-325 along with :class:`PlanAcceptanceService` — the wizard no
longer round-trips the plan back to confirm a draft.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.models.user import User
from src.services.trip_planner_service import TripPlannerService
from src.utils.logger import logger

router = APIRouter(prefix="/v1/ai", tags=["AI Trip Planning"])


@router.post("/plan-trip/stream")
async def plan_trip_stream(
    request: PlanTripRequest,
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Stream a multi-agent trip plan via SSE.

    Emits events: ``progress``, ``destinations``, ``weather``,
    ``activities``, ``accommodations``, ``transport``, ``baggage``,
    ``budget``, ``warning``, ``error``, ``complete`` (with ``tripId``)
    and ``done``.
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
