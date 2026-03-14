"""Service pour l'orchestration des bookings Amadeus."""

from datetime import datetime
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import BookingIntentStatus, BookingIntentType, BudgetCategory, FlightOrderStatus
from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOffer, FlightOrderTraveler
from src.models.booking_intent import BookingIntent
from src.models.budget_item import BudgetItem
from src.models.flight_offer import FlightOffer as FlightOfferModel
from src.models.flight_order import FlightOrder
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
        traveler_ids: list[UUID] | None = None,
        contacts: list[dict] | None = None,
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

        if booking_intent.status != BookingIntentStatus.AUTHORIZED:
            raise AppError(
                "INVALID_STATUS",
                400,
                f"Booking intent must be AUTHORIZED, got {booking_intent.status}",
            )

        # Passer en BOOKING_PENDING
        booking_intent.status = BookingIntentStatus.BOOKING_PENDING
        db.commit()

        try:
            if booking_intent.type == BookingIntentType.FLIGHT:
                await BookingOrchestratorService._book_flight(
                    db, booking_intent, traveler_ids, contacts
                )
            else:
                raise AppError("INVALID_TYPE", 400, f"Invalid booking type: {booking_intent.type}")

            # Succès
            booking_intent.status = BookingIntentStatus.BOOKED
            db.commit()
            db.refresh(booking_intent)

            return booking_intent

        except Exception as e:
            # Échec - rollback avant de mettre à jour le statut
            db.rollback()
            booking_intent.status = BookingIntentStatus.FAILED
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

        # Extract ticket_url from Amadeus response if available
        ticket_url = None
        if isinstance(order_data, dict):
            associated_records = order_data.get("associatedRecords", [])
            for record in associated_records:
                if record.get("originSystemCode") == "GDS":
                    ticket_url = f"amadeus://order/{amadeus_order_id}"
                    break

        # Créer le flight order
        flight_order = FlightOrder(
            trip_id=booking_intent.trip_id,
            flight_offer_id=flight_offer.id,
            booking_intent_id=booking_intent.id,
            amadeus_flight_order_id=amadeus_order_id,
            status=FlightOrderStatus.CONFIRMED,
            payment_id=booking_intent.stripe_payment_intent_id,
            ticket_url=ticket_url,
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

        # Auto-create budget item for the flight
        origin_iata = ""
        destination_iata = ""
        departure_date = None
        try:
            offer_data = flight_offer.priced_offer_json or flight_offer.offer_json
            if isinstance(offer_data, dict):
                itineraries = offer_data.get("itineraries", [])
                if itineraries:
                    segments = itineraries[0].get("segments", [])
                    if segments:
                        origin_iata = segments[0].get("departure", {}).get("iataCode", "")
                        destination_iata = segments[-1].get("arrival", {}).get("iataCode", "")
                        dep_at = segments[0].get("departure", {}).get("at", "")
                        if dep_at:
                            departure_date = datetime.fromisoformat(dep_at).date()
        except Exception:
            pass

        label = f"Vol : {origin_iata} → {destination_iata}" if origin_iata and destination_iata else "Vol"

        budget_item = BudgetItem(
            trip_id=booking_intent.trip_id,
            label=label,
            amount=booking_intent.amount,
            category=BudgetCategory.FLIGHT,
            date=departure_date,
            is_planned=False,
            source_type="flight_order",
            source_id=flight_order.id,
        )
        db.add(budget_item)

        # Mettre à jour le booking intent
        booking_intent.amadeus_order_id = amadeus_order_id
        db.commit()
