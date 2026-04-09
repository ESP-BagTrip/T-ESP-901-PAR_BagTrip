"""Routes pour les paiements."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.payments.schemas import (
    PaymentAuthorizeRequest,
    PaymentAuthorizeResponse,
    PaymentCancelResponse,
    PaymentCaptureResponse,
    PaymentRefundRequest,
    PaymentRefundResponse,
)
from src.config.database import get_db
from src.config.env import settings
from src.models.user import User
from src.services.stripe_payments_service import StripePaymentsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/booking-intents", tags=["Payments"])


@router.post(
    "/{intentId}/payment/authorize",
    response_model=PaymentAuthorizeResponse,
    summary="Authorize payment",
    description="Create a Stripe PaymentIntent with manual capture",
)
async def authorize_payment(
    request: PaymentAuthorizeRequest,
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Autoriser un paiement selon PLAN.md."""
    try:
        result = StripePaymentsService.create_manual_capture_payment_intent(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
        )
        return PaymentAuthorizeResponse(**result)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{intentId}/payment/capture",
    response_model=PaymentCaptureResponse,
    summary="Capture payment",
    description="Capture a Stripe PaymentIntent (requires BOOKED status)",
)
async def capture_payment(
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Capturer un paiement selon PLAN.md."""
    try:
        booking_intent = StripePaymentsService.capture_payment(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
        )
        return PaymentCaptureResponse(
            bookingIntent={
                "id": str(booking_intent.id),
                "status": booking_intent.status,
            },
            stripe={
                "paymentIntentId": booking_intent.stripe_payment_intent_id,
            },
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{intentId}/payment/cancel",
    response_model=PaymentCancelResponse,
    summary="Cancel payment",
    description="Cancel a Stripe PaymentIntent",
)
async def cancel_payment(
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Annuler un paiement selon PLAN.md."""
    try:
        booking_intent = StripePaymentsService.cancel_payment(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
        )
        return PaymentCancelResponse(
            bookingIntent={
                "id": str(booking_intent.id),
                "status": booking_intent.status,
            }
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{intentId}/payment/refund",
    response_model=PaymentRefundResponse,
    summary="Refund payment",
    description="Refund a captured Stripe payment (full or partial)",
)
async def refund_payment(
    request: PaymentRefundRequest,
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Rembourser un paiement capturé."""
    try:
        booking_intent = StripePaymentsService.refund_payment(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
            amount=request.amount,
            reason=request.reason,
        )
        return PaymentRefundResponse(
            bookingIntent={
                "id": str(booking_intent.id),
                "status": booking_intent.status,
            }
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{intentId}/payment/confirm-test",
    response_model=PaymentAuthorizeResponse,
    summary="[TEST] Confirm payment with test card",
    description="For POC: Confirm a payment with a test card (4242 4242 4242 4242)",
)
async def confirm_payment_test(
    intentId: UUID = Path(..., description="Booking Intent ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Confirmer un paiement avec une carte de test pour POC."""
    if settings.NODE_ENV == "production":
        raise HTTPException(status_code=404, detail="Not found")
    try:
        result = StripePaymentsService.confirm_payment_with_test_card(
            db=db,
            intent_id=intentId,
            user_id=current_user.id,
        )
        return PaymentAuthorizeResponse(**result)
    except AppError as e:
        raise create_http_exception(e) from e
