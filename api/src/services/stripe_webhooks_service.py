"""Service pour le traitement des webhooks Stripe."""

import contextlib
from datetime import UTC
from uuid import UUID

import stripe
from sqlalchemy.orm import Session

from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent


class StripeWebhooksService:
    """Service pour le traitement des événements Stripe."""

    @staticmethod
    def process_event(
        db: Session,
        event: stripe.Event,
    ) -> StripeEvent:
        """
        Traiter un événement Stripe.
        Persiste l'événement et met à jour le booking intent si nécessaire.
        """
        # Vérifier l'idempotence
        existing_event = (
            db.query(StripeEvent).filter(StripeEvent.stripe_event_id == event.id).first()
        )

        if existing_event:
            # Événement déjà traité
            return existing_event

        # Créer l'enregistrement d'événement
        stripe_event = StripeEvent(
            stripe_event_id=event.id,
            type=event.type,
            livemode=event.livemode,
            payload=event.to_dict(),
        )

        # Extraire booking_intent_id depuis les metadata si disponible
        booking_intent_id = None
        if event.type.startswith("payment_intent."):
            payment_intent = event.data.object
            if isinstance(payment_intent, dict):
                metadata = payment_intent.get("metadata", {})
            else:
                metadata = getattr(payment_intent, "metadata", {})
            booking_intent_id_str = metadata.get("booking_intent_id")
            if booking_intent_id_str:
                with contextlib.suppress(ValueError):
                    booking_intent_id = UUID(booking_intent_id_str)

        if booking_intent_id:
            stripe_event.booking_intent_id = booking_intent_id

        db.add(stripe_event)
        db.flush()

        # Traiter l'événement selon son type
        try:
            StripeWebhooksService._handle_event(db, event, stripe_event)
            from datetime import datetime

            stripe_event.processed_at = datetime.now(UTC)
        except Exception as e:
            stripe_event.processing_error = {"error": str(e), "type": type(e).__name__}

        db.commit()
        db.refresh(stripe_event)

        return stripe_event

    @staticmethod
    def _handle_event(
        db: Session,
        event: stripe.Event,
        stripe_event: StripeEvent,
    ) -> None:
        """Gérer un événement spécifique."""
        if event.type == "payment_intent.amount_capturable_updated":
            # PaymentIntent est autorisé (requires_capture)
            if stripe_event.booking_intent_id:
                booking_intent = (
                    db.query(BookingIntent)
                    .filter(BookingIntent.id == stripe_event.booking_intent_id)
                    .first()
                )

                if booking_intent and booking_intent.status == "INIT":
                    booking_intent.status = "AUTHORIZED"
                    db.commit()

        elif event.type == "payment_intent.canceled":
            # PaymentIntent annulé
            if stripe_event.booking_intent_id:
                booking_intent = (
                    db.query(BookingIntent)
                    .filter(BookingIntent.id == stripe_event.booking_intent_id)
                    .first()
                )

                if booking_intent and booking_intent.status != "CAPTURED":
                    booking_intent.status = "CANCELLED"
                    db.commit()

        elif (
            event.type == "payment_intent.payment_failed"
            and stripe_event.booking_intent_id
            and (
                booking_intent := db.query(BookingIntent)
                .filter(BookingIntent.id == stripe_event.booking_intent_id)
                .first()
            )
        ):
            # Échec de paiement
            booking_intent.status = "FAILED"
            booking_intent.last_error = {"type": "payment_failed", "event_id": event.id}
            db.commit()
