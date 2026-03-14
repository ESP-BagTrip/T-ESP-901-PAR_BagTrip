"""Service IA pour inspiration de voyages."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.services.llm_service import LLMService
from src.services.trips_service import TripsService


class InspireAIService:
    """Génère des suggestions de voyages et crée des trips depuis les suggestions."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage créatif et inspirant. L'utilisateur te donne ses préférences de voyage.
Tu dois générer 3 à 4 suggestions de voyages uniques et inspirantes.

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "suggestions": [
    {
      "destination": "Nom de la ville",
      "destinationCountry": "Pays",
      "durationDays": 7,
      "budgetEur": 1500,
      "description": "Description inspirante du voyage",
      "activities": [
        {
          "title": "Nom de l'activité",
          "description": "Description courte",
          "category": "CULTURE|NATURE|FOOD|SPORT|OTHER",
          "estimatedCost": 25.0
        }
      ]
    }
  ]
}

Sois créatif et varié dans tes suggestions. Propose des destinations différentes adaptées aux préférences."""

    @staticmethod
    def generate_inspiration(
        travel_types: str | None = None,
        budget_range: str | None = None,
        duration_days: int | None = None,
        companions: str | None = None,
        season: str | None = None,
        constraints: str | None = None,
    ) -> dict:
        """Génère des suggestions de voyage via LLM."""
        parts = []
        if travel_types:
            parts.append(f"Types de voyage préférés : {travel_types}")
        if budget_range:
            parts.append(f"Budget : {budget_range}")
        if duration_days:
            parts.append(f"Durée souhaitée : {duration_days} jours")
        if companions:
            parts.append(f"Compagnons : {companions}")
        if season:
            parts.append(f"Saison : {season}")
        if constraints:
            parts.append(f"Contraintes : {constraints}")

        if not parts:
            parts.append("Surprise-moi avec des destinations variées et originales !")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(InspireAIService.SYSTEM_PROMPT, user_prompt)

    # Default baggage items for AI-generated trips
    DEFAULT_BAGGAGE = [
        {"name": "Passeport", "category": "DOCUMENTS"},
        {"name": "Adaptateur de voyage", "category": "ELECTRONICS"},
        {"name": "Crème solaire", "category": "TOILETRIES"},
        {"name": "Trousse de premiers secours", "category": "HEALTH"},
        {"name": "Chargeur de téléphone", "category": "ELECTRONICS"},
        {"name": "Vêtements de rechange", "category": "CLOTHING"},
    ]

    @staticmethod
    def create_trip_from_suggestion(
        db: Session,
        user_id: UUID,
        suggestion: dict,
        start_date: str | None = None,
        end_date: str | None = None,
    ):
        """Crée un Trip DRAFT à partir d'une suggestion IA, avec activités et bagages."""
        trip = TripsService.create_trip(
            db=db,
            user_id=user_id,
            title=f"Voyage à {suggestion.get('destination', 'Inconnu')}",
            origin_iata=None,
            destination_iata=None,
            destination_name=suggestion.get("destination"),
            description=suggestion.get("description"),
            budget_total=suggestion.get("budgetEur"),
            start_date=start_date,
            end_date=end_date,
            origin="AI",
        )

        # Create activities from suggestion
        activities_data = suggestion.get("activities", [])
        if activities_data:
            trip_start = None
            if start_date:
                try:
                    trip_start = date.fromisoformat(start_date)
                except ValueError:
                    pass

            duration_days = suggestion.get("durationDays", len(activities_data)) or len(activities_data)

            for i, act in enumerate(activities_data):
                # Distribute activities across trip days (cycling)
                day_offset = i % max(duration_days, 1)
                activity_date = (
                    trip_start + timedelta(days=day_offset)
                    if trip_start
                    else date.today() + timedelta(days=day_offset)
                )

                activity = Activity(
                    trip_id=trip.id,
                    title=act.get("title", f"Activité {i + 1}"),
                    description=act.get("description", ""),
                    date=activity_date,
                    category=act.get("category", "OTHER"),
                    estimated_cost=act.get("estimatedCost"),
                )
                db.add(activity)

        # Create default baggage items
        for bag in InspireAIService.DEFAULT_BAGGAGE:
            item = BaggageItem(
                trip_id=trip.id,
                name=bag["name"],
                category=bag["category"],
            )
            db.add(item)

        db.commit()
        db.refresh(trip)
        return trip
