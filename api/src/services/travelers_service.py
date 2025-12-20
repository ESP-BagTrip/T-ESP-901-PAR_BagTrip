"""Service pour la gestion des travelers."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.traveler import TripTraveler
from src.services.trips_service import TripsService
from src.utils.errors import AppError


class TravelersService:
    """Service pour les opérations CRUD sur les travelers."""

    @staticmethod
    def create_traveler(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        amadeus_traveler_ref: str | None,
        traveler_type: str,
        first_name: str,
        last_name: str,
        date_of_birth: str | None = None,
        gender: str | None = None,
        documents: dict | None = None,
        contacts: dict | None = None,
        raw: dict | None = None,
    ) -> TripTraveler:
        """Créer un nouveau traveler."""
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        traveler = TripTraveler(
            trip_id=trip_id,
            amadeus_traveler_ref=amadeus_traveler_ref,
            traveler_type=traveler_type,
            first_name=first_name,
            last_name=last_name,
            date_of_birth=date_of_birth,
            gender=gender,
            documents=documents,
            contacts=contacts,
            raw=raw,
        )
        db.add(traveler)
        db.commit()
        db.refresh(traveler)
        return traveler

    @staticmethod
    def get_travelers_by_trip(db: Session, trip_id: UUID, user_id: UUID) -> list[TripTraveler]:
        """Récupérer tous les travelers d'un trip."""
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        return db.query(TripTraveler).filter(TripTraveler.trip_id == trip_id).all()

    @staticmethod
    def get_traveler_by_id(
        db: Session, traveler_id: UUID, trip_id: UUID, user_id: UUID
    ) -> TripTraveler | None:
        """Récupérer un traveler par ID."""
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        return (
            db.query(TripTraveler)
            .filter(TripTraveler.id == traveler_id, TripTraveler.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def update_traveler(
        db: Session,
        traveler_id: UUID,
        trip_id: UUID,
        user_id: UUID,
        amadeus_traveler_ref: str | None = None,
        traveler_type: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        date_of_birth: str | None = None,
        gender: str | None = None,
        documents: dict | None = None,
        contacts: dict | None = None,
        raw: dict | None = None,
    ) -> TripTraveler:
        """Mettre à jour un traveler."""
        traveler = TravelersService.get_traveler_by_id(db, traveler_id, trip_id, user_id)
        if not traveler:
            raise AppError("TRAVELER_NOT_FOUND", 404, "Traveler not found")

        if amadeus_traveler_ref is not None:
            traveler.amadeus_traveler_ref = amadeus_traveler_ref
        if traveler_type is not None:
            traveler.traveler_type = traveler_type
        if first_name is not None:
            traveler.first_name = first_name
        if last_name is not None:
            traveler.last_name = last_name
        if date_of_birth is not None:
            traveler.date_of_birth = date_of_birth
        if gender is not None:
            traveler.gender = gender
        if documents is not None:
            traveler.documents = documents
        if contacts is not None:
            traveler.contacts = contacts
        if raw is not None:
            traveler.raw = raw

        db.commit()
        db.refresh(traveler)
        return traveler

    @staticmethod
    def delete_traveler(db: Session, traveler_id: UUID, trip_id: UUID, user_id: UUID) -> None:
        """Supprimer un traveler."""
        traveler = TravelersService.get_traveler_by_id(db, traveler_id, trip_id, user_id)
        if not traveler:
            raise AppError("TRAVELER_NOT_FOUND", 404, "Traveler not found")

        db.delete(traveler)
        db.commit()

    @staticmethod
    def traveler_to_amadeus_payload(traveler: TripTraveler) -> dict:
        """
        Mapper un TripTraveler vers le payload Amadeus.
        Stocke le payload complet dans traveler.raw.
        """
        payload = {
            "id": traveler.amadeus_traveler_ref or str(traveler.id),
            "dateOfBirth": traveler.date_of_birth.isoformat() if traveler.date_of_birth else None,
            "name": {
                "firstName": traveler.first_name,
                "lastName": traveler.last_name,
            },
            "gender": traveler.gender,
            "contact": traveler.contacts or {},
            "documents": traveler.documents or [],
        }

        # Stocker le payload dans raw
        traveler.raw = payload
        return payload
