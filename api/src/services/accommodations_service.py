"""Service pour la gestion des accommodations."""

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import BudgetCategory, TripStatus
from src.models.accommodation import Accommodation
from src.models.budget_item import BudgetItem
from src.models.trip import Trip
from src.services.budget_item_service import BudgetItemService
from src.utils.errors import AppError
from src.utils.logger import logger

_ACCOMMODATION_SUGGEST_LABELS: dict[str, dict[str, str]] = {
    "en": {
        "destination": "Destination",
        "unknown": "Unknown",
        "iata": "IATA code",
        "duration": "Trip duration",
        "days": "days",
        "to": "to",
        "travelers": "Number of travelers",
        "budget": "Total budget",
        "existing": "Already added (avoid duplicates)",
    },
    "fr": {
        "destination": "Destination",
        "unknown": "Inconnue",
        "iata": "Code IATA",
        "duration": "Durée du voyage",
        "days": "jours",
        "to": "au",
        "travelers": "Nombre de voyageurs",
        "budget": "Budget total",
        "existing": "Déjà ajouté (éviter les doublons)",
    },
}


class AccommodationsService:
    """Service pour les opérations CRUD sur les accommodations."""

    @staticmethod
    def _check_trip_not_completed(trip: Trip) -> None:
        if trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify accommodations on a completed trip.",
            )

    @staticmethod
    def _calc_nights(check_in: datetime | date | None, check_out: datetime | date | None) -> int:
        """Calculate number of nights between check_in and check_out."""
        if check_in and check_out:
            d1 = check_in.date() if isinstance(check_in, datetime) else check_in
            d2 = check_out.date() if isinstance(check_out, datetime) else check_out
            if d2 > d1:
                return (d2 - d1).days
        return 1

    @staticmethod
    def create_accommodation(
        db: Session,
        trip: Trip,
        name: str,
        address: str | None = None,
        check_in: datetime | None = None,
        check_out: datetime | None = None,
        price_per_night: Decimal | None = None,
        currency: str | None = None,
        booking_reference: str | None = None,
        notes: str | None = None,
    ) -> Accommodation:
        """Créer un nouvel hébergement (accès vérifié par la dependency)."""
        AccommodationsService._check_trip_not_completed(trip)
        accommodation = Accommodation(
            trip_id=trip.id,
            name=name,
            address=address,
            check_in=check_in,
            check_out=check_out,
            price_per_night=price_per_night,
            currency=currency,
            booking_reference=booking_reference,
            notes=notes,
        )
        db.add(accommodation)

        if accommodation.price_per_night is not None:
            nights = AccommodationsService._calc_nights(check_in, check_out)
            amount = accommodation.price_per_night * nights
            db.add(
                BudgetItem(
                    trip_id=trip.id,
                    label=f"Hébergement : {name}",
                    amount=amount,
                    category=BudgetCategory.ACCOMMODATION,
                    date=check_in,
                    is_planned=True,
                    source_type="accommodation",
                    source_id=accommodation.id,
                )
            )

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
        trip: Trip,
        name: str | None = None,
        address: str | None = None,
        check_in: datetime | None = None,
        check_out: datetime | None = None,
        price_per_night: Decimal | None = None,
        currency: str | None = None,
        booking_reference: str | None = None,
        notes: str | None = None,
        price_explicitly_cleared: bool = False,
    ) -> Accommodation:
        """Mettre à jour un hébergement (accès vérifié par la dependency)."""
        AccommodationsService._check_trip_not_completed(trip)
        accommodation = AccommodationsService.get_accommodation_by_id(db, accommodation_id, trip.id)
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
        if price_per_night is not None:
            accommodation.price_per_night = price_per_night
        if currency is not None:
            accommodation.currency = currency
        if booking_reference is not None:
            accommodation.booking_reference = booking_reference
        if notes is not None:
            accommodation.notes = notes
        if price_explicitly_cleared:
            accommodation.price_per_night = None

        # Sync linked budget item
        linked = BudgetItemService.find_by_source(db, "accommodation", accommodation.id)
        if accommodation.price_per_night is not None:
            nights = AccommodationsService._calc_nights(
                accommodation.check_in, accommodation.check_out
            )
            amount = accommodation.price_per_night * nights
            if linked:
                linked.label = f"Hébergement : {accommodation.name}"
                linked.amount = amount
                linked.date = accommodation.check_in
            else:
                db.add(
                    BudgetItem(
                        trip_id=trip.id,
                        label=f"Hébergement : {accommodation.name}",
                        amount=amount,
                        category=BudgetCategory.ACCOMMODATION,
                        date=accommodation.check_in,
                        is_planned=True,
                        source_type="accommodation",
                        source_id=accommodation.id,
                    )
                )
        elif price_explicitly_cleared and linked:
            db.delete(linked)

        db.commit()
        db.refresh(accommodation)
        return accommodation

    @staticmethod
    def delete_accommodation(db: Session, accommodation_id: UUID, trip: Trip) -> None:
        """Supprimer un hébergement (accès vérifié par la dependency)."""
        AccommodationsService._check_trip_not_completed(trip)
        accommodation = AccommodationsService.get_accommodation_by_id(db, accommodation_id, trip.id)
        if not accommodation:
            raise AppError("ACCOMMODATION_NOT_FOUND", 404, "Accommodation not found")

        linked = BudgetItemService.find_by_source(db, "accommodation", accommodation.id)
        if linked:
            db.delete(linked)

        db.delete(accommodation)
        db.commit()

    @staticmethod
    async def suggest_accommodations(
        db: Session, trip: Trip, locale: str | None = None
    ) -> list[dict]:
        """Generate AI accommodation suggestions for a trip."""
        from src.agent.prompts import render as render_prompt
        from src.services.llm_service import LLMService
        from src.utils.locale import normalize_locale

        resolved_locale = normalize_locale(locale)
        labels = _ACCOMMODATION_SUGGEST_LABELS[resolved_locale]

        parts = [f"{labels['destination']}: {trip.destination_name or labels['unknown']}"]

        if trip.destination_iata:
            parts.append(f"{labels['iata']}: {trip.destination_iata}")

        if trip.start_date and trip.end_date:
            duration = (trip.end_date - trip.start_date).days + 1
            parts.append(
                f"{labels['duration']}: {duration} {labels['days']} "
                f"({trip.start_date} {labels['to']} {trip.end_date})"
            )

        if trip.nb_travelers:
            parts.append(f"{labels['travelers']}: {trip.nb_travelers}")

        if trip.budget_target:
            parts.append(f"{labels['budget']}: {trip.budget_target} EUR")

        # Dedup: list existing accommodations
        existing = AccommodationsService.get_accommodations_by_trip(db, trip.id)
        if existing:
            names = [a.name for a in existing]
            parts.append(f"{labels['existing']}: {', '.join(names)}")

        user_prompt = "\n".join(parts)

        llm = LLMService()
        try:
            result = await llm.acall_llm(
                render_prompt("accommodation_suggest", locale=resolved_locale),
                user_prompt,
            )
            accommodations = result.get("accommodations", [])
        except Exception as e:
            logger.error("Accommodation suggest LLM call failed", {"error": str(e)})
            accommodations = []

        return accommodations
