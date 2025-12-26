"""Service pour la gestion des trips."""

from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.trip import Trip
from src.utils.errors import AppError


class TripsService:
    """Service pour les opérations CRUD sur les trips."""

    @staticmethod
    def create_trip(
        db: Session,
        user_id: UUID,
        title: str | None,
        origin_iata: str | None,
        destination_iata: str | None,
        start_date: str | date | None = None,
        end_date: str | date | None = None,
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

        db.commit()
        db.refresh(trip)
        return trip

    @staticmethod
    def delete_trip(db: Session, trip_id: UUID, user_id: UUID) -> None:
        """Supprimer un trip."""
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        db.delete(trip)
        db.commit()
