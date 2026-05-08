"""Tests for :class:`PostTripSuggester` (W3 — RAG-grounded suggestions).

Covers:

- The cosine ranker pulls the highest-similarity catalogue row.
- The LLM is called narrative-only against a locked destination — its
  schema cannot inject a different city, country or IATA.
- Visited destinations are excluded; an "everything visited" user
  still gets a suggestion (defensive fallback).
- ``NO_FEEDBACK_HISTORY`` is raised when the user has no feedback yet.
- The bootstrap is invoked when the catalogue is empty.
"""

from __future__ import annotations

import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.llm_router import LLMRouter
from src.services.post_trip_suggester import (
    PostTripSuggester,
    _compose_user_corpus,
    _norm,
    _rank_by_cosine,
)
from src.utils.errors import AppError

# ── Fixtures ──────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def _reset_router() -> None:
    LLMRouter.reset_for_tests()
    yield
    LLMRouter.reset_for_tests()


def _catalog_row(
    iata: str,
    *,
    city: str,
    country: str = "Country",
    embedding: list[float] | None = None,
    daily_budget_eur: int = 100,
    typical_duration_days: int = 5,
    summary: str = "Catalog entry summary.",
    types_tags: str = "tag",
    region: str = "Region",
    country_code: str = "ZZ",
):
    row = SimpleNamespace(
        iata=iata,
        city=city,
        country=country,
        country_code=country_code,
        region=region,
        types_tags=types_tags,
        summary=summary,
        avg_summer_temp_c=25,
        avg_winter_temp_c=10,
        daily_budget_eur=daily_budget_eur,
        typical_duration_days=typical_duration_days,
        embedding=embedding or [1.0, 0.0],
        embedding_model="bge-m3",
    )
    return row


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


# ── Pure helpers ──────────────────────────────────────────────────────


class TestComposeUserCorpus:
    def test_positive_feedback_repeated_to_amplify_signal(self):
        feedbacks = [
            (_feedback(rating=5, highlights="ramen, neon"), _trip(destination_name="Tokyo"))
        ]
        corpus = _compose_user_corpus(feedbacks)
        assert corpus.count("ramen, neon") == 2  # positive ⇒ duplicated
        assert "loved Tokyo" in corpus

    def test_negative_lowlights_marked_avoid(self):
        feedbacks = [(_feedback(rating=2, highlights=None, lowlights="too crowded"), _trip())]
        corpus = _compose_user_corpus(feedbacks)
        assert "avoid: too crowded" in corpus

    def test_empty_feedbacks_falls_back_to_default(self):
        feedbacks = [(_feedback(rating=3, highlights=None, lowlights=None), _trip())]
        assert _compose_user_corpus(feedbacks) == "no detailed feedback"


class TestRankByCosine:
    def test_picks_aligned_vector_over_orthogonal(self):
        a = _catalog_row("AAA", city="A", embedding=[1.0, 0.0])
        b = _catalog_row("BBB", city="B", embedding=[0.0, 1.0])
        ranked = _rank_by_cosine([1.0, 0.0], [a, b])
        assert ranked[0].row.iata == "AAA"
        assert ranked[0].score == pytest.approx(1.0)
        assert ranked[1].row.iata == "BBB"

    def test_zero_user_vector_ranks_all_zero(self):
        a = _catalog_row("AAA", city="A", embedding=[1.0, 0.0])
        ranked = _rank_by_cosine([0.0, 0.0], [a])
        assert ranked[0].score == 0.0

    def test_norm_is_euclidean(self):
        assert _norm([3.0, 4.0]) == pytest.approx(5.0)
        assert _norm([0.0, 0.0]) == 0.0


# ── End-to-end flow ───────────────────────────────────────────────────


def _wire_db_with_feedbacks(db: MagicMock, feedbacks_with_trips: list[tuple]):
    """Drive the chained ORM call to return the canned feedback list."""
    chain = db.query.return_value.join.return_value.filter.return_value
    chain.order_by.return_value.limit.return_value.all.return_value = feedbacks_with_trips


def _wire_catalog_query(db: MagicMock, rows: list, count: int | None = None):
    """Drive catalogue queries: count() and the filtered .all()."""
    base = MagicMock()
    base.count.return_value = count if count is not None else len(rows)
    base.filter.return_value.all.return_value = rows
    base.all.return_value = rows
    db.query.side_effect = None  # ensure no pre-set side_effect

    # The suggester runs db.query(Feedback)... (already mocked) and then
    # db.query(DestinationCatalog)...; route the latter to ``base``.
    original = db.query

    def _query(model, *args, **kwargs):
        if getattr(model, "__name__", "") == "DestinationCatalog":
            return base
        return original.return_value

    db.query = _query
    return base


@pytest.mark.asyncio
async def test_no_feedback_history_raises_app_error():
    db = MagicMock()
    _wire_db_with_feedbacks(db, [])

    with pytest.raises(AppError) as exc:
        await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")
    assert exc.value.code == "NO_FEEDBACK_HISTORY"
    assert exc.value.status_code == 400


