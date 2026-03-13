"""Service IA pour suggestions de bagages."""

from src.services.llm_service import LLMService


class BaggageAIService:
    """Suggère des éléments de bagages via LLM."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert en préparation de bagages.
L'utilisateur te donne une destination, la durée du séjour et la saison.
Tu dois suggérer 10 à 15 éléments essentiels à emporter.

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "items": [
    {
      "name": "Nom de l'élément",
      "quantity": 2,
      "category": "Catégorie"
    }
  ]
}

Les catégories valides sont : Documents, Vêtements, Electronique, Hygiène, Médicaments, Accessoires, Autre.
Adapte les suggestions à la destination, la durée et la saison. Sois pratique et pertinent."""

    @staticmethod
    def suggest_baggage(
        destination: str,
        duration_days: int,
        season: str | None = None,
    ) -> dict:
        """Génère des suggestions de bagages via LLM."""
        parts = [
            f"Destination : {destination}",
            f"Durée du séjour : {duration_days} jours",
        ]
        if season:
            parts.append(f"Saison : {season}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(BaggageAIService.SYSTEM_PROMPT, user_prompt)
