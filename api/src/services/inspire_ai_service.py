"""Service IA pour inspiration de voyages."""

from uuid import UUID

from sqlalchemy.orm import Session

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

        if not parts:
            parts.append("Surprise-moi avec des destinations variées et originales !")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(InspireAIService.SYSTEM_PROMPT, user_prompt)

    @staticmethod
    def create_trip_from_suggestion(
        db: Session,
        user_id: UUID,
        suggestion: dict,
    ):
        """Crée un Trip DRAFT à partir d'une suggestion IA."""
        return TripsService.create_trip(
            db=db,
            user_id=user_id,
            title=f"Voyage à {suggestion.get('destination', 'Inconnu')}",
            origin_iata=None,
            destination_iata=None,
            destination_name=suggestion.get("destination"),
            description=suggestion.get("description"),
            budget_total=suggestion.get("budgetEur"),
            origin="AI",
        )
