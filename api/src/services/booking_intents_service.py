"""Service pour la gestion des booking intents."""

from decimal import Decimal
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.models.hotel_offer import HotelOffer
from src.utils.errors import AppError


class BookingIntentsService:
    """Service pour les booking intents (orchestration)."""

    @staticmethod
    def create_intent(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        type: str,  # flight | hotel
        flight_offer_id: UUID | None = None,
        hotel_offer_id: UUID | None = None,
    ) -> BookingIntent:
        """
        Créer un booking intent selon PLAN.md.
        Accès vérifié par la dependency en amont.
        """
        # Charger l'offre selon le type
        amount = Decimal("0")
        currency = "EUR"
        selected_offer_type = None
        selected_offer_id = None

        if type == "flight":
            if not flight_offer_id:
                raise AppError("INVALID_REQUEST", 400, "flightOfferId is required for flight type")

            offer = (
                db.query(FlightOffer)
                .filter(
                    FlightOffer.id == flight_offer_id,
                    FlightOffer.trip_id == trip_id,
                )
                .first()
            )

            if not offer:
                raise AppError("OFFER_NOT_FOUND", 404, "Flight offer not found")

            # Utiliser priced_offer_json si disponible, sinon offer_json
            price_source = offer.priced_offer_json if offer.priced_offer_json else offer.offer_json
            if isinstance(price_source, dict):
                price_data = (
                    price_source.get("price", {}) if "price" in price_source else price_source
                )
                if isinstance(price_data, dict):
                    grand_total = price_data.get("grandTotal", offer.grand_total or 0)
                    currency_code = price_data.get("currency", offer.currency or "EUR")
                else:
                    grand_total = offer.grand_total or 0
                    currency_code = offer.currency or "EUR"
            else:
                grand_total = offer.grand_total or 0
                currency_code = offer.currency or "EUR"

            amount = Decimal(str(grand_total))
            currency = currency_code or "EUR"
            selected_offer_type = "flight_offer"
            selected_offer_id = flight_offer_id

        elif type == "hotel":
            if not hotel_offer_id:
                raise AppError("INVALID_REQUEST", 400, "hotelOfferId is required for hotel type")

            offer = (
                db.query(HotelOffer)
                .filter(
                    HotelOffer.id == hotel_offer_id,
                    HotelOffer.trip_id == trip_id,
                )
                .first()
            )

            if not offer:
                raise AppError("OFFER_NOT_FOUND", 404, "Hotel offer not found")

            amount = Decimal(str(offer.total_price or 0))
            currency = offer.currency or "EUR"
            selected_offer_type = "hotel_offer"
            selected_offer_id = hotel_offer_id

        else:
            raise AppError(
                "INVALID_REQUEST", 400, f"Invalid type: {type}. Must be 'flight' or 'hotel'"
            )

        # Créer le booking intent
        booking_intent = BookingIntent(
            user_id=user_id,
            trip_id=trip_id,
            type=type,
            status="INIT",
            amount=amount,
            currency=currency,
            selected_offer_type=selected_offer_type,
            selected_offer_id=selected_offer_id,
        )

        db.add(booking_intent)
        db.commit()
        db.refresh(booking_intent)

        return booking_intent

    @staticmethod
    def get_intent_by_id(db: Session, intent_id: UUID, user_id: UUID) -> BookingIntent | None:
        """Récupérer un booking intent par ID."""
        return (
            db.query(BookingIntent)
            .filter(
                BookingIntent.id == intent_id,
                BookingIntent.user_id == user_id,
            )
            .first()
        )
