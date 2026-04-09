"""Schémas Pydantic pour les paiements."""

from pydantic import BaseModel


class PaymentAuthorizeRequest(BaseModel):
    """Requête d'autorisation de paiement selon PLAN.md."""

    returnUrl: str | None = None


class PaymentAuthorizeResponse(BaseModel):
    """Réponse d'autorisation de paiement selon PLAN.md."""

    stripePaymentIntentId: str
    clientSecret: str
    status: str


class PaymentCaptureResponse(BaseModel):
    """Réponse de capture de paiement selon PLAN.md."""

    bookingIntent: dict
    stripe: dict


class PaymentCancelResponse(BaseModel):
    """Réponse d'annulation de paiement selon PLAN.md."""

    bookingIntent: dict


class PaymentRefundRequest(BaseModel):
    """Requête de remboursement."""

    amount: int | None = None
    reason: str | None = None


class PaymentRefundResponse(BaseModel):
    """Réponse de remboursement."""

    bookingIntent: dict
