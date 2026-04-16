"""Service pour le traitement des webhooks Stripe."""

import contextlib
from datetime import timezone
from uuid import UUID

import stripe
from sqlalchemy.orm import Session

from src.enums import BookingIntentStatus
from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.models.user import User
from src.utils.logger import logger


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

            stripe_event.processed_at = datetime.now(timezone.utc)
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

                if booking_intent and booking_intent.status == BookingIntentStatus.INIT:
                    booking_intent.status = BookingIntentStatus.AUTHORIZED
                    db.commit()

        elif event.type == "payment_intent.canceled":
            # PaymentIntent annulé
            if stripe_event.booking_intent_id:
                booking_intent = (
                    db.query(BookingIntent)
                    .filter(BookingIntent.id == stripe_event.booking_intent_id)
                    .first()
                )

                if booking_intent and booking_intent.status != BookingIntentStatus.CAPTURED:
                    booking_intent.status = BookingIntentStatus.CANCELLED
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
            booking_intent.status = BookingIntentStatus.FAILED
            booking_intent.last_error = {"type": "payment_failed", "event_id": event.id}
            db.commit()

        # --- Subscription events for Premium plan ---
        elif event.type == "customer.subscription.created":
            StripeWebhooksService._handle_subscription_change(db, event, "PREMIUM")

        elif event.type == "customer.subscription.updated":
            StripeWebhooksService._handle_subscription_updated(db, event)

        elif event.type == "customer.subscription.deleted":
            StripeWebhooksService._handle_subscription_change(db, event, "FREE", clear=True)

        elif event.type == "invoice.payment_succeeded":
            StripeWebhooksService._handle_invoice_succeeded(db, event)

        elif event.type == "charge.refunded":
            StripeWebhooksService._handle_charge_refunded(db, event)

    # --- Subscription helpers ---

    @staticmethod
    def _find_user_by_customer(db: Session, event: stripe.Event) -> User | None:
        obj = event.data.object
        customer_id = (
            obj.get("customer") if isinstance(obj, dict) else getattr(obj, "customer", None)
        )
        if not customer_id:
            return None
        return db.query(User).filter(User.stripe_customer_id == customer_id).first()

    @staticmethod
    def _handle_subscription_change(
        db: Session, event: stripe.Event, target_plan: str, *, clear: bool = False
    ) -> None:
        user = StripeWebhooksService._find_user_by_customer(db, event)
        if not user:
            logger.warn(f"subscription event: user not found for {event.type}")
            return
        obj = event.data.object
        user.plan = target_plan
        if clear:
            user.stripe_subscription_id = None
            user.plan_expires_at = None
        else:
            sub_id = obj.get("id") if isinstance(obj, dict) else getattr(obj, "id", None)
            user.stripe_subscription_id = sub_id
            period_end = (
                obj.get("current_period_end")
                if isinstance(obj, dict)
                else getattr(obj, "current_period_end", None)
            )
            if period_end:
                from datetime import datetime

                user.plan_expires_at = datetime.fromtimestamp(period_end, tz=timezone.utc)
        db.commit()
        logger.info(f"User {user.id} plan set to {target_plan}")

    @staticmethod
    def _handle_subscription_updated(db: Session, event: stripe.Event) -> None:
        user = StripeWebhooksService._find_user_by_customer(db, event)
        if not user:
            return
        obj = event.data.object
        status_val = obj.get("status") if isinstance(obj, dict) else getattr(obj, "status", None)
        period_end = (
            obj.get("current_period_end")
            if isinstance(obj, dict)
            else getattr(obj, "current_period_end", None)
        )
        if period_end:
            from datetime import datetime

            user.plan_expires_at = datetime.fromtimestamp(period_end, tz=timezone.utc)
        if status_val in ("canceled", "unpaid", "incomplete_expired"):
            user.plan = "FREE"
            user.stripe_subscription_id = None
        db.commit()

    @staticmethod
    def _handle_invoice_succeeded(db: Session, event: stripe.Event) -> None:
        user = StripeWebhooksService._find_user_by_customer(db, event)
        if not user:
            return
        obj = event.data.object
        lines = obj.get("lines", {}) if isinstance(obj, dict) else getattr(obj, "lines", {})
        data = lines.get("data", []) if isinstance(lines, dict) else getattr(lines, "data", [])
        for line in data:
            period = (
                line.get("period", {}) if isinstance(line, dict) else getattr(line, "period", {})
            )
            end = period.get("end") if isinstance(period, dict) else getattr(period, "end", None)
            if end:
                from datetime import datetime

                user.plan_expires_at = datetime.fromtimestamp(end, tz=timezone.utc)
                break
        if user.plan != "ADMIN":
            user.plan = "PREMIUM"
        db.commit()

    @staticmethod
    def _handle_charge_refunded(db: Session, event: stripe.Event) -> None:
        """Handle charge.refunded — update booking intent to REFUNDED."""
        obj = event.data.object
        charge_id = obj.get("id") if isinstance(obj, dict) else getattr(obj, "id", None)
        if not charge_id:
            return
        booking_intent = (
            db.query(BookingIntent).filter(BookingIntent.stripe_charge_id == charge_id).first()
        )
        if booking_intent and booking_intent.status == BookingIntentStatus.CAPTURED:
            booking_intent.status = BookingIntentStatus.REFUNDED
            db.commit()
