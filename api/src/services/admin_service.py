"""Service pour les opérations admin (sans filtrage par utilisateur)."""

from math import ceil

from sqlalchemy.orm import Session

from src.models.booking_intent import BookingIntent
from src.models.flight_order import FlightOrder
from src.models.flight_search import FlightSearch
from src.models.traveler import TripTraveler
from src.models.traveler_profile import TravelerProfile
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
                    "budget_total": trip.budget_total,
                    "origin": trip.origin,
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

    @staticmethod
    def get_all_traveler_profiles(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les profils voyageurs avec informations utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

        query = (
            db.query(
                TravelerProfile,
                User.email.label("user_email"),
            )
            .join(User, TravelerProfile.user_id == User.id)
            .order_by(TravelerProfile.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for profile, user_email in results:
            items.append(
                {
                    "id": profile.id,
                    "user_id": profile.user_id,
                    "user_email": user_email,
                    "travel_types": profile.travel_types,
                    "travel_style": profile.travel_style,
                    "budget": profile.budget,
                    "companions": profile.companions,
                    "is_completed": profile.is_completed,
                    "created_at": profile.created_at,
                    "updated_at": profile.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_booking_intents(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les booking intents avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for intent, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_flight_searches(
        db: Session, page: int = 1, limit: int = 10
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les recherches de vols avec informations trip.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

        query = (
            db.query(
                FlightSearch,
                Trip.title.label("trip_title"),
            )
            .join(Trip, FlightSearch.trip_id == Trip.id)
            .order_by(FlightSearch.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for search, trip_title in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages
