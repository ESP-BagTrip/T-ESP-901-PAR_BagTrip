"""HTTP routes for multi-agent trip planning.

SSE orchestration lives in :class:`TripPlannerService`; trip creation from an
accepted plan lives in :class:`PlanAcceptanceService`. This file stays a thin
HTTP adapter.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import AcceptPlanRequest, PlanTripRequest
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.models.user import User
from src.services.plan_acceptance_service import PlanAcceptanceService
from src.services.trip_planner_service import TripPlannerService
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import logger

router = APIRouter(prefix="/v1/ai", tags=["AI Trip Planning"])


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


@router.post("/plan-trip/accept")
async def accept_plan(
    request: AcceptPlanRequest,
    raw_request: Request,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Create a DRAFT trip from the multi-agent plan.

    Delegates the whole flow to :meth:`PlanAcceptanceService.create_trip_from_plan`.
    """
    try:
        return await PlanAcceptanceService.create_trip_from_plan(
            db=db,
            user=current_user,
            request=request,
            accept_language=raw_request.headers.get("accept-language") or "fr",
        )
    except AppError as e:
        raise create_http_exception(e) from e
