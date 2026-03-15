"""Service IA pour suggestions de bagages."""

from src.services.llm_service import LLMService


class BaggageAIService:
    """Suggère des éléments de bagages via LLM."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert en préparation de bagages.
L'utilisateur te donne une destination, la durée du séjour, la saison et son profil voyageur.
Tu dois suggérer 10 à 15 éléments essentiels à emporter.

Prends en compte :
- Le profil du voyageur (style de voyage, compagnons, budget) pour adapter tes suggestions.
- Les activités validées : si randonnée → chaussures de marche, si plage → maillot de bain, etc.
- Les contraintes de vol : poids max autorisé, cabine uniquement vs soute. Respecte strictement les limites bagages.
- Les contraintes médicales : si le voyageur a des besoins spécifiques (médicaments, allergies, etc.), inclus les éléments nécessaires.
- Les bagages déjà ajoutés : ne propose JAMAIS un élément déjà présent dans la liste existante.

Pour chaque élément, explique brièvement pourquoi tu le suggères dans le champ "reason".

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "items": [
    {
      "name": "Nom de l'élément",
      "quantity": 2,
      "category": "Catégorie",
      "reason": "Pourquoi cet élément est recommandé"
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
        travel_types: str | None = None,
        travel_style: str | None = None,
        budget: str | None = None,
        companions: str | None = None,
        validated_activities: list[str] | None = None,
        flight_info: str | None = None,
        medical_constraints: str | None = None,
        existing_baggage: list[str] | None = None,
    ) -> dict:
        """Génère des suggestions de bagages via LLM."""
        parts = [
            f"Destination : {destination}",
            f"Durée du séjour : {duration_days} jours",
        ]
        if season:
            parts.append(f"Saison : {season}")
        if travel_types:
            parts.append(f"Types de voyage préférés : {travel_types}")
        if travel_style:
            parts.append(f"Style de voyage : {travel_style}")
        if budget:
            parts.append(f"Budget : {budget}")
        if companions:
            parts.append(f"Compagnons : {companions}")
        if validated_activities:
            parts.append(f"Activités confirmées : {', '.join(validated_activities)}")
        if flight_info:
            parts.append(f"Informations vol (contraintes bagages) : {flight_info}")
        if medical_constraints:
            parts.append(f"Contraintes médicales : {medical_constraints}")
        if existing_baggage:
            parts.append(f"Bagages déjà ajoutés (ne pas reproposer) : {', '.join(existing_baggage)}")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(BaggageAIService.SYSTEM_PROMPT, user_prompt)
