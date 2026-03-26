"""Service IA pour suggestions post-voyage."""

from sqlalchemy import desc
from sqlalchemy.orm import Session

from src.models.feedback import Feedback
from src.models.trip import Trip
from src.services.llm_service import LLMService
from src.utils.errors import AppError


class PostTripAIService:
    """Analyse les feedbacks passés et suggère un prochain voyage."""

    SYSTEM_PROMPT = """Tu es un assistant de voyage expert. L'utilisateur te donne l'historique de ses avis sur ses voyages passés (notes, points forts, points faibles).
Analyse ces retours et suggère UN prochain voyage idéal qui correspond à ses préférences.

Réponds UNIQUEMENT en JSON valide avec cette structure exacte :
{
  "suggestion": {
    "destination": "Nom de la ville",
    "destinationCountry": "Pays",
    "durationDays": 7,
    "budgetEur": 1500,
    "description": "Description du voyage proposé et pourquoi il correspond à l'utilisateur",
    "highlightsMatch": ["Ce qui a plu dans les voyages passés et qu'on retrouve ici"],
    "activities": [
      {
        "title": "Nom de l'activité",
        "description": "Description courte",
        "category": "CULTURE|NATURE|FOOD|SPORT|OTHER",
        "estimatedCost": 25.0
      }
    ]
  }
}

Sois personnalisé : base ta suggestion sur les patterns des feedbacks (ce que l'utilisateur a aimé vs pas aimé)."""

    @staticmethod
    def suggest_next_trip(db: Session, user_id) -> dict:
        """Analyse les feedbacks et suggère un prochain voyage."""
        feedbacks = (
            db.query(Feedback, Trip)
            .join(Trip, Feedback.trip_id == Trip.id)
            .filter(Feedback.user_id == user_id)
            .order_by(desc(Feedback.created_at))
            .limit(10)
            .all()
        )

        if not feedbacks:
            raise AppError(
                "NO_FEEDBACK_HISTORY",
                400,
                "No feedback history found. Complete a trip and leave feedback first.",
            )

        # Build user prompt from feedback history
        parts = ["Voici l'historique des avis de l'utilisateur sur ses voyages passés :\n"]
        for feedback, trip in feedbacks:
            destination = trip.destination_name or trip.destination_iata or "Inconnu"
            parts.append(f"--- Voyage : {destination} ({trip.title or 'Sans titre'}) ---")
            parts.append(f"Note : {feedback.overall_rating}/5")
            if feedback.highlights:
                parts.append(f"Points forts : {feedback.highlights}")
            if feedback.lowlights:
                parts.append(f"Points faibles : {feedback.lowlights}")
            parts.append(f"Recommande : {'Oui' if feedback.would_recommend else 'Non'}")
            parts.append("")

        user_prompt = "\n".join(parts)
        llm = LLMService()
        return llm.call_llm(PostTripAIService.SYSTEM_PROMPT, user_prompt)
