"""Service pour l'orchestration des bookings Amadeus."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOffer, FlightOrderTraveler
from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer as FlightOfferModel
from src.models.flight_order import FlightOrder
from src.models.hotel_offer import HotelOffer
from src.models.traveler import TripTraveler
from src.services.travelers_service import TravelersService
from src.utils.errors import AppError


class BookingOrchestratorService:
    """Service pour orchestrer les bookings Amadeus (Pattern 2)."""

    @staticmethod
    async def book(
        db: Session,
        intent_id: UUID,
        user_id: UUID,
        traveler_ids: list[UUID] | None = None,  # Pour les vols
        contacts: list[dict] | None = None,  # Pour les vols
        guests: list[dict] | None = None,  # Pour les hôtels
        room_associations: list[dict] | None = None,  # Pour les hôtels
    ) -> BookingIntent:
        """
        Book selon le type du booking intent.
        Nécessite que le statut soit AUTHORIZED.
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

        if booking_intent.status != "AUTHORIZED":
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be AUTHORIZED, got {booking_intent.status}",
            )

        # Passer en BOOKING_PENDING
        booking_intent.status = "BOOKING_PENDING"
        db.commit()

        try:
            if booking_intent.type == "flight":
                await BookingOrchestratorService._book_flight(
                    db, booking_intent, traveler_ids, contacts
                )
            elif booking_intent.type == "hotel":
                await BookingOrchestratorService._book_hotel(
                    db, booking_intent, guests, room_associations
                )
            else:
                raise AppError("INVALID_TYPE", 400, f"Invalid booking type: {booking_intent.type}")

            # Succès
            booking_intent.status = "BOOKED"
            db.commit()
            db.refresh(booking_intent)

            return booking_intent

        except Exception as e:
            # Échec - rollback avant de mettre à jour le statut
            db.rollback()
            booking_intent.status = "FAILED"
            booking_intent.last_error = {
                "error": str(e),
                "type": type(e).__name__,
            }
            db.commit()
            raise

    @staticmethod
    async def _book_flight(
        db: Session,
        booking_intent: BookingIntent,
        traveler_ids: list[UUID] | None,
        contacts: list[dict] | None,
    ) -> None:
        """Book un vol."""
        if not booking_intent.selected_offer_id:
            raise AppError("MISSING_OFFER", 400, "No flight offer selected")

        # Charger l'offre
        flight_offer = (
            db.query(FlightOfferModel)
            .filter(FlightOfferModel.id == booking_intent.selected_offer_id)
            .first()
        )

        if not flight_offer:
            raise AppError("OFFER_NOT_FOUND", 404, "Flight offer not found")

        # Construire le payload Amadeus
        # Amadeus recommande d'utiliser une offre repricée (priced) avant le booking
        flight_offer_data = (
            flight_offer.priced_offer_json
            if flight_offer.priced_offer_json
            else flight_offer.offer_json
        )

        if not flight_offer.priced_offer_json:
            # Log a warning but proceed - some offers might work without repricing
            from src.utils.logger import logger
            logger.warning(
                "Booking flight with unpriced offer",
                {
                    "offer_id": str(flight_offer.id),
                    "note": "Consider pricing the offer first for better reliability",
                },
            )

        if isinstance(flight_offer_data, dict):
            amadeus_offer = FlightOffer(**flight_offer_data)
        else:
            amadeus_offer = flight_offer_data

        # Extraire les traveler IDs de l'offre Amadeus
        # Les travelerPricings contiennent les IDs attendus par Amadeus (ex: "1", "2", etc.)
        traveler_pricing_ids = []
        if hasattr(amadeus_offer, "travelerPricings") and amadeus_offer.travelerPricings:
            traveler_pricing_ids = [
                tp.travelerId for tp in amadeus_offer.travelerPricings if hasattr(tp, "travelerId")
            ]
        elif isinstance(flight_offer_data, dict):
            # Fallback: extraire depuis le dict
            traveler_pricings = flight_offer_data.get("travelerPricings", [])
            traveler_pricing_ids = [
                tp.get("travelerId")
                for tp in traveler_pricings
                if isinstance(tp, dict) and tp.get("travelerId")
            ]

        if not traveler_pricing_ids:
            raise AppError(
                "MISSING_TRAVELER_PRICINGS",
                400,
                "Flight offer does not contain travelerPricings. The offer may be invalid.",
            )

        if len(traveler_ids or []) != len(traveler_pricing_ids):
            raise AppError(
                "TRAVELER_COUNT_MISMATCH",
                400,
                f"Number of travelers ({len(traveler_ids or [])}) does not match "
                f"travelerPricings in offer ({len(traveler_pricing_ids)}).",
            )

        # Charger les travelers et les mapper aux IDs Amadeus
        travelers = []
        if traveler_ids:
            for idx, traveler_id in enumerate(traveler_ids):
                if idx >= len(traveler_pricing_ids):
                    raise AppError(
                        "TRAVELER_INDEX_OUT_OF_RANGE",
                        400,
                        f"Not enough travelerPricings in offer for traveler {traveler_id}",
                    )

                traveler = (
                    db.query(TripTraveler)
                    .filter(
                        TripTraveler.id == traveler_id,
                        TripTraveler.trip_id == booking_intent.trip_id,
                    )
                    .first()
                )

                if not traveler:
                    raise AppError("TRAVELER_NOT_FOUND", 404, f"Traveler {traveler_id} not found")

                # Mapper vers Amadeus avec l'ID correct depuis travelerPricings
                amadeus_traveler_payload = TravelersService.traveler_to_amadeus_payload(traveler)
                # Remplacer l'ID par celui attendu par Amadeus
                amadeus_traveler_payload["id"] = traveler_pricing_ids[idx]
                travelers.append(FlightOrderTraveler(**amadeus_traveler_payload))

        # Appeler Amadeus
        order_response = await amadeus_client.create_flight_order(amadeus_offer, travelers)

        # Extraire l'ID de commande
        order_data = order_response.data if hasattr(order_response, "data") else order_response
        amadeus_order_id = (
            order_data.get("id")
            if isinstance(order_data, dict)
            else getattr(order_data, "id", None)
        )

        if not amadeus_order_id:
            raise AppError("AMADEUS_ERROR", 500, "No order ID received from Amadeus")

        # Créer le flight order
        flight_order = FlightOrder(
            trip_id=booking_intent.trip_id,
            flight_offer_id=flight_offer.id,
            booking_intent_id=booking_intent.id,
            amadeus_flight_order_id=amadeus_order_id,
            status="CONFIRMED",
            amadeus_create_order_request={
                "flightOffer": flight_offer_data,
                "travelers": [t.model_dump() if hasattr(t, "model_dump") else t for t in travelers],
            },
            amadeus_create_order_response=order_data
            if isinstance(order_data, dict)
            else order_data.model_dump()
            if hasattr(order_data, "model_dump")
            else {},
        )
        db.add(flight_order)

        # Mettre à jour le booking intent
        booking_intent.amadeus_order_id = amadeus_order_id
        db.commit()

    @staticmethod
    async def _book_hotel(
        db: Session,
        booking_intent: BookingIntent,
        guests: list[dict] | None,
        room_associations: list[dict] | None,
    ) -> None:
        """Book un hôtel."""
        if not booking_intent.selected_offer_id:
            raise AppError("MISSING_OFFER", 400, "No hotel offer selected")

        # Charger l'offre
        hotel_offer = (
            db.query(HotelOffer).filter(HotelOffer.id == booking_intent.selected_offer_id).first()
        )

        if not hotel_offer:
            raise AppError("OFFER_NOT_FOUND", 404, "Hotel offer not found")

        if not guests:
            raise AppError("INVALID_REQUEST", 400, "guests are required for hotel booking")

        # Import logger early for debugging
        from src.utils.logger import logger

        # Extraire offer_id et hotel_id depuis offer_json
        offer_json = hotel_offer.offer_json
        if isinstance(offer_json, dict):
            offer_data = offer_json.get("offer", {})
            # Try multiple possible fields for offer ID
            offer_id = offer_data.get("id") or offer_data.get("offerId") or hotel_offer.offer_id
            hotel_id = hotel_offer.hotel_id
            # Log the offer structure for debugging
            logger.debug(
                "Extracting offer data from offer_json",
                {
                    "offer_data_keys": list(offer_data.keys())
                    if isinstance(offer_data, dict)
                    else None,
                    "offer_id_from_data": offer_data.get("id")
                    if isinstance(offer_data, dict)
                    else None,
                    "offer_id_from_db": hotel_offer.offer_id,
                    "final_offer_id": offer_id,
                },
            )
        else:
            offer_id = hotel_offer.offer_id
            hotel_id = hotel_offer.hotel_id
            logger.debug(
                "Using offer_id from database field",
                {
                    "offer_id": offer_id,
                    "offer_json_type": type(offer_json).__name__,
                },
            )

        if not offer_id:
            raise AppError(
                "MISSING_OFFER_ID",
                400,
                f"No offer ID found. hotel_offer.id={hotel_offer.id}, offer_json type={type(offer_json)}, "
                f"offer_json keys={list(offer_json.keys()) if isinstance(offer_json, dict) else 'N/A'}",
            )

        # Validate offer_id format (should be a string, not empty)
        if not isinstance(offer_id, str) or not offer_id.strip():
            raise AppError(
                "INVALID_OFFER_ID",
                400,
                f"Invalid offer ID format: {offer_id} (type: {type(offer_id)})",
            )

        # Log the data being sent for debugging
        from datetime import UTC, datetime

        # Check offer age - Amadeus hotel offers typically expire within 30-60 minutes
        offer_age_minutes = None
        if hasattr(hotel_offer, "created_at") and hotel_offer.created_at:
            now = datetime.now(UTC)
            # created_at is already timezone-aware (DateTime with timezone=True)
            created_at = hotel_offer.created_at
            if created_at.tzinfo is None:
                # If somehow not timezone-aware, assume UTC
                created_at = created_at.replace(tzinfo=UTC)
            offer_age = now - created_at
            offer_age_minutes = int(offer_age.total_seconds() / 60)

            # Warn if offer is older than 30 minutes (likely expired)
            if offer_age_minutes > 30:
                logger.warn(
                    "Hotel offer is older than 30 minutes - may have expired",
                    {
                        "offer_id": offer_id,
                        "hotel_id": hotel_id,
                        "hotel_offer_db_id": str(hotel_offer.id),
                        "offer_age_minutes": offer_age_minutes,
                        "offer_created_at": str(hotel_offer.created_at),
                    },
                )

        logger.debug(
            "Preparing hotel booking request",
            {
                "offer_id": offer_id,
                "hotel_id": hotel_id,
                "guests": guests,
                "hotel_offer_db_id": str(hotel_offer.id),
                "offer_created_at": str(hotel_offer.created_at)
                if hasattr(hotel_offer, "created_at")
                else None,
                "offer_age_minutes": offer_age_minutes,
            },
        )

        # POC: Skip actual Amadeus booking - just mark as BOOKED
        # In production, this would call Amadeus to actually book the hotel
        logger.info(
            "POC: Skipping Amadeus hotel booking - marking as BOOKED directly",
            {
                "offer_id": offer_id,
                "hotel_id": hotel_id,
                "booking_intent_id": str(booking_intent.id),
            },
        )

        # Simulate successful booking for POC
        # Set a mock booking ID to indicate booking was "completed"
        booking_intent.amadeus_booking_id = f"POC_BOOKING_{booking_intent.id}"

        # For POC, we skip the actual booking and just mark as BOOKED
        # The booking intent status will be updated to BOOKED by the calling function
        return

        # Original Amadeus booking code (commented out for POC)
        # Uncomment this section when ready for production booking
        """
        try:
            booking_response = await amadeus_client.book_hotel(
                offer_id=offer_id,
                hotel_id=hotel_id or "",
                guests=guests,
            )
        except Exception as e:
            error_msg = str(e)
            # Check if it's a 404 error (offer expired or not found)
            if "404" in error_msg or "doesn't exist" in error_msg.lower():
                age_info = ""
                if offer_age_minutes is not None:
                    age_info = f" (offer age: {offer_age_minutes} minutes)"

                logger.warn(
                    "Hotel offer not found - may have expired or test environment limitation",
                    {
                        "offer_id": offer_id,
                        "hotel_id": hotel_id,
                        "hotel_offer_db_id": str(hotel_offer.id),
                        "offer_age_minutes": offer_age_minutes,
                        "error": error_msg,
                    },
                )

                # Build error message
                error_message = f"Hotel offer not found or has expired{age_info}."

                # For very fresh offers (likely test environment issue)
                if offer_age_minutes is not None and offer_age_minutes <= 5:
                    error_message += (
                        " This appears to be a test environment limitation. "
                        "The Amadeus test API may not support actual hotel bookings. "
                        "In production with live API credentials, hotel bookings should work correctly."
                    )
                elif offer_age_minutes is not None and offer_age_minutes > 30:
                    error_message += " Hotel offers from Amadeus typically expire within 30-60 minutes."
                else:
                    error_message += " Hotel offers from Amadeus can expire quickly."

                error_message += " Please search for hotels again and select a new offer."

                raise AppError(
                    "OFFER_EXPIRED",
                    404,
                    error_message,
                ) from e
            raise

        # Extraire l'ID de booking
        booking_data = (
            booking_response.get("data", {})
            if isinstance(booking_response, dict)
            else booking_response
        )
        amadeus_booking_id = (
            booking_data.get("id")
            if isinstance(booking_data, dict)
            else getattr(booking_data, "id", None)
        )

        if not amadeus_booking_id:
            raise AppError("AMADEUS_ERROR", 500, "No booking ID received from Amadeus")

        # Créer le hotel booking
        hotel_booking = HotelBooking(
            trip_id=booking_intent.trip_id,
            hotel_offer_id=hotel_offer.id,
            booking_intent_id=booking_intent.id,
            amadeus_booking_id=amadeus_booking_id,
            status="CONFIRMED",
            amadeus_booking_request={
                "offerId": offer_id,
                "guests": guests,
            },
            amadeus_booking_response=booking_data
            if isinstance(booking_data, dict)
            else booking_data.model_dump()
            if hasattr(booking_data, "model_dump")
            else {},
        )
        db.add(hotel_booking)

        # Mettre à jour le booking intent
        booking_intent.amadeus_booking_id = amadeus_booking_id
        db.commit()
        """