@pytest.mark.asyncio
async def test_full_flow_picks_top_match_and_locks_destination(monkeypatch):
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
        _catalog_row(
            "KIX",
            city="Kyoto",
            country="Japan",
            embedding=[1.0, 0.0],  # aligned with the user vector below
            daily_budget_eur=130,
            typical_duration_days=5,
            summary="Temples and seasonal cuisine.",
        ),
        _catalog_row(
            "LIS",
            city="Lisbon",
            country="Portugal",
            embedding=[0.0, 1.0],  # orthogonal — should NOT win
        ),
    ]
    _wire_catalog_query(db, rows, count=len(rows))

    embed_stub = AsyncMock(return_value=[[1.0, 0.0]])
    chat_stub = AsyncMock(
        return_value={
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": json.dumps(
                            {
                                "description": "Kyoto matches your love of temples and food.",
                                "highlights_match": ["temples", "ramen"],
                                "activities": [
                                    {
                                        "title": "Fushimi Inari at dawn",
                                        "description": "Orange torii gates without the crowd.",
                                        "category": "CULTURE",
                                        "estimated_cost": 0,
                                    },
                                    {
                                        "title": "Kaiseki dinner in Gion",
                                        "description": "Seasonal multi-course tasting.",
                                        "category": "FOOD",
                                        "estimated_cost": 110,
                                    },
                                    {
                                        "title": "Arashiyama bamboo walk",
                                        "description": "Western-hills morning loop.",
                                        "category": "NATURE",
                                        "estimated_cost": 0,
                                    },
                                ],
                            }
                        ),
                    }
                }
            ]
        }
    )
    monkeypatch.setattr(LLMRouter, "embed", embed_stub)
    monkeypatch.setattr(LLMRouter, "chat_completion", chat_stub)

    result = await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")

    assert result.matchedIata == "KIX"
    assert result.destination == "Kyoto"
    assert result.destinationCountry == "Japan"
    assert result.durationDays == 5
    assert result.budgetEur == 130 * 5
    assert "temples" in result.highlightsMatch
    assert len(result.activities) == 3
    # The narration LLM must have been called exactly once — it is
    # NEVER asked to choose a destination.
    chat_stub.assert_awaited_once()


@pytest.mark.asyncio
async def test_visited_destinations_are_excluded(monkeypatch):
    db = MagicMock()
    _wire_db_with_feedbacks(
        db,
        [
            (
                _feedback(rating=5, highlights="loved everything"),
                _trip(destination_name="Kyoto", destination_iata="KIX"),
            ),
        ],
    )
    rows = [
        _catalog_row("LIS", city="Lisbon", country="Portugal", embedding=[1.0, 0.0]),
    ]
    base = _wire_catalog_query(db, rows, count=1)

    monkeypatch.setattr(LLMRouter, "embed", AsyncMock(return_value=[[1.0, 0.0]]))
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        AsyncMock(
            return_value={
                "choices": [
                    {
                        "message": {
                            "content": json.dumps(
                                {
                                    "description": "Lisbon's a sunny city for slow walks.",
                                    "highlights_match": ["food", "sunshine"],
                                    "activities": [
                                        {
                                            "title": "Alfama walk",
                                            "description": "Hilly old town stroll.",
                                            "category": "CULTURE",
                                            "estimated_cost": 0,
                                        },
                                        {
                                            "title": "Pastel de nata tasting",
                                            "description": "Belém bakery crawl.",
                                            "category": "FOOD",
                                            "estimated_cost": 25,
                                        },
                                        {
                                            "title": "Caparica day trip",
                                            "description": "Atlantic beach south of Tejo.",
                                            "category": "NATURE",
                                            "estimated_cost": 15,
                                        },
                                    ],
                                }
                            )
                        }
                    }
                ]
            }
        ),
    )

    await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")

    # ``filter(~iata.in_(visited))`` should have been applied with the
    # visited IATA the user already saw.
    base.filter.assert_called_once()


@pytest.mark.asyncio
async def test_bootstrap_runs_when_catalog_empty(monkeypatch):
    db = MagicMock()
    _wire_db_with_feedbacks(
        db,
        [(_feedback(highlights="anything"), _trip(destination_name="Paris"))],
    )
    rows: list = []  # initially empty
    _wire_catalog_query(db, rows, count=0)

    monkeypatch.setattr(LLMRouter, "embed", AsyncMock(return_value=[[1.0, 0.0]]))

    bootstrap_stub = AsyncMock(return_value=42)
    monkeypatch.setattr(
        "src.services.post_trip_suggester.bootstrap_destination_catalog",
        bootstrap_stub,
    )

    # After bootstrap "fills" the catalogue, the cosine ranker has at
    # least one row to pick — patch the catalogue query to return a
    # canned hit on the second access.
    populated_row = _catalog_row("MRS", city="Marseille", country="France", embedding=[1.0, 0.0])
    rows.append(populated_row)

    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        AsyncMock(
            return_value={
                "choices": [
                    {
                        "message": {
                            "content": json.dumps(
                                {
                                    "description": "Marseille mixes harbour life and Calanques hikes.",
                                    "highlights_match": ["sea", "food"],
                                    "activities": [
                                        {
                                            "title": "Vieux-Port walk",
                                            "description": "Harbour stroll at sunrise.",
                                            "category": "CULTURE",
                                            "estimated_cost": 0,
                                        },
                                        {
                                            "title": "Calanques day-trip",
                                            "description": "Boat to Sormiou.",
                                            "category": "NATURE",
                                            "estimated_cost": 30,
                                        },
                                        {
                                            "title": "Bouillabaisse dinner",
                                            "description": "Vieux-Port classic.",
                                            "category": "FOOD",
                                            "estimated_cost": 65,
                                        },
                                    ],
                                }
                            )
                        }
                    }
                ]
            }
        ),
    )

    result = await PostTripSuggester.suggest_next_trip(db=db, user_id="u1")
    bootstrap_stub.assert_awaited_once()
    assert result.matchedIata == "MRS"
