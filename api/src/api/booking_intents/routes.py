"""Routes pour les booking intents."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.booking_intents.schemas import (
    BookingIntentCreateRequest,
    BookingIntentResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.booking_intents_service import BookingIntentsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Booking Intents"])


@router.post(
    "/{tripId}/booking-intents",
    response_model=BookingIntentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create booking intent",
    description="Create a booking intent for a selected offer",
)
async def create_booking_intent(
    request: BookingIntentCreateRequest,
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Créer un booking intent selon PLAN.md."""
    try:
        booking_intent = BookingIntentsService.create_intent(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
            type=request.type,
            flight_offer_id=request.flightOfferId,
            hotel_offer_id=request.hotelOfferId,
        )

        return BookingIntentResponse(
            id=booking_intent.id,
            type=booking_intent.type,
            status=booking_intent.status,
            amount=float(booking_intent.amount),
            currency=booking_intent.currency,
            selectedOfferId=booking_intent.selected_offer_id,
        )
    except AppError as e:
        raise create_http_exception(e) from e
