"""W1 — "Inspire-me" eval cases.

Each case pins one structural invariant the audit caught regressing:

- Every shipped destination has a 3-letter IATA, a non-empty country
  and a cover image URL (audit C3 / Q2).
- The LLM ranker can only pick from the candidate IATA set — a
  hallucinated IATA is silently dropped.
- An Amadeus outage emits a typed ``warning`` event with code
  ``INSPIRE_AMADEUS_DOWN`` (audit C4) and falls back to an LLM-only
  path that still attaches an IATA to every shipped destination.

Run with the regular suite. Each case should complete in well under
1 s (everything external is stubbed).
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.inspire_orchestrator import InspireOrchestrator, InspireRequest
from src.services.llm_router import LLMRouter
from src.utils.errors import AppError
from tests.eval.conftest import (
    amadeus_inspire_response,
    drain,
    llm_chat_stub,
)


def _stub_amadeus_inspire(monkeypatch, rows):
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(return_value=amadeus_inspire_response(rows)),
    )


def _stub_amadeus_inspire_failure(monkeypatch, error: Exception):
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(side_effect=error),
    )


def _stub_weather(monkeypatch, *, payload: dict | None = None):
    if payload is None:
        payload = {
            "avg_temp_c": 24,
            "min_temp_c": 18,
            "max_temp_c": 30,
            "rain_probability": 15,
            "description": "Warm",
            "source": "open-meteo",
        }
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.get_weather",
        AsyncMock(return_value=payload),
    )


def _stub_unsplash(monkeypatch):
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value="https://images.unsplash.com/cover.jpg"),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.get_fallback_url",
        MagicMock(return_value="https://fallback"),
    )


# ── Eval cases ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_eval_w1_paris_summer_couple_4_destinations_have_iata(monkeypatch):
    """Wizard Paris/summer/couple → 2 picks, every dest has IATA + country + image."""
    _stub_amadeus_inspire(
        monkeypatch,
        [
            {"iata": "BCN", "price": 130},
            {"iata": "LIS", "price": 140},
            {"iata": "ROM", "price": 180},
        ],
    )
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "destinations": [
                    {
                        "iata": "BCN",
                        "match_reason": "Sun, sea and Gaudí — perfect for a couple in July.",
                        "weather_summary": "22-30°C in summer",
                        "top_activities": ["Sagrada Família", "Tapas crawl", "Park Güell"],
                    },
                    {
                        "iata": "LIS",
                        "match_reason": "Pastel-coloured hills, fado and pastel de nata.",
                        "weather_summary": "20-28°C in summer",
                        "top_activities": ["Alfama walk", "Belém towers", "Pastel de nata"],
                    },
                ]
            }
        ),
    )

    req = InspireRequest(
        origin_city="Paris",
        travel_types="culture, gastronomie",
        duration_days=6,
        departure_date="2026-07-04",
        return_date="2026-07-10",
        season="summer",
        companions="couple",
        budget_preset="COMFORTABLE",
        nb_travelers=2,
        locale="fr",
        pick_count=2,
    )
    events = await drain(InspireOrchestrator.stream(req))

    types = [t for t, _ in events]
    assert types[-1] == "complete"
    payload = next(d for t, d in events if t == "destinations")
    destinations = payload["destinations"]
    assert len(destinations) == 2
    iatas = [d["iata"] for d in destinations]
    assert iatas == ["BCN", "LIS"]
    for dest in destinations:
        # Every destination ships a 3-letter IATA — audit C3.
        assert isinstance(dest["iata"], str) and len(dest["iata"]) == 3
        assert dest["country"], "country must not be blank"
        assert dest["match_reason"], "match_reason must not be blank"
        assert dest["image_url"], "image_url must not be blank"
        assert dest["weather_summary"], "weather_summary must not be blank"
        assert isinstance(dest["topActivities"], list) and 3 <= len(dest["topActivities"]) <= 5
    complete = next(d for t, d in events if t == "complete")
    assert complete["source"] == "amadeus_inspire"


@pytest.mark.asyncio
async def test_eval_w1_llm_hallucinates_iata_outside_candidate_set(monkeypatch):
    """The strict-schema enum contract drops IATAs not present in the candidate list."""
    _stub_amadeus_inspire(
        monkeypatch,
        [
            {"iata": "BCN", "price": 130},
            {"iata": "LIS", "price": 140},
        ],
    )
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "destinations": [
                    {
                        "iata": "BCN",  # valid
                        "match_reason": "Sun and sea.",
                        "weather_summary": "warm",
                        "top_activities": ["a", "b", "c"],
                    },
                    {
                        "iata": "ZZZ",  # not in candidate set
                        "match_reason": "fake",
                        "weather_summary": "n/a",
                        "top_activities": ["x", "y", "z"],
                    },
                ]
            }
        ),
    )

    req = InspireRequest(origin_city="Paris", pick_count=4, locale="en")
    events = await drain(InspireOrchestrator.stream(req))
    payload = next(d for t, d in events if t == "destinations")
    iatas = [d["iata"] for d in payload["destinations"]]
    assert iatas == ["BCN"]


@pytest.mark.asyncio
async def test_eval_w1_amadeus_down_emits_warning_and_falls_back(monkeypatch):
    """Audit C4: Amadeus outage must surface as a typed ``warning`` event,
    and the LLM-only fallback must still attach an IATA per shipped destination."""
    _stub_amadeus_inspire_failure(monkeypatch, AppError("UPSTREAM_ERROR", 502, "amadeus down"))
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "destinations": [
                    {
                        "city": "Lisbon",
                        "country": "Portugal",
                        "match_reason": "Pastel cliffs and sunshine.",
                        "weather_summary": "20-28°C",
                        "topActivities": ["Alfama", "Pastel de nata", "Belém"],
                    },
                    {
                        "city": "Barcelona",
                        "country": "Spain",
                        "match_reason": "Beach plus Gaudí.",
                        "weather_summary": "22-32°C",
                        "topActivities": ["Sagrada", "Tapas", "Park Güell"],
                    },
                ]
            }
        ),
    )

    req = InspireRequest(origin_city="Paris", pick_count=2, locale="en")
    events = await drain(InspireOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "warning" in types
    warning = next(d for t, d in events if t == "warning")
    assert warning["code"] == "INSPIRE_AMADEUS_DOWN"

    complete = next(d for t, d in events if t == "complete")
    assert complete["source"] == "llm_only"
    for dest in complete["destinations"]:
        assert isinstance(dest["iata"], str) and len(dest["iata"]) == 3
