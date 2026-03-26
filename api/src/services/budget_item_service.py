from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import BudgetCategory, TripStatus
from src.models.activity import Activity
from src.models.budget_item import BudgetItem
from src.models.trip import Trip
from src.utils.errors import AppError


class BudgetItemService:
    """Service for BudgetItem CRUD operations."""

    @staticmethod
    def _check_trip_not_completed(trip: Trip) -> None:
        if trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify budget items on a completed trip.",
            )

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
        BudgetItemService._check_trip_not_completed(trip)
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
    def find_by_source(db: Session, source_type: str, source_id: UUID) -> BudgetItem | None:
        return (
            db.query(BudgetItem)
            .filter(BudgetItem.source_type == source_type, BudgetItem.source_id == source_id)
            .first()
        )

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
        BudgetItemService._check_trip_not_completed(trip)
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
        BudgetItemService._check_trip_not_completed(trip)
        item = BudgetItemService.get_by_id(db, item_id, trip.id)
        db.delete(item)
        db.commit()

    @staticmethod
    def get_budget_summary(db: Session, trip: Trip) -> dict:
        items = BudgetItemService.get_by_trip(db, trip.id)
        total_spent = sum(float(i.amount) for i in items)
        by_category: dict[str, float] = {}
        for item in items:
            cat = item.category or BudgetCategory.OTHER
            by_category[cat] = by_category.get(cat, 0.0) + float(item.amount)

        budget_total = float(trip.budget_total) if trip.budget_total else 0.0

        # Confirmed vs forecasted — budget items
        confirmed_total = 0.0
        forecasted_total = 0.0
        for item in items:
            if item.source_type is not None or not item.is_planned:
                confirmed_total += float(item.amount)
            elif item.is_planned and item.source_type is None:
                forecasted_total += float(item.amount)

        # Confirmed vs forecasted — activities
        activities = db.query(Activity).filter(Activity.trip_id == trip.id).all()
        for activity in activities:
            if activity.estimated_cost is None:
                continue
            cost = float(activity.estimated_cost)
            if activity.validation_status in ("VALIDATED", "MANUAL"):
                confirmed_total += cost
            elif activity.validation_status == "SUGGESTED":
                forecasted_total += cost

        alert_level = None
        alert_message = None
        if budget_total > 0:
            ratio = total_spent / budget_total
            if ratio >= 1.0:
                alert_level = "DANGER"
                over = total_spent - budget_total
                alert_message = f"Budget exceeded by {over:.2f} €"
            elif ratio >= 0.8:
                alert_level = "WARNING"
                pct = ratio * 100
                alert_message = f"{pct:.0f}% of your budget has been used"

        return {
            "total_budget": budget_total,
            "total_spent": total_spent,
            "remaining": budget_total - total_spent,
            "by_category": by_category,
            "alert_level": alert_level,
            "alert_message": alert_message,
            "confirmed_total": confirmed_total,
            "forecasted_total": forecasted_total,
        }
