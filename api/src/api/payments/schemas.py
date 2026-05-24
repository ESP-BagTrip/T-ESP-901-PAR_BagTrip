"""Schémas Pydantic pour les paiements."""

from typing import Literal

from pydantic import BaseModel, Field

# Stripe-supported refund reasons. Anything else is rejected at the schema
# layer so we don't waste a round-trip just to have Stripe reject it.
RefundReason = Literal["duplicate", "fraudulent", "requested_by_customer"]


class PaymentAuthorizeRequest(BaseModel):
    """Requête d'autorisation de paiement."""

    returnUrl: str | None = None


class PaymentAuthorizeResponse(BaseModel):
    """Réponse d'autorisation de paiement."""

    stripePaymentIntentId: str
    clientSecret: str
    status: str


class PaymentCaptureResponse(BaseModel):
    """Réponse de capture de paiement."""

    bookingIntent: dict
    stripe: dict


class PaymentCancelResponse(BaseModel):
    """Réponse d'annulation de paiement."""

    bookingIntent: dict


class PaymentRefundRequest(BaseModel):
    """Requête de remboursement (montant en cents)."""

    amount: int | None = Field(default=None, gt=0, description="Montant à rembourser en cents")
    reason: RefundReason | None = None


class PaymentRefundResponse(BaseModel):
    """Réponse de remboursement."""

    bookingIntent: dict
