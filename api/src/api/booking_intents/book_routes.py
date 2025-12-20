"""Routes pour le booking (book endpoint)."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.booking_intents.schemas import (
    BookingIntentBookRequestFlight,
    BookingIntentBookRequestHotel,
    BookingIntentBookResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.booking_orchestrator_service import BookingOrchestratorService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/booking-intents", tags=["Booking Intents"])


@router.post(
    "/{intentId}/book",
    response_model=BookingIntentBookResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Book flight or hotel",
    description="Book a flight or hotel through Amadeus (requires AUTHORIZED status)",
)
async def book(
    request: BookingIntentBookRequestFlight | BookingIntentBookRequestHotel,
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Book selon PLAN.md."""
    try:
        booking_intent = await BookingOrchestratorService.book(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
            traveler_ids=request.travelerIds
            if isinstance(request, BookingIntentBookRequestFlight)
            else None,
            contacts=request.contacts
            if isinstance(request, BookingIntentBookRequestFlight)
            else None,
            guests=request.guests if isinstance(request, BookingIntentBookRequestHotel) else None,
            room_associations=request.roomAssociations
            if isinstance(request, BookingIntentBookRequestHotel)
            else None,
        )

        # Construire la réponse
        amadeus_data = {}
        if booking_intent.type == "flight":
            amadeus_data = {
                "type": "flight",
                "orderId": booking_intent.amadeus_order_id,
            }
        elif booking_intent.type == "hotel":
            amadeus_data = {
                "type": "hotel",
                "bookingId": booking_intent.amadeus_booking_id,
            }

        return BookingIntentBookResponse(
            bookingIntent={
                "id": str(booking_intent.id),
                "status": booking_intent.status,
            },
            amadeus=amadeus_data,
        )
    except AppError as e:
        raise create_http_exception(e) from e
