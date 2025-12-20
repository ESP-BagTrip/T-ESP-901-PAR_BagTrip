"""Service pour la gestion des paiements Stripe."""

import contextlib
from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.stripe.client import StripeClient
from src.models.booking_intent import BookingIntent
from src.utils.errors import AppError


class StripePaymentsService:
    """Service pour les opérations de paiement Stripe."""

    @staticmethod
    def create_manual_capture_payment_intent(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> dict:
        """
        Créer un PaymentIntent Stripe en capture_method=manual.
        Retourne payment_intent_id et client_secret.
        """
        booking_intent = (
            db.query(BookingIntent)
            .filter(
                BookingIntent.id == intent_id,
                BookingIntent.user_id == user_id,
            )
            .first()
        )

        if not booking_intent:
            raise AppError("BOOKING_INTENT_NOT_FOUND", 404, "Booking intent not found")

        if booking_intent.status != "INIT":
            raise AppError(
                "INVALID_STATUS", 400, f"Booking intent must be INIT, got {booking_intent.status}"
            )

        # Convertir le montant en cents (minor units)
        amount_cents = int(float(booking_intent.amount) * 100)

        # Créer le PaymentIntent
        payment_intent = StripeClient.create_payment_intent(
            amount=amount_cents,
            currency=booking_intent.currency,
            metadata={
                "booking_intent_id": str(booking_intent.id),
                "trip_id": str(booking_intent.trip_id),
                "type": booking_intent.type,
            },
            capture_method="manual",
        )

        # Mettre à jour le booking intent
        booking_intent.stripe_payment_intent_id = payment_intent.id
        db.commit()

        return {
            "stripePaymentIntentId": payment_intent.id,
            "clientSecret": payment_intent.client_secret,
            "status": payment_intent.status,
        }

    @staticmethod
    def capture_payment(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> BookingIntent:
        """
        Capturer le paiement d'un PaymentIntent.
        Nécessite que le booking intent soit en statut BOOKED.
        """
        booking_intent = (
            db.query(BookingIntent)
            .filter(
                BookingIntent.id == intent_id,
                BookingIntent.user_id == user_id,
            )
            .first()
        )

        if not booking_intent:
            raise AppError("BOOKING_INTENT_NOT_FOUND", 404, "Booking intent not found")

        if booking_intent.status != "BOOKED":
            raise AppError(
                "INVALID_STATUS", 400, f"Booking intent must be BOOKED, got {booking_intent.status}"
            )

        if not booking_intent.stripe_payment_intent_id:
            raise AppError("MISSING_PAYMENT_INTENT", 400, "No payment intent associated")

        # Capturer le paiement
        payment_intent = StripeClient.capture_payment_intent(
            booking_intent.stripe_payment_intent_id
        )

        # Mettre à jour le booking intent
        booking_intent.status = "CAPTURED"
        booking_intent.stripe_charge_id = payment_intent.latest_charge
        db.commit()
        db.refresh(booking_intent)

        return booking_intent

    @staticmethod
    def cancel_payment(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> BookingIntent:
        """
        Annuler un PaymentIntent.
        Refuse si le statut est déjà CAPTURED.
        """
        booking_intent = (
            db.query(BookingIntent)
            .filter(
                BookingIntent.id == intent_id,
                BookingIntent.user_id == user_id,
            )
            .first()
        )

        if not booking_intent:
            raise AppError("BOOKING_INTENT_NOT_FOUND", 404, "Booking intent not found")

        if booking_intent.status == "CAPTURED":
            raise AppError("INVALID_STATUS", 400, "Cannot cancel a captured payment")

        if booking_intent.stripe_payment_intent_id:
            with contextlib.suppress(Exception):
                # Logger l'erreur mais continuer
                StripeClient.cancel_payment_intent(booking_intent.stripe_payment_intent_id)

        # Mettre à jour le booking intent
        booking_intent.status = "CANCELLED"
        db.commit()
        db.refresh(booking_intent)

        return booking_intent
