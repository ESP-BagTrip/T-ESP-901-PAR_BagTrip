"""Service pour l'orchestration des bookings Amadeus."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOffer, FlightOrderTraveler
from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer as FlightOfferModel
from src.models.flight_order import FlightOrder
from src.models.hotel_booking import HotelBooking
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
            # Échec
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

        # Charger les travelers
        travelers = []
        if traveler_ids:
            for traveler_id in traveler_ids:
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

                # Mapper vers Amadeus
                amadeus_traveler = TravelersService.traveler_to_amadeus_payload(traveler)
                travelers.append(FlightOrderTraveler(**amadeus_traveler))

        # Construire le payload Amadeus
        flight_offer_data = (
            flight_offer.priced_offer_json
            if flight_offer.priced_offer_json
            else flight_offer.offer_json
        )
        if isinstance(flight_offer_data, dict):
            amadeus_offer = FlightOffer(**flight_offer_data)
        else:
            amadeus_offer = flight_offer_data

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

        # Extraire offer_id et hotel_id depuis offer_json
        offer_json = hotel_offer.offer_json
        if isinstance(offer_json, dict):
            offer_data = offer_json.get("offer", {})
            offer_id = offer_data.get("id") or hotel_offer.offer_id
            hotel_id = hotel_offer.hotel_id
        else:
            offer_id = hotel_offer.offer_id
            hotel_id = hotel_offer.hotel_id

        if not offer_id:
            raise AppError("MISSING_OFFER_ID", 400, "No offer ID found")

        # Appeler Amadeus
        booking_response = await amadeus_client.book_hotel(
            offer_id=offer_id,
            hotel_id=hotel_id or "",
            guests=guests,
        )

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
