"""Service pour la gestion des trips."""

from datetime import UTC, date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.trip import Trip
from src.utils.errors import AppError


class TripsService:
    """Service pour les opérations CRUD sur les trips."""

    VALID_TRANSITIONS: dict[str, list[str]] = {
        "draft": ["planning"],
        "planning": ["active", "draft"],
        "active": ["completed"],
        "completed": ["archived"],
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
    ) -> Trip:
        """Créer un nouveau trip."""
        trip = Trip(
            user_id=user_id,
            title=title,
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            start_date=start_date,
            end_date=end_date,
            status="draft",
            description=description,
            destination_name=destination_name,
            nb_travelers=nb_travelers or 1,
            cover_image_url=cover_image_url,
        )
        db.add(trip)
        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_trips_by_user(db: Session, user_id: UUID) -> list[Trip]:
        """Récupérer tous les trips d'un utilisateur."""
        return db.query(Trip).filter(Trip.user_id == user_id).order_by(Trip.created_at.desc()).all()

    @staticmethod
    def get_trip_by_id(db: Session, trip_id: UUID, user_id: UUID) -> Trip | None:
        """Récupérer un trip par ID (vérifie que l'utilisateur en est propriétaire)."""
        trip = db.query(Trip).filter(Trip.id == trip_id, Trip.user_id == user_id).first()
        return trip

    @staticmethod
    def update_trip(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        title: str | None = None,
        origin_iata: str | None = None,
        destination_iata: str | None = None,
        start_date: str | None = None,
        end_date: str | None = None,
        status: str | None = None,
        description: str | None = None,
        destination_name: str | None = None,
        nb_travelers: int | None = None,
        cover_image_url: str | None = None,
    ) -> Trip:
        """Mettre à jour un trip."""
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

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
        if status is not None:
            trip.status = status
        if description is not None:
            trip.description = description
        if destination_name is not None:
            trip.destination_name = destination_name
        if nb_travelers is not None:
            trip.nb_travelers = nb_travelers
        if cover_image_url is not None:
            trip.cover_image_url = cover_image_url

        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_grouped_trips(db: Session, user_id: UUID) -> dict[str, list[Trip]]:
        """Récupérer les trips groupés par statut."""
        trips = db.query(Trip).filter(Trip.user_id == user_id).order_by(Trip.created_at.desc()).all()

        grouped: dict[str, list[Trip]] = {
            "active": [],
            "planning": [],
            "completed": [],
            "archived": [],
        }

        for trip in trips:
            status = trip.status or "draft"
            if status in ("draft", "planning", "planned"):
                grouped["planning"].append(trip)
            elif status == "active":
                grouped["active"].append(trip)
            elif status == "completed":
                grouped["completed"].append(trip)
            elif status == "archived":
                grouped["archived"].append(trip)
            else:
                grouped["planning"].append(trip)

        return grouped

    @staticmethod
    def update_trip_status(
        db: Session, trip_id: UUID, user_id: UUID, new_status: str
    ) -> Trip:
        """Mettre à jour le statut d'un trip avec validation des transitions."""
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        current_status = trip.status or "draft"
        allowed = TripsService.VALID_TRANSITIONS.get(current_status, [])

        if new_status not in allowed:
            raise AppError(
                "INVALID_STATUS_TRANSITION",
                400,
                f"Cannot transition from '{current_status}' to '{new_status}'. "
                f"Allowed transitions: {allowed}",
            )

        trip.status = new_status
        if new_status == "archived":
            trip.archived_at = datetime.now(UTC)

        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def get_trip_home(db: Session, trip_id: UUID, user_id: UUID) -> dict:
        """Récupérer les données de la page d'accueil d'un trip."""
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

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
            {"id": "baggage", "label": "Bagages", "icon": "luggage", "route": "baggage", "enabled": False},
            {"id": "budget", "label": "Budget", "icon": "wallet", "route": "budget", "enabled": False},
            {"id": "accommodation", "label": "Hébergement", "icon": "hotel", "route": "accommodation", "enabled": False},
            {"id": "activities", "label": "Activités", "icon": "hiking", "route": "activities", "enabled": False},
            {"id": "transport", "label": "Transport", "icon": "directions_car", "route": "transport", "enabled": False},
            {"id": "map", "label": "Carte", "icon": "map", "route": "map", "enabled": False},
        ]

        return {"trip": trip, "stats": stats, "features": features}

    @staticmethod
    def delete_trip(db: Session, trip_id: UUID, user_id: UUID) -> None:
        """Supprimer un trip."""
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        db.delete(trip)
        db.commit()
