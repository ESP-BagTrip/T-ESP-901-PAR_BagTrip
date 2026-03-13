from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.budget_item import BudgetItem
from src.models.trip import Trip
from src.utils.errors import AppError


class BudgetItemService:
    """Service for BudgetItem CRUD operations."""

    @staticmethod
    def create(
        db: Session,
        trip: Trip,
        label: str,
        amount: float,
        category: str = "OTHER",
        date: date | None = None,
        is_planned: bool = True,
    ) -> BudgetItem:
        item = BudgetItem(
            trip_id=trip.id,
            label=label,
            amount=amount,
            category=category,
            date=date,
            is_planned=is_planned,
        )
        db.add(item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def get_by_trip(db: Session, trip_id: UUID) -> list[BudgetItem]:
        return (
            db.query(BudgetItem)
            .filter(BudgetItem.trip_id == trip_id)
            .order_by(BudgetItem.created_at.desc())
            .all()
        )

    @staticmethod
    def get_by_id(db: Session, item_id: UUID, trip_id: UUID) -> BudgetItem:
        item = (
            db.query(BudgetItem)
            .filter(BudgetItem.id == item_id, BudgetItem.trip_id == trip_id)
            .first()
        )
        if not item:
            raise AppError("BUDGET_ITEM_NOT_FOUND", 404, "Budget item not found")
        return item

    @staticmethod
    def update(
        db: Session,
        trip: Trip,
        item_id: UUID,
        label: str | None = None,
        amount: float | None = None,
        category: str | None = None,
        date: date | None = None,
        is_planned: bool | None = None,
    ) -> BudgetItem:
        item = BudgetItemService.get_by_id(db, item_id, trip.id)

        if label is not None:
            item.label = label
        if amount is not None:
            item.amount = amount
        if category is not None:
            item.category = category
        if date is not None:
            item.date = date
        if is_planned is not None:
            item.is_planned = is_planned

        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def delete(db: Session, trip: Trip, item_id: UUID) -> None:
        item = BudgetItemService.get_by_id(db, item_id, trip.id)
        db.delete(item)
        db.commit()

    @staticmethod
    def get_budget_summary(db: Session, trip: Trip) -> dict:
        items = BudgetItemService.get_by_trip(db, trip.id)
        total_spent = sum(float(i.amount) for i in items)
        by_category: dict[str, float] = {}
        for item in items:
            cat = item.category or "OTHER"
            by_category[cat] = by_category.get(cat, 0.0) + float(item.amount)

        budget_total = float(trip.budget_total) if trip.budget_total else 0.0
        return {
            "total_budget": budget_total,
            "total_spent": total_spent,
            "remaining": budget_total - total_spent,
            "by_category": by_category,
        }
