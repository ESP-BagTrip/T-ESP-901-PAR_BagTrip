"""Service pour la gestion des baggage items."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.baggage_item import BaggageItem
from src.utils.errors import AppError


class BaggageItemsService:
    """Service pour les opérations CRUD sur les baggage items."""

    @staticmethod
    def create_baggage_item(
        db: Session,
        trip_id: UUID,
        name: str,
        quantity: int | None = None,
        is_packed: bool | None = None,
        category: str | None = None,
        notes: str | None = None,
    ) -> BaggageItem:
        """Créer un nouvel élément de bagage (accès vérifié par la dependency)."""
        baggage_item = BaggageItem(
            trip_id=trip_id,
            name=name,
            quantity=quantity,
            is_packed=is_packed,
            category=category,
            notes=notes,
        )
        db.add(baggage_item)
        db.commit()
        db.refresh(baggage_item)
        return baggage_item

    @staticmethod
    def get_baggage_items_by_trip(db: Session, trip_id: UUID) -> list[BaggageItem]:
        """Récupérer tous les éléments de bagage d'un trip."""
        return db.query(BaggageItem).filter(BaggageItem.trip_id == trip_id).all()

    @staticmethod
    def get_baggage_item_by_id(
        db: Session, baggage_item_id: UUID, trip_id: UUID
    ) -> BaggageItem | None:
        """Récupérer un élément de bagage par ID."""
        return (
            db.query(BaggageItem)
            .filter(BaggageItem.id == baggage_item_id, BaggageItem.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def update_baggage_item(
        db: Session,
        baggage_item_id: UUID,
        trip_id: UUID,
        name: str | None = None,
        quantity: int | None = None,
        is_packed: bool | None = None,
        category: str | None = None,
        notes: str | None = None,
    ) -> BaggageItem:
        """Mettre à jour un élément de bagage (accès vérifié par la dependency)."""
        baggage_item = BaggageItemsService.get_baggage_item_by_id(db, baggage_item_id, trip_id)
        if not baggage_item:
            raise AppError("BAGGAGE_ITEM_NOT_FOUND", 404, "Baggage item not found")

        if name is not None:
            baggage_item.name = name
        if quantity is not None:
            baggage_item.quantity = quantity
        if is_packed is not None:
            baggage_item.is_packed = is_packed
        if category is not None:
            baggage_item.category = category
        if notes is not None:
            baggage_item.notes = notes

        db.commit()
        db.refresh(baggage_item)
        return baggage_item

    @staticmethod
    def delete_baggage_item(db: Session, baggage_item_id: UUID, trip_id: UUID) -> None:
        """Supprimer un élément de bagage (accès vérifié par la dependency)."""
        baggage_item = BaggageItemsService.get_baggage_item_by_id(db, baggage_item_id, trip_id)
        if not baggage_item:
            raise AppError("BAGGAGE_ITEM_NOT_FOUND", 404, "Baggage item not found")

        db.delete(baggage_item)
        db.commit()
