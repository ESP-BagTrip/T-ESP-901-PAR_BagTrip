"""Service pour la gestion des paiements Stripe.

Idempotency
-----------
Every Stripe-mutating call passes a stable key derived from the booking intent
ID + operation name. A network retry of the same business operation will hit
Stripe with the same key and return the original response — no duplicate
PaymentIntent, no duplicate refund, no duplicate capture.

Refund validation
-----------------
Refunds query the Stripe `Charge` for the authoritative `amount_captured` and
`amount_refunded` and refuse anything that would over-refund. Trusting the
client-supplied amount blindly was the previous (P0) bug.
"""

from __future__ import annotations

import contextlib
import json
from typing import Any
from uuid import UUID

import stripe
from sqlalchemy.orm import Session

from src.config.env import settings
from src.enums import BookingIntentStatus, BookingIntentType
from src.integrations.stripe.client import StripeClient
from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.models.user import User
from src.services.stripe_products_service import StripeProductsService
from src.utils.errors import AppError
from src.utils.logger import logger

# Stripe-allowed refund reasons. Anything else is rejected at the schema layer.
ALLOWED_REFUND_REASONS = {
    "duplicate",
    "fraudulent",
    "requested_by_customer",
}


def _idem_key(prefix: str, intent_id: UUID) -> str:
    """Build a stable idempotency key — stable across retries of the same op."""
    return f"bi-{intent_id}-{prefix}-v1"


