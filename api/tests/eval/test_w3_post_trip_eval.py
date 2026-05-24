"""W3 — post-trip suggestion eval cases.

The W3 RAG is the audit's anti-hallucination move: the LLM never picks
a destination, only narrates the catalogue match the cosine ranker has
already locked. These tests pin that contract:

- The shipped destination is always one of the rows we wired into the
  catalogue; the IATA round-trips from row to response.
- Visited destinations are excluded from the candidate pool.
- The narration ships 3-6 activities (matching the schema's bounds).
- ``NO_FEEDBACK_HISTORY`` short-circuits before we even hit the
  embedding service.
"""

from __future__ import annotations

import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.llm_router import LLMRouter
from src.services.post_trip_suggester import PostTripSuggester
from src.utils.errors import AppError


def _wire_db_with_feedbacks(db: MagicMock, feedbacks_with_trips: list[tuple]):
    chain = db.query.return_value.join.return_value.filter.return_value
    chain.order_by.return_value.limit.return_value.all.return_value = feedbacks_with_trips


def _wire_catalog(db: MagicMock, rows: list, count: int | None = None):
    base = MagicMock()
    base.count.return_value = count if count is not None else len(rows)
    base.filter.return_value.all.return_value = rows
    base.all.return_value = rows
    db.query.side_effect = None
    original = db.query

    def _query(model, *args, **kwargs):
        if getattr(model, "__name__", "") == "DestinationCatalog":
            return base
        return original.return_value

    db.query = _query
    return base


def _row(
    iata: str,
    *,
    city: str,
    country: str = "Country",
    embedding: list[float] | None = None,
    daily_budget_eur: int = 100,
    typical_duration_days: int = 5,
):
    return SimpleNamespace(
        iata=iata,
        city=city,
        country=country,
        country_code="ZZ",
        region="Region",
        types_tags="tag",
        summary="Catalog entry summary.",
        avg_summer_temp_c=25,
        avg_winter_temp_c=10,
        daily_budget_eur=daily_budget_eur,
        typical_duration_days=typical_duration_days,
        embedding=embedding or [1.0, 0.0],
        embedding_model="bge-m3",
    )


def _feedback(
    *,
    rating: int = 5,
    highlights: str = "great",
    lowlights: str | None = None,
    would_recommend: bool = True,
):
    return SimpleNamespace(
        overall_rating=rating,
        highlights=highlights,
        lowlights=lowlights,
        would_recommend=would_recommend,
    )


def _trip(*, destination_name: str = "", destination_iata: str = ""):
    return SimpleNamespace(destination_name=destination_name, destination_iata=destination_iata)


def _narration(activities: int = 3) -> str:
    return json.dumps(
        {
            "description": "Locked-destination narrative copy.",
            "highlights_match": ["match-A", "match-B"],
            "activities": [
                {
                    "title": f"Activity {i + 1}",
                    "description": f"Description {i + 1}",
                    "category": "CULTURE",
                    "estimated_cost": 0,
                }
                for i in range(activities)
            ],
        }
    )


# ── Eval cases ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_eval_w3_top_match_destination_locked_to_catalog(monkeypatch):
    """The shipped destination must be one of the catalogue rows; the LLM
    only writes the narrative (audit anti-hallucination contract)."""
    db = MagicMock()
    _wire_db_with_feedbacks(
        db,
        [
            (
                _feedback(rating=5, highlights="temples and ramen"),
                _trip(destination_name="Paris", destination_iata="CDG"),
            ),
        ],
    )
    rows = [
        _row("KIX", city="Kyoto", country="Japan", embedding=[1.0, 0.0]),
        _row("LIS", city="Lisbon", country="Portugal", embedding=[0.0, 1.0]),
    ]
    _wire_catalog(db, rows)

    monkeypatch.setattr(LLMRouter, "embed", AsyncMock(return_value=[[1.0, 0.0]]))
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        AsyncMock(
            return_value={
                "choices": [{"message": {"content": _narration(activities=4)}}],
                "usage": {"prompt_tokens": 100, "completion_tokens": 100},
            }
        ),
    )

    result = await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")

    # The cosine ranker locked KIX (aligned with the user vector); the
    # LLM only wrote the narrative.
    assert result.matchedIata == "KIX"
    assert result.destination == "Kyoto"
    assert result.destinationCountry == "Japan"
    # Activities count within the schema's bounds.
    assert 3 <= len(result.activities) <= 6


@pytest.mark.asyncio
async def test_eval_w3_visited_destination_excluded(monkeypatch):
    """Destinations the user already visited are filtered out of the
    candidate pool — the suggester never recommends Kyoto twice."""
    db = MagicMock()
    _wire_db_with_feedbacks(
        db,
        [
            (
                _feedback(rating=5, highlights="loved it"),
                _trip(destination_name="Kyoto", destination_iata="KIX"),
            ),
        ],
    )
    rows = [_row("LIS", city="Lisbon", country="Portugal", embedding=[1.0, 0.0])]
    base = _wire_catalog(db, rows)

    monkeypatch.setattr(LLMRouter, "embed", AsyncMock(return_value=[[1.0, 0.0]]))
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        AsyncMock(
            return_value={
                "choices": [{"message": {"content": _narration(activities=3)}}],
                "usage": {"prompt_tokens": 100, "completion_tokens": 100},
            }
        ),
    )

    await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")
    base.filter.assert_called_once()  # ``~iata.in_(visited)`` was applied


@pytest.mark.asyncio
async def test_eval_w3_no_feedback_short_circuits_before_embedding(monkeypatch):
    """Without feedback history, the suggester refuses early — no LLM /
    no embedding call."""
    db = MagicMock()
    _wire_db_with_feedbacks(db, [])

    embed_stub = AsyncMock(side_effect=AssertionError("embed must not be called"))
    chat_stub = AsyncMock(side_effect=AssertionError("LLM must not be called"))
    monkeypatch.setattr(LLMRouter, "embed", embed_stub)
    monkeypatch.setattr(LLMRouter, "chat_completion", chat_stub)

    with pytest.raises(AppError) as exc:
        await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")
    assert exc.value.code == "NO_FEEDBACK_HISTORY"
    assert exc.value.status_code == 400
    embed_stub.assert_not_called()
    chat_stub.assert_not_called()
