"""Routes pour le booking (book endpoint)."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.booking_intents.schemas import (
    BookingIntentBookRequestFlight,
    BookingIntentBookResponse,
    BookingIntentResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.booking_intents_service import BookingIntentsService
from src.services.booking_orchestrator_service import BookingOrchestratorService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/booking-intents", tags=["Booking Intents"])


@router.get(
    "/{intentId}",
    response_model=BookingIntentResponse,
    summary="Get booking intent",
    description="Get booking intent by ID",
)
async def get_booking_intent(
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer un booking intent par ID."""
    try:
        booking_intent = BookingIntentsService.get_intent_by_id(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
        )

        if not booking_intent:
            raise AppError("BOOKING_INTENT_NOT_FOUND", 404, "Booking intent not found")

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


@router.post(
    "/{intentId}/book",
    response_model=BookingIntentBookResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Book flight",
    description="Book a flight through Amadeus (requires AUTHORIZED status)",
)
async def book(
    request: BookingIntentBookRequestFlight,
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
            traveler_ids=request.travelerIds,
            contacts=request.contacts,
        )

        # Construire la réponse
        amadeus_data = {
            "type": "flight",
            "orderId": booking_intent.amadeus_order_id,
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
