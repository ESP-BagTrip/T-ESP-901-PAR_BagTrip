"""HTTP routes for multi-agent trip planning.

SSE orchestration lives in :class:`TripPlannerService`. The legacy
``POST /v1/ai/plan-trip/accept`` endpoint was removed in SMP-324: the
backend now persists the draft directly during the SSE pipeline and
ships its ``tripId`` in the ``complete`` event. Confirming the trip
is just ``PATCH /v1/trips/{id}/status`` with ``{"status": "PLANNED"}``;
discarding it is ``DELETE /v1/trips/{id}``.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Request
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
    raw_request: Request,
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Stream a multi-agent trip plan via SSE.

    Emits events: progress, destinations, activities, accommodations, baggage,
    budget, complete (with ``tripId``), heartbeat, error, done.
    """
    logger.info("Starting plan-trip/stream", {"user_id": str(current_user.id)})

    accept_language = raw_request.headers.get("accept-language") or "fr"

    return StreamingResponse(
        TripPlannerService.stream_plan(
            request,
            str(current_user.id),
            db,
            accept_language=accept_language,
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
