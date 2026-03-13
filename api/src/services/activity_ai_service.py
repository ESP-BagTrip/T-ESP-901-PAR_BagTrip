"""Service IA pour suggestions d'activités."""

from src.services.llm_service import LLMService


class ActivityAIService:
    """Suggère des activités pour un trip via LLM."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert. L'utilisateur te donne une destination, des dates et une description de voyage.
Tu dois suggérer 5 à 8 activités pertinentes pour ce voyage.

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "activities": [
    {
      "title": "Nom de l'activité",
      "description": "Description courte",
      "category": "CULTURE|NATURE|FOOD|SPORT|SHOPPING|NIGHTLIFE|RELAXATION|OTHER",
      "estimatedCost": 25.0,
      "location": "Lieu ou quartier"
    }
  ]
}

Les catégories valides sont : CULTURE, NATURE, FOOD, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER.
Les coûts sont en euros. Sois créatif et propose des activités variées adaptées à la destination et à la saison."""

    @staticmethod
    def suggest_activities(
        destination: str,
        start_date: str | None,
        end_date: str | None,
        description: str | None,
    ) -> dict:
        """Génère des suggestions d'activités via LLM."""
        parts = [f"Destination : {destination}"]
        if start_date:
            parts.append(f"Date de début : {start_date}")
        if end_date:
            parts.append(f"Date de fin : {end_date}")
        if description:
            parts.append(f"Description du voyage : {description}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(ActivityAIService.SYSTEM_PROMPT, user_prompt)
