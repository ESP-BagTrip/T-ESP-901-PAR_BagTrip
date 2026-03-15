"""Service IA pour estimation de budget."""

from src.services.llm_service import LLMService


class BudgetAiService:
    """Estime le budget d'un voyage via LLM."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert en budgétisation.
L'utilisateur te donne une destination, la durée du séjour, le nombre de voyageurs et son profil de voyage.
Tu peux aussi recevoir des hébergements, vols et activités déjà réservés pour affiner ton estimation.

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "estimation": {
    "accommodation_per_night": 85,
    "meals_per_day_per_person": 35,
    "local_transport_per_day": 15,
    "activities_total": 200,
    "total_min": 1200,
    "total_max": 1800,
    "currency": "EUR",
    "breakdown_notes": "Explication détaillée du calcul et des hypothèses"
  }
}

Adapte les montants à la destination, au style de voyage et au budget du profil.
Si des éléments sont déjà réservés (hébergements, vols, activités), déduis-les de tes estimations et ajuste les totaux.
Sois réaliste et donne une fourchette min/max crédible."""

    @staticmethod
    def estimate_budget(
        destination: str,
        duration_days: int,
        nb_travelers: int,
        budget_profile: str | None = None,
        known_accommodations: list[dict] | None = None,
        known_flights: list[dict] | None = None,
        known_activities: list[dict] | None = None,
    ) -> dict:
        """Génère une estimation de budget via LLM."""
        parts = [
            f"Destination : {destination}",
            f"Durée du séjour : {duration_days} jours",
            f"Nombre de voyageurs : {nb_travelers}",
        ]
        if budget_profile:
            parts.append(f"Profil budget : {budget_profile}")
        if known_accommodations:
            parts.append(f"Hébergements déjà réservés : {known_accommodations}")
        if known_flights:
            parts.append(f"Vols déjà réservés : {known_flights}")
        if known_activities:
            parts.append(f"Activités planifiées : {known_activities}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(BudgetAiService.SYSTEM_PROMPT, user_prompt)
