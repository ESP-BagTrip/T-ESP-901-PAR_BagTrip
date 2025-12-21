"""Service pour les opérations admin (sans filtrage par utilisateur)."""

from math import ceil

from sqlalchemy.orm import Session

from src.models.flight_order import FlightOrder
from src.models.hotel_booking import HotelBooking
from src.models.hotel_offer import HotelOffer
from src.models.traveler import TripTraveler
from src.models.trip import Trip
from src.models.user import User


class AdminService:
    """Service pour les opérations admin."""

    @staticmethod
    def get_all_users(db: Session, page: int = 1, limit: int = 10) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les utilisateurs.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête pour obtenir tous les utilisateurs
        query = db.query(User).order_by(User.created_at.desc())

        # Compter le total
        total = query.count()

        # Paginer
        users = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for user in users:
            items.append(
                {
                    "id": user.id,
                    "email": user.email,
                    "created_at": user.created_at,
                    "updated_at": user.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_trips(db: Session, page: int = 1, limit: int = 10) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les trips avec informations utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec join pour obtenir l'email de l'utilisateur
        query = (
            db.query(
                Trip,
                User.email.label("user_email"),
            )
            .join(User, Trip.user_id == User.id)
            .order_by(Trip.created_at.desc())
        )

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for trip, user_email in results:
            items.append(
                {
                    "id": trip.id,
                    "user_id": trip.user_id,
                    "user_email": user_email,
                    "title": trip.title,
                    "origin_iata": trip.origin_iata,
                    "destination_iata": trip.destination_iata,
                    "start_date": trip.start_date,
                    "end_date": trip.end_date,
                    "status": trip.status,
                    "created_at": trip.created_at,
                    "updated_at": trip.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_travelers(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les travelers avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec joins pour obtenir trip title et user email
        query = (
            db.query(
                TripTraveler,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, TripTraveler.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(TripTraveler.created_at.desc())
        )

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for traveler, trip_title, user_email in results:
            items.append(
                {
                    "id": traveler.id,
                    "trip_id": traveler.trip_id,
                    "trip_title": trip_title,
                    "user_email": user_email,
                    "amadeus_traveler_ref": traveler.amadeus_traveler_ref,
                    "traveler_type": traveler.traveler_type,
                    "first_name": traveler.first_name,
                    "last_name": traveler.last_name,
                    "date_of_birth": traveler.date_of_birth,
                    "gender": traveler.gender,
                    "created_at": traveler.created_at,
                    "updated_at": traveler.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_hotel_bookings(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les hotel bookings avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec joins pour obtenir trip title, user email, et hotel_id
        query = (
            db.query(
                HotelBooking,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
                HotelOffer.hotel_id.label("hotel_id"),
            )
            .join(Trip, HotelBooking.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .join(HotelOffer, HotelBooking.hotel_offer_id == HotelOffer.id)
            .order_by(HotelBooking.created_at.desc())
        )

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for booking, trip_title, user_email, hotel_id in results:
            items.append(
                {
                    "id": booking.id,
                    "trip_id": booking.trip_id,
                    "trip_title": trip_title,
                    "user_email": user_email,
                    "hotel_offer_id": booking.hotel_offer_id,
                    "hotel_id": hotel_id,
                    "booking_intent_id": booking.booking_intent_id,
                    "amadeus_booking_id": booking.amadeus_booking_id,
                    "status": booking.status,
                    "created_at": booking.created_at,
                    "updated_at": booking.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_flight_bookings(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les flight bookings avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec joins pour obtenir trip title et user email
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

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for order, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages
