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
      "location": "Lieu ou quartier",
      "suggestedDay": 1
    }
  ]
}

Les catégories valides sont : CULTURE, NATURE, FOOD, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER.
Les coûts sont en euros. Sois créatif et propose des activités variées adaptées à la destination et à la saison.
Répartis les activités sur les jours du voyage (suggestedDay: 1 = premier jour, 2 = deuxième jour, etc.).
Si des contraintes sont spécifiées, toutes les activités doivent les respecter.
Ne propose pas d'activités déjà planifiées (liste fournie dans le prompt)."""

    @staticmethod
    def suggest_activities(
        destination: str,
        start_date: str | None,
        end_date: str | None,
        description: str | None,
        duration_days: int | None = None,
        nb_travelers: int | None = None,
        travel_types: str | None = None,
        travel_style: str | None = None,
        budget: str | None = None,
        companions: str | None = None,
        constraints: str | None = None,
        existing_activities: list[str] | None = None,
    ) -> dict:
        """Génère des suggestions d'activités via LLM."""
        parts = [f"Destination : {destination}"]
        if start_date:
            parts.append(f"Date de début : {start_date}")
        if end_date:
            parts.append(f"Date de fin : {end_date}")
        if description:
            parts.append(f"Description du voyage : {description}")
        if duration_days:
            parts.append(f"Durée du voyage : {duration_days} jours")
        if nb_travelers and nb_travelers > 1:
            parts.append(f"Nombre de voyageurs : {nb_travelers}")
        if travel_types:
            parts.append(f"Types de voyage préférés : {travel_types}")
        if travel_style:
            parts.append(f"Style de voyage : {travel_style}")
        if budget:
            parts.append(f"Budget : {budget}")
        if companions:
            parts.append(f"Compagnons : {companions}")
        if constraints:
            parts.append(f"Contraintes : {constraints}")
        if existing_activities:
            parts.append(f"Activités déjà planifiées (ne pas reproposer) : {', '.join(existing_activities)}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(ActivityAIService.SYSTEM_PROMPT, user_prompt)
