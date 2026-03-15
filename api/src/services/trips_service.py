"""Service pour la gestion des trips."""

from datetime import UTC, date, datetime
from math import ceil
from uuid import UUID

from sqlalchemy import literal_column, update
from sqlalchemy.orm import Session

from src.enums import FlightOrderStatus, NotificationType, TripOrigin, TripStatus
from src.models.booking_intent import BookingIntent
from src.models.flight_order import FlightOrder
from src.models.stripe_event import StripeEvent
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.utils.errors import AppError


class TripsService:
    """Service pour les opérations CRUD sur les trips."""

    VALID_TRANSITIONS: dict[str, list[str]] = {
        TripStatus.DRAFT: [TripStatus.PLANNED],
        TripStatus.PLANNED: [TripStatus.ONGOING],
        TripStatus.ONGOING: [TripStatus.COMPLETED],
    }

    @staticmethod
    def create_trip(
        db: Session,
        user_id: UUID,
        title: str | None,
        origin_iata: str | None,
        destination_iata: str | None,
        start_date: str | date | None = None,
        end_date: str | date | None = None,
        description: str | None = None,
        destination_name: str | None = None,
        nb_travelers: int | None = None,
        cover_image_url: str | None = None,
        budget_total: float | None = None,
        origin: str | None = None,
    ) -> Trip:
        """Créer un nouveau trip."""
        trip = Trip(
            user_id=user_id,
            title=title,
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            start_date=start_date,
            end_date=end_date,
            status=TripStatus.DRAFT,
            description=description,
            destination_name=destination_name,
            nb_travelers=nb_travelers or 1,
            cover_image_url=cover_image_url,
            budget_total=budget_total,
            origin=origin or TripOrigin.MANUAL,
        )
        db.add(trip)
        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_trips_by_user(db: Session, user_id: UUID) -> list[tuple[Trip, str]]:
        """Récupérer tous les trips d'un utilisateur (owned + shared)."""
        owned = db.query(Trip, literal_column("'OWNER'").label("role")).filter(
            Trip.user_id == user_id
        )
        shared = (
            db.query(Trip, TripShare.role)
            .join(TripShare, TripShare.trip_id == Trip.id)
            .filter(TripShare.user_id == user_id)
        )
        return owned.union_all(shared).order_by(Trip.created_at.desc()).all()

    @staticmethod
    def get_trips_by_user_paginated(
        db: Session,
        user_id: UUID,
        page: int = 1,
        limit: int = 20,
        status: str | None = None,
    ) -> tuple[list[tuple[Trip, str]], int, int]:
        """Get paginated trips for a user. Returns (items, total, total_pages)."""
        owned = db.query(Trip, literal_column("'OWNER'").label("role")).filter(
            Trip.user_id == user_id
        )
        shared = (
            db.query(Trip, TripShare.role)
            .join(TripShare, TripShare.trip_id == Trip.id)
            .filter(TripShare.user_id == user_id)
        )
        query = owned.union_all(shared)
        if status:
            status_map = {
                "ongoing": [TripStatus.ONGOING, "active"],
                "planned": [TripStatus.DRAFT, TripStatus.PLANNED, "draft", "planning", "planned"],
                "completed": [TripStatus.COMPLETED, "completed", "archived"],
            }
            allowed = status_map.get(status, [status])
            query = query.filter(Trip.status.in_(allowed))
        query = query.order_by(Trip.created_at.desc())
        total = query.count()
        total_pages = ceil(total / limit) if limit > 0 else 0
        items = query.offset((page - 1) * limit).limit(limit).all()
        return items, total, total_pages

    @staticmethod
    def get_trip_by_id(db: Session, trip_id: UUID, user_id: UUID) -> Trip | None:
        """Récupérer un trip par ID (vérifie que l'utilisateur en est propriétaire)."""
        return db.query(Trip).filter(Trip.id == trip_id, Trip.user_id == user_id).first()

    @staticmethod
    def update_trip(
        db: Session,
        trip: Trip,
        title: str | None = None,
        origin_iata: str | None = None,
        destination_iata: str | None = None,
        start_date: str | None = None,
        end_date: str | None = None,
        description: str | None = None,
        destination_name: str | None = None,
        nb_travelers: int | None = None,
        cover_image_url: str | None = None,
        budget_total: float | None = None,
    ) -> Trip:
        """Mettre à jour un trip (ownership déjà vérifiée par la dependency)."""
        if trip.status == TripStatus.COMPLETED:
            raise AppError("TRIP_COMPLETED", 403, "Cannot modify a completed trip.")

        if title is not None:
            trip.title = title
        if origin_iata is not None:
            trip.origin_iata = origin_iata
        if destination_iata is not None:
            trip.destination_iata = destination_iata
        if start_date is not None:
            trip.start_date = start_date
        if end_date is not None:
            trip.end_date = end_date
        if description is not None:
            trip.description = description
        if destination_name is not None:
            trip.destination_name = destination_name
        if nb_travelers is not None:
            trip.nb_travelers = nb_travelers
        if cover_image_url is not None:
            trip.cover_image_url = cover_image_url
        if budget_total is not None:
            trip.budget_total = budget_total

        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_grouped_trips(db: Session, user_id: UUID) -> dict[str, list[tuple[Trip, str]]]:
        """Récupérer les trips groupés par statut (owned + shared)."""
        rows = TripsService.get_trips_by_user(db, user_id)

        grouped: dict[str, list[tuple[Trip, str]]] = {
            "ongoing": [],
            "planned": [],
            "completed": [],
        }

        for trip, role in rows:
            trip_status = trip.status or TripStatus.DRAFT
            if trip_status in (TripStatus.DRAFT, TripStatus.PLANNED, "draft", "planning", "planned"):
                grouped["planned"].append((trip, role))
            elif trip_status in (TripStatus.ONGOING, "active"):
                grouped["ongoing"].append((trip, role))
            elif trip_status in (TripStatus.COMPLETED, "completed", "archived"):
                grouped["completed"].append((trip, role))
            else:
                grouped["planned"].append((trip, role))

        return grouped

    @staticmethod
    def update_trip_status(db: Session, trip: Trip, new_status: str) -> Trip:
        """Mettre à jour le statut d'un trip (ownership déjà vérifiée)."""
        current_status = trip.status or TripStatus.DRAFT
        allowed = TripsService.VALID_TRANSITIONS.get(current_status, [])

        if new_status not in allowed:
            raise AppError(
                "INVALID_STATUS_TRANSITION",
                400,
                f"Cannot transition from '{current_status}' to '{new_status}'. "
                f"Allowed transitions: {allowed}",
            )

        # S11: validate required fields before DRAFT→PLANNED
        if current_status == TripStatus.DRAFT and new_status == TripStatus.PLANNED:
            missing = []
            if not trip.destination_iata and not trip.destination_name:
                missing.append("destination")
            if not trip.start_date:
                missing.append("start_date")
            if not trip.end_date:
                missing.append("end_date")
            if missing:
                raise AppError(
                    "TRIP_INCOMPLETE",
                    400,
                    f"Cannot plan trip: missing {', '.join(missing)}",
                )
            if trip.start_date and trip.end_date and trip.start_date > trip.end_date:
                raise AppError(
                    "INVALID_DATES",
                    400,
                    "start_date must be before or equal to end_date",
                )

        trip.status = new_status

        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_trip_home(db: Session, trip: Trip) -> dict:
        """Récupérer les données de la page d'accueil d'un trip."""
        now = date.today()
        days_until_trip = None
        trip_duration = None

        if trip.start_date:
            delta = trip.start_date - now
            days_until_trip = max(0, delta.days)

        if trip.start_date and trip.end_date:
            trip_duration = (trip.end_date - trip.start_date).days

        stats = {
            "baggageCount": 0,
            "totalExpenses": 0.0,
            "nbTravelers": trip.nb_travelers or 1,
            "daysUntilTrip": days_until_trip,
            "tripDuration": trip_duration,
        }

        features = [
            {"id": "baggage", "label": "Bagages", "icon": "luggage", "route": "baggage", "enabled": True},
            {"id": "budget", "label": "Budget", "icon": "wallet", "route": "budget", "enabled": False},
            {"id": "accommodation", "label": "Hébergement", "icon": "hotel", "route": "accommodations", "enabled": True},
            {"id": "activities", "label": "Activités", "icon": "hiking", "route": "activities", "enabled": False},
            {"id": "transport", "label": "Transport", "icon": "directions_car", "route": "transport", "enabled": False},
            {"id": "map", "label": "Carte", "icon": "map", "route": "map", "enabled": False},
        ]

        return {"trip": trip, "stats": stats, "features": features}

    @staticmethod
    def auto_transition_statuses(db: Session) -> tuple[int, int]:
        """Bulk-update trip statuses based on dates (daily job).

        - PLANNED → ONGOING when start_date <= today
        - ONGOING → COMPLETED when end_date < today
        Returns (planned_to_ongoing, ongoing_to_completed) counts.
        Also sends TRIP_ENDED notifications for newly completed trips.
        """
        today = datetime.now(UTC).date()

        planned_to_ongoing = db.execute(
            update(Trip)
            .where(Trip.status == TripStatus.PLANNED, Trip.start_date.isnot(None), Trip.start_date <= today)
            .values(status=TripStatus.ONGOING)
        ).rowcount

        # Capture trips that will transition ONGOING→COMPLETED before updating
        completing_trips = (
            db.query(Trip)
            .filter(Trip.status == TripStatus.ONGOING, Trip.end_date.isnot(None), Trip.end_date < today)
            .all()
        )

        ongoing_to_completed = db.execute(
            update(Trip)
            .where(Trip.status == TripStatus.ONGOING, Trip.end_date.isnot(None), Trip.end_date < today)
            .values(status=TripStatus.COMPLETED)
        ).rowcount

        db.commit()

        # Send TRIP_ENDED notifications for newly completed trips
        if completing_trips:
            from src.services.notification_service import NotificationService

            for trip in completing_trips:
                try:
                    recipients = NotificationService._get_trip_recipients(db, trip)
                    NotificationService.create_and_send_bulk(
                        db=db,
                        user_ids=recipients,
                        trip_id=trip.id,
                        notif_type=NotificationType.TRIP_ENDED,
                        title="Voyage terminé !",
                        body=f"Votre voyage « {trip.title or 'sans titre'} » est terminé. Partagez votre avis !",
                        data={"screen": "feedback", "tripId": str(trip.id)},
                    )
                except Exception:
                    pass

        return planned_to_ongoing, ongoing_to_completed

    @staticmethod
    def delete_trip(db: Session, trip: Trip) -> None:
        """Supprimer un trip DRAFT (ownership déjà vérifiée)."""
        if trip.status != TripStatus.DRAFT:
            raise AppError(
                "TRIP_NOT_DRAFT",
                409,
                "Only trips in DRAFT status can be deleted.",
            )

        confirmed_flight = (
            db.query(FlightOrder)
            .filter(FlightOrder.trip_id == trip.id, FlightOrder.status == FlightOrderStatus.CONFIRMED)
            .first()
        )
        if confirmed_flight:
            raise AppError(
                "TRIP_HAS_CONFIRMED_FLIGHT",
                409,
                "Cannot delete a trip with a confirmed flight order.",
            )

        # Nullify StripeEvent.booking_intent_id for BookingIntents of this trip
        booking_intent_ids = (
            db.query(BookingIntent.id).filter(BookingIntent.trip_id == trip.id).subquery()
        )
        db.query(StripeEvent).filter(
            StripeEvent.booking_intent_id.in_(booking_intent_ids)
        ).update({StripeEvent.booking_intent_id: None}, synchronize_session="fetch")

        # Delete FlightOrders of this trip (no cascade from Trip)
        db.query(FlightOrder).filter(FlightOrder.trip_id == trip.id).delete(
            synchronize_session="fetch"
        )

        db.delete(trip)
        db.commit()
