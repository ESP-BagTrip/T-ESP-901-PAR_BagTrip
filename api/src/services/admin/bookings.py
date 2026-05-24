"""Admin service — flight bookings, intents and flight searches domain."""

from sqlalchemy.orm import Session

from src.api.common.pagination import PaginationParams, paginate
from src.models.booking_intent import BookingIntent
from src.models.flight_order import FlightOrder
from src.models.flight_search import FlightSearch
from src.models.trip import Trip
from src.models.user import User
from src.utils.errors import AppError


def _serialize_flight_booking_row(row) -> dict:
    order, trip_title, user_email = row
    return {
        "id": order.id,
        "trip_id": order.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "flight_offer_id": order.flight_offer_id,
        "booking_intent_id": order.booking_intent_id,
        "amadeus_flight_order_id": order.amadeus_flight_order_id,
        "status": order.status,
        "booking_reference": order.booking_reference,
        "created_at": order.created_at,
        "updated_at": order.updated_at,
    }


def _serialize_booking_intent_row(row) -> dict:
    intent, trip_title, user_email = row
    return {
        "id": intent.id,
        "user_id": intent.user_id,
        "user_email": user_email,
        "trip_id": intent.trip_id,
        "trip_title": trip_title,
        "type": intent.type,
        "status": intent.status,
        "amount": float(intent.amount),
        "currency": intent.currency,
        "stripe_payment_intent_id": intent.stripe_payment_intent_id,
        "created_at": intent.created_at,
        "updated_at": intent.updated_at,
    }


def _serialize_flight_search_row(row) -> dict:
    search, trip_title = row
    return {
        "id": search.id,
        "trip_id": search.trip_id,
        "trip_title": trip_title,
        "origin_iata": search.origin_iata,
        "destination_iata": search.destination_iata,
        "departure_date": search.departure_date,
        "return_date": search.return_date,
        "adults": search.adults,
        "children": search.children,
        "travel_class": search.travel_class,
        "created_at": search.created_at,
    }


class AdminBookingsService:
    """Admin operations over flight bookings, booking intents and flight searches."""

    @staticmethod
    def get_all_flight_bookings(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour toutes les flight bookings."""
        query = (
            db.query(
                FlightOrder,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, FlightOrder.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(FlightOrder.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_flight_booking_row
        ).as_tuple()

    @staticmethod
    def get_all_booking_intents(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les booking intents."""
        query = (
            db.query(
                BookingIntent,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, BookingIntent.trip_id == Trip.id)
            .join(User, BookingIntent.user_id == User.id)
            .order_by(BookingIntent.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_booking_intent_row
        ).as_tuple()

    @staticmethod
    def get_all_flight_searches(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour toutes les flight searches."""
        query = (
            db.query(FlightSearch, Trip.title.label("trip_title"))
            .join(Trip, FlightSearch.trip_id == Trip.id)
            .order_by(FlightSearch.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_flight_search_row
        ).as_tuple()

    @staticmethod
    def get_booking_intent_detail(db: Session, intent_id) -> dict:
        """Get detailed booking intent info."""
        result = (
            db.query(BookingIntent, User.email.label("user_email"), Trip.title.label("trip_title"))
            .join(User, BookingIntent.user_id == User.id)
            .join(Trip, BookingIntent.trip_id == Trip.id)
            .filter(BookingIntent.id == intent_id)
            .first()
        )
        if not result:
            raise AppError("NOT_FOUND", 404, "Booking intent not found")
        bi, user_email, trip_title = result
        return {
            "id": bi.id,
            "user_id": bi.user_id,
            "user_email": user_email,
            "trip_id": bi.trip_id,
            "trip_title": trip_title,
            "type": bi.type,
            "status": bi.status,
            "amount": float(bi.amount) if bi.amount else 0,
            "currency": bi.currency or "EUR",
            "stripe_payment_intent_id": bi.stripe_payment_intent_id,
            "stripe_charge_id": getattr(bi, "stripe_charge_id", None),
            "amadeus_order_id": getattr(bi, "amadeus_order_id", None),
            "last_error": getattr(bi, "last_error", None),
            "created_at": bi.created_at,
            "updated_at": bi.updated_at,
        }

    @staticmethod
    def force_booking_status(db: Session, intent_id, new_status: str) -> None:
        """Force a booking intent status (admin bypass — no state machine validation)."""
        bi = db.query(BookingIntent).filter(BookingIntent.id == intent_id).first()
        if not bi:
            raise AppError("NOT_FOUND", 404, "Booking intent not found")
        bi.status = new_status
        db.commit()
