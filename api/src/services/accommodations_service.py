"""Service pour la gestion des accommodations."""

from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.accommodation import Accommodation
from src.utils.errors import AppError


class AccommodationsService:
    """Service pour les opérations CRUD sur les accommodations."""

    @staticmethod
    def create_accommodation(
        db: Session,
        trip_id: UUID,
        name: str,
        address: str | None = None,
        check_in: date | None = None,
        check_out: date | None = None,
        price: Decimal | None = None,
        currency: str | None = None,
        booking_reference: str | None = None,
        notes: str | None = None,
    ) -> Accommodation:
        """Créer un nouvel hébergement (accès vérifié par la dependency)."""
        accommodation = Accommodation(
            trip_id=trip_id,
            name=name,
            address=address,
            check_in=check_in,
            check_out=check_out,
            price=price,
            currency=currency,
            booking_reference=booking_reference,
            notes=notes,
        )
        db.add(accommodation)
        db.commit()
        db.refresh(accommodation)
        return accommodation

    @staticmethod
    def get_accommodations_by_trip(db: Session, trip_id: UUID) -> list[Accommodation]:
        """Récupérer tous les hébergements d'un trip."""
        return db.query(Accommodation).filter(Accommodation.trip_id == trip_id).all()

    @staticmethod
    def get_accommodation_by_id(
        db: Session, accommodation_id: UUID, trip_id: UUID
    ) -> Accommodation | None:
        """Récupérer un hébergement par ID."""
        return (
            db.query(Accommodation)
            .filter(Accommodation.id == accommodation_id, Accommodation.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def update_accommodation(
        db: Session,
        accommodation_id: UUID,
        trip_id: UUID,
        name: str | None = None,
        address: str | None = None,
        check_in: date | None = None,
        check_out: date | None = None,
        price: Decimal | None = None,
        currency: str | None = None,
        booking_reference: str | None = None,
        notes: str | None = None,
    ) -> Accommodation:
        """Mettre à jour un hébergement (accès vérifié par la dependency)."""
        accommodation = AccommodationsService.get_accommodation_by_id(db, accommodation_id, trip_id)
        if not accommodation:
            raise AppError("ACCOMMODATION_NOT_FOUND", 404, "Accommodation not found")

        if name is not None:
            accommodation.name = name
        if address is not None:
            accommodation.address = address
        if check_in is not None:
            accommodation.check_in = check_in
        if check_out is not None:
            accommodation.check_out = check_out
        if price is not None:
            accommodation.price = price
        if currency is not None:
            accommodation.currency = currency
        if booking_reference is not None:
            accommodation.booking_reference = booking_reference
        if notes is not None:
            accommodation.notes = notes

        db.commit()
        db.refresh(accommodation)
        return accommodation

    @staticmethod
    def delete_accommodation(db: Session, accommodation_id: UUID, trip_id: UUID) -> None:
        """Supprimer un hébergement (accès vérifié par la dependency)."""
        accommodation = AccommodationsService.get_accommodation_by_id(db, accommodation_id, trip_id)
        if not accommodation:
            raise AppError("ACCOMMODATION_NOT_FOUND", 404, "Accommodation not found")

        db.delete(accommodation)
        db.commit()
