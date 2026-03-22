"""Service pour la gestion des baggage items."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import TripStatus
from src.models.baggage_item import BaggageItem
from src.models.trip import Trip
from src.utils.errors import AppError
from src.utils.logger import logger


class BaggageItemsService:
    """Service pour les opérations CRUD sur les baggage items."""

    @staticmethod
    def _check_trip_not_completed(trip: Trip) -> None:
        if trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify baggage items on a completed trip.",
            )

    @staticmethod
    def create_baggage_item(
        db: Session,
        trip: Trip,
        name: str,
        quantity: int | None = None,
        is_packed: bool | None = None,
        category: str | None = None,
        notes: str | None = None,
    ) -> BaggageItem:
        """Créer un nouvel élément de bagage (accès vérifié par la dependency)."""
        BaggageItemsService._check_trip_not_completed(trip)
        baggage_item = BaggageItem(
            trip_id=trip.id,
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
        trip: Trip,
        name: str | None = None,
        quantity: int | None = None,
        is_packed: bool | None = None,
        category: str | None = None,
        notes: str | None = None,
    ) -> BaggageItem:
        """Mettre à jour un élément de bagage (accès vérifié par la dependency)."""
        BaggageItemsService._check_trip_not_completed(trip)
        baggage_item = BaggageItemsService.get_baggage_item_by_id(db, baggage_item_id, trip.id)
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
    def delete_baggage_item(db: Session, baggage_item_id: UUID, trip: Trip) -> None:
        """Supprimer un élément de bagage (accès vérifié par la dependency)."""
        BaggageItemsService._check_trip_not_completed(trip)
        baggage_item = BaggageItemsService.get_baggage_item_by_id(db, baggage_item_id, trip.id)
        if not baggage_item:
            raise AppError("BAGGAGE_ITEM_NOT_FOUND", 404, "Baggage item not found")

        db.delete(baggage_item)
        db.commit()

    @staticmethod
    async def suggest_baggage_items(db: Session, trip: Trip) -> list[dict]:
        """Suggest baggage items via AI, deduplicating against existing items."""
        from src.agent.prompts import BAGGAGE_PROMPT
        from src.services.llm_service import LLMService

        # Build prompt from trip data
        parts = [
            f"Destination: {trip.destination_name or 'Unknown'}",
        ]

        if trip.start_date and trip.end_date:
            duration = (trip.end_date - trip.start_date).days
            parts.append(f"Trip duration: {duration} days")

        # Include activities if loaded
        if trip.activities:
            activity_titles = [a.title for a in trip.activities[:8]]
            parts.append(f"Planned activities: {', '.join(activity_titles)}")

        if trip.nb_travelers:
            parts.append(f"Number of travelers: {trip.nb_travelers}")

        user_prompt = "\n".join(parts)

        # Call LLM
        llm = LLMService()
        try:
            result = await llm.acall_llm(BAGGAGE_PROMPT, user_prompt)
            items = result.get("items", [])
        except Exception as e:
            logger.error("Baggage suggest LLM call failed", {"error": str(e)})
            items = _default_baggage_items()

        # Deduplicate against existing items
        existing = BaggageItemsService.get_baggage_items_by_trip(db, trip.id)
        existing_names = {b.name.lower() for b in existing}
        filtered = [i for i in items if i.get("name", "").lower() not in existing_names]

        return filtered


def _default_baggage_items() -> list[dict]:
    """Fallback baggage items if LLM fails."""
    return [
        {"name": "Passport", "quantity": 1, "category": "DOCUMENTS", "reason": "Essential travel document"},
        {"name": "Travel adapter", "quantity": 1, "category": "ELECTRONICS", "reason": "Power adapter"},
        {"name": "Sunscreen", "quantity": 1, "category": "TOILETRIES", "reason": "Sun protection"},
        {"name": "First aid kit", "quantity": 1, "category": "HEALTH", "reason": "Emergency kit"},
        {"name": "Phone charger", "quantity": 1, "category": "ELECTRONICS", "reason": "Keep devices charged"},
        {"name": "Change of clothes", "quantity": 3, "category": "CLOTHING", "reason": "Daily wear"},
    ]