class StripePaymentsService:
    """Service pour les opérations de paiement Stripe."""

    @staticmethod
    def create_manual_capture_payment_intent(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> dict:
        """Créer un PaymentIntent Stripe en capture_method=manual."""
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

        if booking_intent.status != BookingIntentStatus.INIT:
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be INIT, got {booking_intent.status}",
            )

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("USER_NOT_FOUND", 404, "User not found")

        if not user.stripe_customer_id:
            raise AppError(
                "MISSING_STRIPE_CUSTOMER",
                400,
                "User does not have a Stripe customer ID. Please contact support or re-register.",
            )

        amount_cents = int(float(booking_intent.amount) * 100)

        product_id = StripeProductsService.get_product_id(booking_intent.type)
        if not product_id:
            raise AppError(
                "STRIPE_PRODUCT_NOT_FOUND",
                500,
                f"Stripe product for type '{booking_intent.type}' not initialized",
            )

        offer_details = StripePaymentsService._get_offer_details(db, booking_intent)
        description = offer_details.get("description", f"{booking_intent.type.title()} Booking")

        metadata = {
            "booking_intent_id": str(booking_intent.id),
            "trip_id": str(booking_intent.trip_id),
            "type": booking_intent.type,
            "product_id": product_id,
        }
        metadata.update(offer_details.get("metadata", {}))

        try:
            payment_intent = StripeClient.create_payment_intent(
                amount=amount_cents,
                currency=booking_intent.currency,
                metadata=metadata,
                capture_method="manual",
                customer=user.stripe_customer_id,
                description=description,
                idempotency_key=_idem_key("authorize", booking_intent.id),
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe authorize failed for intent {booking_intent.id}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "STRIPE_ERROR",
                502,
                "Payment authorization failed. Please try again.",
            ) from exc

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
        """Capturer le paiement d'un PaymentIntent.

        Allowed source statuses:
          - BOOKED — the canonical "Amadeus order succeeded, charge the card" path.
          - AUTHORIZED — non-prod escape hatch so the QA flow can capture without
            actually booking through Amadeus. Blocked in production.
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

        is_production = settings.NODE_ENV == "production"
        if is_production:
            allowed_statuses = (BookingIntentStatus.BOOKED,)
        else:
            allowed_statuses = (BookingIntentStatus.BOOKED, BookingIntentStatus.AUTHORIZED)

        if booking_intent.status not in allowed_statuses:
            allowed_str = " or ".join(s.value for s in allowed_statuses)
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be {allowed_str} to capture, got {booking_intent.status}",
            )

        if not booking_intent.stripe_payment_intent_id:
            raise AppError("MISSING_PAYMENT_INTENT", 400, "No payment intent associated")

        try:
            payment_intent = StripeClient.capture_payment_intent(
                booking_intent.stripe_payment_intent_id,
                idempotency_key=_idem_key("capture", booking_intent.id),
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe capture failed for intent {booking_intent.id}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "STRIPE_ERROR",
                502,
                "Payment capture failed.",
            ) from exc

        booking_intent.status = BookingIntentStatus.CAPTURED
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
        """Annuler un PaymentIntent. Refuse si le statut est déjà CAPTURED."""
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

        if booking_intent.status == BookingIntentStatus.CAPTURED:
            raise AppError("INVALID_STATUS", 400, "Cannot cancel a captured payment")

        if booking_intent.stripe_payment_intent_id:
            with contextlib.suppress(stripe.StripeError):
                # Best-effort cancel against Stripe — the source of truth is the
                # local status update below. If Stripe is down or the PI is in
                # a non-cancelable state, we still mark the intent CANCELLED
                # locally so the user can move on.
                StripeClient.cancel_payment_intent(
                    booking_intent.stripe_payment_intent_id,
                    idempotency_key=_idem_key("cancel", booking_intent.id),
                )

        booking_intent.status = BookingIntentStatus.CANCELLED
        db.commit()
        db.refresh(booking_intent)

        return booking_intent

    @staticmethod
    def refund_payment(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
        amount: int | None = None,
        reason: str | None = None,
    ) -> BookingIntent:
        """Rembourser un paiement capturé.

        Validates `amount` against Stripe's authoritative captured/refunded
        amounts before issuing the refund. Prevents double-refunds and
        over-refunds even when the caller is wrong.
        """
        if reason is not None and reason not in ALLOWED_REFUND_REASONS:
            raise AppError(
                "INVALID_REFUND_REASON",
                400,
                f"reason must be one of {sorted(ALLOWED_REFUND_REASONS)}",
            )
        if amount is not None and amount <= 0:
            raise AppError("INVALID_AMOUNT", 400, "amount must be positive (in cents)")

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

        if booking_intent.status != BookingIntentStatus.CAPTURED:
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be CAPTURED to refund, got {booking_intent.status}",
            )

        if not booking_intent.stripe_charge_id:
            raise AppError("MISSING_CHARGE_ID", 400, "No charge ID associated for refund")

        # Validate against Stripe's source of truth. We don't trust local state
        # because partial refunds aren't tracked on BookingIntent, and a manual
        # refund issued from the Stripe dashboard would otherwise be invisible.
        try:
            charge = StripeClient.retrieve_charge(booking_intent.stripe_charge_id)
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe charge retrieve failed for {booking_intent.stripe_charge_id}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "STRIPE_ERROR",
                502,
                "Could not verify charge state. Please try again.",
            ) from exc

        captured = int(getattr(charge, "amount_captured", 0) or 0)
        already_refunded = int(getattr(charge, "amount_refunded", 0) or 0)
        remaining = max(0, captured - already_refunded)

        if remaining <= 0:
            raise AppError(
                "ALREADY_FULLY_REFUNDED",
                400,
                "Charge has already been fully refunded.",
            )

        if amount is not None and amount > remaining:
            raise AppError(
                "REFUND_AMOUNT_EXCEEDS_REMAINING",
                400,
                f"Requested refund {amount} exceeds remaining {remaining} cents",
            )

        # Stable key per refund request — including the requested amount means a
        # partial refund of 500 retried after a network failure dedup'es, but a
        # second deliberate refund of 200 gets its own key.
        idem_suffix = f"refund-{amount or remaining}-{already_refunded}"

        try:
            StripeClient.create_refund(
                charge_id=booking_intent.stripe_charge_id,
                amount=amount,
                reason=reason,
                idempotency_key=_idem_key(idem_suffix, booking_intent.id),
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe refund failed for charge {booking_intent.stripe_charge_id}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "STRIPE_ERROR",
                502,
                "Refund failed. Please try again.",
            ) from exc

        # Only mark fully REFUNDED if the whole captured amount is now refunded.
        # Partial refunds keep status CAPTURED so further partial refunds remain
        # possible until the total reaches `captured`.
        new_refunded_total = already_refunded + (amount if amount is not None else remaining)
        if new_refunded_total >= captured:
            booking_intent.status = BookingIntentStatus.REFUNDED

        db.commit()
        db.refresh(booking_intent)

        return booking_intent

    @staticmethod
    def confirm_payment_with_test_card(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> dict:
        """[ADMIN/POC] Confirmer un paiement avec une carte de test.

        For local QA only. Route is admin-gated *and* blocked entirely in
        production. Real clients confirm via the Stripe PaymentSheet on mobile
        or Elements on the web — never via this endpoint.
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

        if not booking_intent.stripe_payment_intent_id:
            raise AppError("MISSING_PAYMENT_INTENT", 400, "No payment intent associated")

        # `pm_card_visa` is a Stripe test token that always succeeds — see
        # https://stripe.com/docs/testing#cards. Never reachable from real
        # clients (admin-gated + non-prod-only).
        test_payment_method_id = "pm_card_visa"

        try:
            payment_intent = stripe.PaymentIntent.confirm(
                booking_intent.stripe_payment_intent_id,
                payment_method=test_payment_method_id,
                return_url="bagtrip://payment/result",
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe test confirm failed for intent {booking_intent.id}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "STRIPE_ERROR",
                502,
                "Test confirmation failed.",
            ) from exc

        if payment_intent.status == "requires_capture":
            booking_intent.status = BookingIntentStatus.AUTHORIZED
            db.commit()
            db.refresh(booking_intent)

        return {
            "stripePaymentIntentId": payment_intent.id,
            "clientSecret": payment_intent.client_secret,
            "status": payment_intent.status,
        }

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _get_offer_details(db: Session, booking_intent: BookingIntent) -> dict[str, Any]:
        """Récupère les détails de l'offre pour metadata + description Stripe."""
        if not booking_intent.selected_offer_id or not booking_intent.selected_offer_type:
            return {
                "description": f"{booking_intent.type.title()} Booking",
                "metadata": {},
            }

        details: dict[str, Any] = {
            "description": f"{booking_intent.type.title()} Booking",
            "metadata": {},
        }

        try:
            if (
                booking_intent.type == BookingIntentType.FLIGHT
                and booking_intent.selected_offer_type == "flight_offer"
            ):
                flight_offer = (
                    db.query(FlightOffer)
                    .filter(FlightOffer.id == booking_intent.selected_offer_id)
                    .first()
                )
                if flight_offer and flight_offer.offer_json:
                    offer_json = (
                        flight_offer.priced_offer_json
                        if flight_offer.priced_offer_json
                        else flight_offer.offer_json
                    )
                    if isinstance(offer_json, dict):
                        itineraries = offer_json.get("itineraries", []) or []
                        segments: list[dict] = []
                        if itineraries:
                            for itinerary in itineraries[:1]:
                                segments.extend(itinerary.get("segments", []) or [])

                        if segments:
                            first_segment = segments[0]
                            last_segment = segments[-1]
                            origin = first_segment.get("departure", {}).get("iataCode", "")
                            destination = last_segment.get("arrival", {}).get("iataCode", "")
                            departure_date = first_segment.get("departure", {}).get("at", "")

                            details["description"] = f"Flight: {origin} → {destination}"
                            details["metadata"] = {
                                "flight_origin": origin,
                                "flight_destination": destination,
                                "flight_departure": departure_date,
                                "flight_offer_id": str(flight_offer.id),
                                "amadeus_offer_id": flight_offer.amadeus_offer_id or "",
                            }
                            offer_summary = json.dumps(
                                {
                                    "itineraries_count": len(itineraries),
                                    "segments_count": len(segments),
                                    "validating_airline": flight_offer.validating_airline_codes,
                                }
                            )
                            if len(offer_summary) <= 200:
                                details["metadata"]["offer_summary"] = offer_summary

        except Exception as exc:
            # The offer payload is opaque JSON; defending against shape drift
            # here means a malformed offer can't break authorization. Log so
            # we notice if it happens in practice.
            logger.warn(
                f"Failed to extract flight offer details for intent {booking_intent.id}: {exc}"
            )

        return details
