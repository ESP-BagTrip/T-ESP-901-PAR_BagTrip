"""Service IA pour suggestions post-voyage."""

from sqlalchemy import desc
from sqlalchemy.orm import Session

from src.agent.prompts import render
from src.models.feedback import Feedback
from src.models.trip import Trip
from src.services.llm_service import LLMService
from src.utils.errors import AppError
from src.utils.locale import normalize_locale

_USER_PROMPT_LABELS: dict[str, dict[str, str]] = {
    "en": {
        "intro": "Here is the user's review history of past trips:\n",
        "trip": "Trip",
        "untitled": "Untitled",
        "rating": "Rating",
        "highlights": "Highlights",
        "lowlights": "Lowlights",
        "would_recommend": "Would recommend",
        "yes": "Yes",
        "no": "No",
        "unknown": "Unknown",
        "no_feedback": "No feedback history found. Complete a trip and leave feedback first.",
    },
    "fr": {
        "intro": "Voici l'historique des avis de l'utilisateur sur ses voyages passés :\n",
        "trip": "Voyage",
        "untitled": "Sans titre",
        "rating": "Note",
        "highlights": "Points forts",
        "lowlights": "Points faibles",
        "would_recommend": "Recommande",
        "yes": "Oui",
        "no": "Non",
        "unknown": "Inconnu",
        "no_feedback": ("Aucun historique d'avis. Termine un voyage et laisse un avis avant tout."),
    },
}


class PostTripAIService:
    """Analyse les feedbacks passés et suggère un prochain voyage."""

    @staticmethod
    def suggest_next_trip(db: Session, user_id, locale: str | None = None) -> dict:
        """Analyse les feedbacks et suggère un prochain voyage."""
        resolved_locale = normalize_locale(locale)
        labels = _USER_PROMPT_LABELS[resolved_locale]

        feedbacks = (
            db.query(Feedback, Trip)
            .join(Trip, Feedback.trip_id == Trip.id)
            .filter(Feedback.user_id == user_id)
            .order_by(desc(Feedback.created_at))
            .limit(10)
            .all()
        )

        if not feedbacks:
            raise AppError("NO_FEEDBACK_HISTORY", 400, labels["no_feedback"])

        parts = [labels["intro"]]
        for feedback, trip in feedbacks:
            destination = trip.destination_name or trip.destination_iata or labels["unknown"]
            title = trip.title or labels["untitled"]
            parts.append(f"--- {labels['trip']}: {destination} ({title}) ---")
            parts.append(f"{labels['rating']}: {feedback.overall_rating}/5")
            if feedback.highlights:
                parts.append(f"{labels['highlights']}: {feedback.highlights}")
            if feedback.lowlights:
                parts.append(f"{labels['lowlights']}: {feedback.lowlights}")
            recommend = labels["yes"] if feedback.would_recommend else labels["no"]
            parts.append(f"{labels['would_recommend']}: {recommend}")
            parts.append("")

        user_prompt = "\n".join(parts)
        system_prompt = render("post_trip_suggestion", locale=resolved_locale)
        llm = LLMService()
        return llm.call_llm(system_prompt, user_prompt)
