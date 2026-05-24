"""Service pour la gestion des vols manuels."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import BudgetCategory, TripStatus
from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.models.trip import Trip
from src.services.budget_item_service import BudgetItemService
from src.utils.errors import AppError


class ManualFlightService:
    """Service pour les opérations CRUD sur les vols manuels."""

    @staticmethod
    def _check_trip_not_completed(trip: Trip) -> None:
        if trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify flights on a completed trip.",
            )

    @staticmethod
    def create_manual_flight(
        db: Session,
        trip: Trip,
        flight_number: str,
        airline: str | None = None,
        departure_airport: str | None = None,
        arrival_airport: str | None = None,
        departure_date: datetime | None = None,
        arrival_date: datetime | None = None,
        price: Decimal | None = None,
        currency: str | None = None,
        notes: str | None = None,
        flight_type: str = "MAIN",
    ) -> ManualFlight:
        """Créer un vol manuel."""
        ManualFlightService._check_trip_not_completed(trip)
        flight = ManualFlight(
            trip_id=trip.id,
            flight_number=flight_number.upper().strip(),
            airline=airline,
            departure_airport=departure_airport,
            arrival_airport=arrival_airport,
            departure_date=departure_date,
            arrival_date=arrival_date,
            price=price,
            currency=currency,
            notes=notes,
            flight_type=flight_type,
        )
        db.add(flight)

        if flight.price is not None:
            db.add(
                BudgetItem(
                    trip_id=trip.id,
                    label=f"Vol : {flight.flight_number}",
                    amount=flight.price,
                    category=BudgetCategory.FLIGHT,
                    date=departure_date.date() if departure_date else None,
                    is_planned=True,
                    source_type="manual_flight",
                    source_id=flight.id,
                )
            )

        db.commit()
        db.refresh(flight)
        return flight

    @staticmethod
    def get_manual_flights_by_trip(db: Session, trip_id: UUID) -> list[ManualFlight]:
        """Récupérer tous les vols manuels d'un trip."""
        return db.query(ManualFlight).filter(ManualFlight.trip_id == trip_id).all()

    @staticmethod
    def get_manual_flight_by_id(db: Session, flight_id: UUID, trip_id: UUID) -> ManualFlight | None:
        """Récupérer un vol manuel par ID."""
        return (
            db.query(ManualFlight)
            .filter(ManualFlight.id == flight_id, ManualFlight.trip_id == trip_id)
            .first()
        )

    @staticmethod
    def update_manual_flight(
        db: Session,
        flight_id: UUID,
        trip: Trip,
        flight_number: str | None = None,
        airline: str | None = None,
        departure_airport: str | None = None,
        arrival_airport: str | None = None,
        departure_date: datetime | None = None,
        arrival_date: datetime | None = None,
        price: Decimal | None = ...,
        currency: str | None = None,
        notes: str | None = None,
        flight_type: str | None = None,
    ) -> ManualFlight:
        """Mettre à jour un vol manuel."""
        ManualFlightService._check_trip_not_completed(trip)
        flight = ManualFlightService.get_manual_flight_by_id(db, flight_id, trip.id)
        if not flight:
            raise AppError("FLIGHT_NOT_FOUND", 404, "Manual flight not found")

        if flight_number is not None:
            flight.flight_number = flight_number.upper().strip()
        if airline is not None:
            flight.airline = airline
        if departure_airport is not None:
            flight.departure_airport = departure_airport
        if arrival_airport is not None:
            flight.arrival_airport = arrival_airport
        if departure_date is not None:
            flight.departure_date = departure_date
        if arrival_date is not None:
            flight.arrival_date = arrival_date
        if currency is not None:
            flight.currency = currency
        if notes is not None:
            flight.notes = notes
        if flight_type is not None:
            flight.flight_type = flight_type

        # Sync budget item when price changes
        if price is not ...:
            flight.price = price
            linked = BudgetItemService.find_by_source(db, "manual_flight", flight.id)
            if price is not None and linked:
                linked.amount = price
                linked.label = f"Vol : {flight.flight_number}"
                if flight.departure_date:
                    linked.date = flight.departure_date.date()
            elif price is not None and not linked:
                db.add(
                    BudgetItem(
                        trip_id=trip.id,
                        label=f"Vol : {flight.flight_number}",
                        amount=price,
                        category=BudgetCategory.FLIGHT,
                        date=flight.departure_date.date() if flight.departure_date else None,
                        is_planned=True,
                        source_type="manual_flight",
                        source_id=flight.id,
                    )
                )
            elif price is None and linked:
                db.delete(linked)

        db.commit()
        db.refresh(flight)
        return flight

    @staticmethod
    def delete_manual_flight(db: Session, flight_id: UUID, trip: Trip) -> None:
        """Supprimer un vol manuel."""
        ManualFlightService._check_trip_not_completed(trip)
        flight = ManualFlightService.get_manual_flight_by_id(db, flight_id, trip.id)
        if not flight:
            raise AppError("FLIGHT_NOT_FOUND", 404, "Manual flight not found")

        linked = BudgetItemService.find_by_source(db, "manual_flight", flight.id)
        if linked:
            db.delete(linked)

        db.delete(flight)
        db.commit()
