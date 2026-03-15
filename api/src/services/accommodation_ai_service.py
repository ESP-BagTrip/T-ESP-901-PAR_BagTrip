"""Service IA pour suggestions d'hébergements."""

from src.services.llm_service import LLMService


class AccommodationAIService:
    """Suggère des hébergements pour un trip via LLM."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert en hébergement. L'utilisateur te donne une destination, des dates et un profil de voyage.
Tu dois suggérer 3 à 5 hébergements pertinents (quartier/type, pas des hôtels spécifiques).

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "accommodations": [
    {
      "type": "HOTEL|AIRBNB|HOSTEL|GUESTHOUSE|CAMPING|RESORT|OTHER",
      "name": "Nom ou type d'hébergement",
      "neighborhood": "Quartier recommandé",
      "priceRange": "50-80",
      "currency": "EUR",
      "reason": "Pourquoi ce quartier/type est recommandé",
      "searchKeywords": "mots-clés pour chercher sur Booking/Airbnb"
    }
  ]
}

Les types valides sont : HOTEL, AIRBNB, HOSTEL, GUESTHOUSE, CAMPING, RESORT, OTHER.
Sois créatif et propose des types variés adaptés à la destination, au budget et au style du voyageur.
Recommande des quartiers stratégiques proches des activités planifiées si elles sont fournies.
Si des contraintes sont spécifiées, toutes les suggestions doivent les respecter.
Ne propose pas d'hébergements déjà réservés (liste fournie dans le prompt)."""

    @staticmethod
    def suggest_accommodations(
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
        existing_accommodations: list[str] | None = None,
        planned_activities: list[str] | None = None,
    ) -> dict:
        """Génère des suggestions d'hébergements via LLM."""
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
        if existing_accommodations:
            parts.append(f"Hébergements déjà réservés (ne pas reproposer) : {', '.join(existing_accommodations)}")
        if planned_activities:
            parts.append(f"Activités planifiées (pour proximité quartier) : {', '.join(planned_activities)}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(AccommodationAIService.SYSTEM_PROMPT, user_prompt)
