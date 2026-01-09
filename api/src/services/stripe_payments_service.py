"""Service pour la gestion des paiements Stripe."""

import contextlib
import json
from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.stripe.client import StripeClient
from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.models.hotel_offer import HotelOffer
from src.models.user import User
from src.services.stripe_products_service import StripeProductsService
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

        # Récupérer l'utilisateur pour obtenir le stripe_customer_id
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("USER_NOT_FOUND", 404, "User not found")

        # Create Stripe customer on-demand if missing
        if not user.stripe_customer_id:
            try:
                stripe_customer = StripeClient.create_customer(
                    email=user.email,
                    name=user.full_name,
                )
                user.stripe_customer_id = stripe_customer.id
                db.commit()
                db.refresh(user)
            except Exception as e:
                raise AppError(
                    "STRIPE_CUSTOMER_CREATION_FAILED",
                    500,
                    f"Failed to create Stripe customer: {str(e)}",
                ) from e

        # Convertir le montant en cents (minor units)
        amount_cents = int(float(booking_intent.amount) * 100)

        # Récupérer le product ID
        product_id = StripeProductsService.get_product_id(booking_intent.type)
        if not product_id:
            raise AppError(
                "STRIPE_PRODUCT_NOT_FOUND",
                500,
                f"Stripe product for type '{booking_intent.type}' not initialized",
            )

        # Récupérer les détails de l'offre pour metadata et description
        offer_details = StripePaymentsService._get_offer_details(db, booking_intent)
        description = offer_details.get("description", f"{booking_intent.type.title()} Booking")

        # Construire les metadata avec les détails du produit
        metadata = {
            "booking_intent_id": str(booking_intent.id),
            "trip_id": str(booking_intent.trip_id),
            "type": booking_intent.type,
            "product_id": product_id,
        }
        # Ajouter les détails de l'offre dans metadata
        metadata.update(offer_details.get("metadata", {}))

        # Créer le PaymentIntent avec le customer ID et product
        payment_intent = StripeClient.create_payment_intent(
            amount=amount_cents,
            currency=booking_intent.currency,
            metadata=metadata,
            capture_method="manual",
            customer=user.stripe_customer_id,
            description=description,
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

        # POC: Allow capture from AUTHORIZED status (skip booking step)
        # In production, this should require BOOKED status
        if booking_intent.status not in ["BOOKED", "AUTHORIZED"]:
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be BOOKED or AUTHORIZED (POC), got {booking_intent.status}",
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

    @staticmethod
    def confirm_payment_with_test_card(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
    ) -> dict:
        """
        [TEST/POC] Confirmer un paiement avec une carte de test.
        Pour POC uniquement - en production, utiliser Stripe Elements côté client.
        Utilise un test token Stripe au lieu de données de carte brutes.
        """
        import stripe

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

        # Utiliser un test payment method token de Stripe
        # pm_card_visa est un token de test qui représente une carte Visa réussie
        # Voir: https://stripe.com/docs/testing#cards
        test_payment_method_id = "pm_card_visa"

        # Confirmer le PaymentIntent avec le test payment method
        # Ajouter return_url pour éviter l'erreur de redirect-based payment methods
        payment_intent = stripe.PaymentIntent.confirm(
            booking_intent.stripe_payment_intent_id,
            payment_method=test_payment_method_id,
            return_url="https://example.com/return",  # URL de retour pour POC
        )

        # Mettre à jour le booking intent si le paiement est autorisé
        if payment_intent.status == "requires_capture":
            booking_intent.status = "AUTHORIZED"
            db.commit()
            db.refresh(booking_intent)

        return {
            "stripePaymentIntentId": payment_intent.id,
            "clientSecret": payment_intent.client_secret,
            "status": payment_intent.status,
        }

    @staticmethod
    def _get_offer_details(db: Session, booking_intent: BookingIntent) -> dict:
        """
        Récupère les détails de l'offre (flight ou hotel) pour les inclure dans metadata et description.
        """
        if not booking_intent.selected_offer_id or not booking_intent.selected_offer_type:
            return {
                "description": f"{booking_intent.type.title()} Booking",
                "metadata": {},
            }

        details = {
            "description": f"{booking_intent.type.title()} Booking",
            "metadata": {},
        }

        try:
            if (
                booking_intent.type == "flight"
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
                        # Extraire les informations de vol
                        itineraries = offer_json.get("itineraries", [])
                        segments = []
                        if itineraries:
                            for itinerary in itineraries[:1]:  # Premier itinéraire
                                segments.extend(itinerary.get("segments", []))

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
                            # Ajouter les détails complets en JSON (limité à 500 caractères pour Stripe)
                            offer_summary = json.dumps(
                                {
                                    "itineraries_count": len(itineraries),
                                    "segments_count": len(segments),
                                    "validating_airline": flight_offer.validating_airline_codes,
                                }
                            )
                            if len(offer_summary) <= 200:
                                details["metadata"]["offer_summary"] = offer_summary

            elif (
                booking_intent.type == "hotel"
                and booking_intent.selected_offer_type == "hotel_offer"
            ):
                hotel_offer = (
                    db.query(HotelOffer)
                    .filter(HotelOffer.id == booking_intent.selected_offer_id)
                    .first()
                )
                if hotel_offer and hotel_offer.offer_json:
                    offer_json = hotel_offer.offer_json
                    if isinstance(offer_json, dict):
                        # Extraire les informations d'hôtel
                        hotel = offer_json.get("hotel", {})
                        hotel_name = hotel.get("name", "Hotel")
                        hotel_id = hotel.get("hotelId", "")
                        chain_code = hotel_offer.chain_code or ""
                        room_type = hotel_offer.room_type or ""

                        details["description"] = f"Hotel: {hotel_name}"
                        details["metadata"] = {
                            "hotel_name": hotel_name,
                            "hotel_id": hotel_id,
                            "chain_code": chain_code,
                            "room_type": room_type,
                            "hotel_offer_id": str(hotel_offer.id),
                            "offer_id": hotel_offer.offer_id or "",
                        }
                        # Ajouter les détails complets en JSON (limité pour Stripe)
                        offer_summary = json.dumps(
                            {
                                "hotel_name": hotel_name,
                                "chain_code": chain_code,
                            }
                        )
                        if len(offer_summary) <= 200:
                            details["metadata"]["offer_summary"] = offer_summary

        except Exception:
            # En cas d'erreur, continuer avec les détails de base
            pass

        return details
