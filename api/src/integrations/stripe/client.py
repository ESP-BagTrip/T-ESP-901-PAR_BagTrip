"""Client Stripe wrapper."""

import stripe
from src.config.env import settings

# Initialiser Stripe avec la clé secrète
if settings.STRIPE_SECRET_KEY:
    stripe.api_key = settings.STRIPE_SECRET_KEY


class StripeClient:
    """Client wrapper pour Stripe."""

    @staticmethod
    def create_payment_intent(
        amount: int,  # En cents (minor units)
        currency: str,
        metadata: dict | None = None,
        capture_method: str = "manual",
    ) -> stripe.PaymentIntent:
        """Créer un PaymentIntent avec capture manuelle."""
        return stripe.PaymentIntent.create(
            amount=amount,
            currency=currency.lower(),
            capture_method=capture_method,
            metadata=metadata or {},
        )

    @staticmethod
    def capture_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
        """Capturer un PaymentIntent."""
        return stripe.PaymentIntent.capture(payment_intent_id)

    @staticmethod
    def cancel_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
        """Annuler un PaymentIntent."""
        return stripe.PaymentIntent.cancel(payment_intent_id)

    @staticmethod
    def retrieve_payment_intent(payment_intent_id: str) -> stripe.PaymentIntent:
        """Récupérer un PaymentIntent."""
        return stripe.PaymentIntent.retrieve(payment_intent_id)
