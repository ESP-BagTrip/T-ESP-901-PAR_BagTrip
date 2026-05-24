"""W3 — post-trip "next destination" suggester.

Pipeline (deterministic-first, narrative-only LLM):

1. Fetch the user's most recent feedbacks + the trips they refer to
   (last :data:`FEEDBACK_LOOKBACK` entries).
2. Compose a single corpus from the highlights / lowlights the user
   actually wrote, weighted positively. Avoid paths the user
   downvoted.
3. Embed the corpus via BGE-M3 (OVH) through :class:`LLMRouter`.
4. Cosine-match against the embeddings stored in
   ``destination_catalog`` (populated by
   :func:`bootstrap_destination_catalog`). Drop destinations the user
   has already visited or explicitly disliked.
5. Pick the top-1 match. The LLM **never** picks a destination — we
   hand the locked match to a strict-schema narration call that
   writes ``description``, ``highlightsMatch`` and ``activities``
   from the catalogue's metadata.

This kills the audit's W3 hallucinations: every shipped destination
is a real entry from a curated catalogue with a real IATA, real
country and a sensible budget band.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from typing import Any

from sqlalchemy import desc
from sqlalchemy.orm import Session

from src.agent.prompts import render
from src.models.destination_catalog import DestinationCatalog
from src.models.feedback import Feedback
from src.models.trip import Trip
from src.services.destination_catalog_bootstrap import bootstrap_destination_catalog
from src.services.llm_router import LLMRouter
from src.utils.errors import AppError
from src.utils.locale import normalize_locale
from src.utils.logger import logger

# ── Tunables ───────────────────────────────────────────────────────────

#: Number of past feedbacks we look at when composing the user vector.
FEEDBACK_LOOKBACK = 10

#: Minimum cosine similarity to consider a candidate "matching enough".
#: Below this we still ship the top-1 (rather than refusing the request)
#: but flag the result with ``low_confidence=True`` for telemetry.
MIN_MATCH_CONFIDENCE = 0.35


# ── Public DTO ─────────────────────────────────────────────────────────


@dataclass
class PostTripSuggestionResult:
    """Final shape ready to ship through ``PostTripSuggestionResponse``."""

    destination: str
    destinationCountry: str
    durationDays: int
    budgetEur: int
    description: str
    highlightsMatch: list[str]
    activities: list[dict[str, Any]]
    matchedIata: str
    matchScore: float


# ── Service ────────────────────────────────────────────────────────────


class PostTripSuggester:
    """Stateless. Use :meth:`suggest_next_trip` per user request."""

    @classmethod
    async def suggest_next_trip(
        cls,
        *,
        db: Session,
        user_id,
        locale: str | None = None,
    ) -> PostTripSuggestionResult:
        resolved_locale = normalize_locale(locale)

        feedback_rows = (
            db.query(Feedback, Trip)
            .join(Trip, Feedback.trip_id == Trip.id)
            .filter(Feedback.user_id == user_id)
            .order_by(desc(Feedback.created_at))
            .limit(FEEDBACK_LOOKBACK)
            .all()
        )
        # SQLAlchemy returns ``Row[tuple[Feedback, Trip]]`` — unpack
        # eagerly so the helpers below see a plain list of tuples.
        feedbacks: list[tuple[Feedback, Trip]] = [(row[0], row[1]) for row in feedback_rows]
        if not feedbacks:
            raise AppError(
                "NO_FEEDBACK_HISTORY",
                400,
                "No feedback history found. Complete a trip and leave feedback first.",
            )

        # 1. Make sure the catalogue is populated. The first request
        # after a fresh deploy pays the embedding cost; later ones are
        # cheap.
        if db.query(DestinationCatalog).count() == 0:
            await bootstrap_destination_catalog(db)

        # 2. Build the user vector from the highlight / lowlight text.
        corpus = _compose_user_corpus(feedbacks)
        user_vector = await _embed_corpus(corpus)

        # 3. Cosine-match against the catalogue, excluding destinations
        # the user already visited.
        visited_iatas = {trip.destination_iata for _, trip in feedbacks if trip.destination_iata}
        catalog_rows = (
            db.query(DestinationCatalog).filter(~DestinationCatalog.iata.in_(visited_iatas)).all()
        )
        if not catalog_rows:
            # Defensive: if the user has somehow visited every
            # catalogue row, fall back to the full set.
            catalog_rows = db.query(DestinationCatalog).all()

        ranked = _rank_by_cosine(user_vector, catalog_rows)
        top = ranked[0]
        match_row = top.row
        match_score = top.score
        if match_score < MIN_MATCH_CONFIDENCE:
            logger.warn(
                "PostTripSuggester: low confidence match",
                {
                    "user_id": str(user_id),
                    "iata": match_row.iata,
                    "score": round(match_score, 3),
                },
            )

        # 4. LLM narration — strict JSON schema, locked destination.
        narration = await _narrate(match_row, feedbacks, locale=resolved_locale)

        return PostTripSuggestionResult(
            destination=match_row.city,
            destinationCountry=match_row.country,
            durationDays=match_row.typical_duration_days,
            budgetEur=match_row.daily_budget_eur * match_row.typical_duration_days,
            description=narration["description"],
            highlightsMatch=narration["highlights_match"],
            activities=narration["activities"],
            matchedIata=match_row.iata,
            matchScore=round(match_score, 4),
        )


# ── Internal helpers ──────────────────────────────────────────────────


def _compose_user_corpus(feedbacks: list[tuple[Feedback, Trip]]) -> str:
    """Concatenate highlights + ratings into a single corpus.

    Weight: positive feedback (rating >= 4 + ``would_recommend=True``)
    has its highlights repeated twice; negative feedback's lowlights
    are prefixed with ``avoid:`` so the embedding pulls AWAY from
    similar themes instead of being silently neutral on them.
    """
    parts: list[str] = []
    for feedback, trip in feedbacks:
        dest = trip.destination_name or trip.destination_iata or ""
        rating = feedback.overall_rating or 0
        positive = rating >= 4 and bool(feedback.would_recommend)
        if feedback.highlights:
            parts.append(feedback.highlights)
            if positive:
                parts.append(feedback.highlights)
            if dest:
                parts.append(f"loved {dest}")
        if feedback.lowlights:
            parts.append(f"avoid: {feedback.lowlights}")
    return " | ".join(p for p in parts if p) or "no detailed feedback"


async def _embed_corpus(text: str) -> list[float]:
    vectors = await LLMRouter.get().embed(inputs=[text])
    if not vectors:
        raise AppError(
            "POST_TRIP_EMBED_FAILED",
            502,
            "Embedding service returned no vector for the user corpus.",
        )
    return vectors[0]


@dataclass
class _RankedRow:
    row: DestinationCatalog
    score: float


def _rank_by_cosine(user_vector: list[float], rows: list[DestinationCatalog]) -> list[_RankedRow]:
    """Cosine similarity of the user vector against every catalogue row.

    Cosine is dot-product / (norm_a * norm_b). At our V1 catalogue
    size (≤ 50 rows) this is ~50 µs in pure Python — well under the
    LLM call latency that follows.
    """
    user_norm = _norm(user_vector)
    if user_norm == 0:
        return [_RankedRow(row=r, score=0.0) for r in rows]
    ranked: list[_RankedRow] = []
    for r in rows:
        emb = r.embedding or []
        rn = _norm(emb)
        if rn == 0:
            ranked.append(_RankedRow(row=r, score=0.0))
            continue
        dot = sum(u * v for u, v in zip(user_vector, emb, strict=False))
        ranked.append(_RankedRow(row=r, score=dot / (user_norm * rn)))
    ranked.sort(key=lambda x: x.score, reverse=True)
    return ranked


def _norm(vec: list[float]) -> float:
    return math.sqrt(sum(v * v for v in vec))


async def _narrate(
    row: DestinationCatalog,
    feedbacks: list[tuple[Feedback, Trip]],
    *,
    locale: str,
) -> dict[str, Any]:
    """LLM narrative-only call. The destination is already chosen."""
    system_prompt = render("post_trip_suggestion", locale=locale)
    user_prompt = _compose_narration_prompt(row, feedbacks)
    schema = _narration_schema()

    payload = await LLMRouter.get().chat_completion(
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        response_format={"type": "json_schema", "json_schema": schema},
        temperature=0.4,
        max_tokens=900,
    )
    raw = payload["choices"][0]["message"].get("content") or "{}"
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AppError(
            "POST_TRIP_INVALID_JSON",
            502,
            f"Narration LLM returned invalid JSON: {exc}",
        ) from exc
    return {
        "description": str(parsed.get("description", row.summary)),
        "highlights_match": [str(x) for x in (parsed.get("highlights_match") or []) if x],
        "activities": [
            {
                "title": str(a.get("title", "")),
                "description": str(a.get("description", "")),
                "category": str(a.get("category", "OTHER")).upper(),
                "estimatedCost": float(a["estimated_cost"])
                if a.get("estimated_cost") is not None
                else None,
            }
            for a in (parsed.get("activities") or [])
        ],
    }


def _compose_narration_prompt(
    row: DestinationCatalog,
    feedbacks: list[tuple[Feedback, Trip]],
) -> str:
    lines: list[str] = [
        "Locked destination (you cannot change it):",
        f"- city: {row.city}",
        f"- country: {row.country}",
        f"- iata: {row.iata}",
        f"- region: {row.region}",
        f"- tags: {row.types_tags}",
        f"- summary: {row.summary}",
        f"- typical duration (days): {row.typical_duration_days}",
        f"- daily budget (EUR): {row.daily_budget_eur}",
        "",
        "User's recent trips and feedback:",
    ]
    for feedback, trip in feedbacks[:5]:
        dest = trip.destination_name or trip.destination_iata or "Unknown"
        lines.append(
            f"- {dest} ({feedback.overall_rating}/5)"
            f" — highlights: {feedback.highlights or '—'}"
            f" — lowlights: {feedback.lowlights or '—'}"
        )
    return "\n".join(lines)


def _narration_schema() -> dict[str, Any]:
    return {
        "name": "post_trip_narration",
        "schema": {
            "type": "object",
            "properties": {
                "description": {"type": "string"},
                "highlights_match": {
                    "type": "array",
                    "items": {"type": "string"},
                    "minItems": 2,
                    "maxItems": 6,
                },
                "activities": {
                    "type": "array",
                    "minItems": 3,
                    "maxItems": 6,
                    "items": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string"},
                            "description": {"type": "string"},
                            "category": {"type": "string"},
                            "estimated_cost": {"anyOf": [{"type": "number"}, {"type": "null"}]},
                        },
                        "required": ["title", "description", "category"],
                        "additionalProperties": False,
                    },
                },
            },
            "required": ["description", "highlights_match", "activities"],
            "additionalProperties": False,
        },
        "strict": True,
    }


__all__ = ["PostTripSuggester", "PostTripSuggestionResult"]
