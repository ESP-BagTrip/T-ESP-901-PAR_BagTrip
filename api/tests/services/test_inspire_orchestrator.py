"""Tests for :class:`InspireOrchestrator` (W1 — destinations_only path).

Behaviour covered:

- Origin city → IATA resolution (offline, ``airportsdata``).
- Successful Amadeus inspiration → enrichment → LLM ranker → final SSE shape.
- LLM ranker constrained to the candidate IATA set (strict schema enforced
  at orchestration level: hallucinated IATAs are dropped).
- Amadeus inspiration unavailable → ``warning`` event + LLM-only fallback.
- LLM-only fallback resolves destinations IATA-first so it stays
  locale-safe (regression: a French run must not collapse to a single
  card) and over-fetches to absorb unresolvable codes.
- Inspirations returned but every IATA is unknown to offline aviation data
  → fallback (we never ship destinations without an IATA).
- Origin unresolved → ``error`` event, no further work.
"""

from __future__ import annotations

import json
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.inspire_orchestrator import InspireOrchestrator, InspireRequest
from src.services.llm_router import LLMRouter
from src.utils.errors import AppError

# ── Fixtures ──────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def _reset_router() -> None:
    LLMRouter.reset_for_tests()
    yield
    LLMRouter.reset_for_tests()


def _llm_chat_completion_stub(content: str) -> AsyncMock:
    """Build an AsyncMock returning an OpenAI-shaped chat completion."""
    return AsyncMock(
        return_value={
            "choices": [{"message": {"role": "assistant", "content": content}}],
            "usage": {"prompt_tokens": 50, "completion_tokens": 50},
        }
    )


def _make_inspire_response(rows: list[dict[str, Any]]) -> Any:
    """Return a stub mimicking ``FlightDestinationResponse`` enough for the orchestrator."""
    data = []
    for r in rows:
        item = MagicMock()
        item.destination = r["iata"]
        item.departureDate = r.get("dep_date", "2026-07-04")
        item.returnDate = r.get("ret_date", "2026-07-10")
        price = MagicMock()
        price.total = str(r.get("price", "120"))
        item.price = price
        data.append(item)
    return SimpleResponse(data=data)


class SimpleResponse:
    def __init__(self, data: list[Any]) -> None:
        self.data = data


async def _drain(agen) -> list[tuple[str, dict]]:
    return [item async for item in agen]


# ── Tests ─────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_origin_unresolved_emits_error(monkeypatch):
    """An unknown origin city short-circuits before any LLM/Amadeus call."""
    req = InspireRequest(origin_city="ZZZNotACity")
    events = await _drain(InspireOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "error" in types
    err_payload = next(p for t, p in events if t == "error")
    assert err_payload["code"] == "ORIGIN_UNRESOLVED"


@pytest.mark.asyncio
async def test_full_path_amadeus_then_llm_ranker(monkeypatch):
    """Happy path: Amadeus returns 3 candidates, LLM ranks them, all SSE events fire."""
    req = InspireRequest(
        origin_city="Paris",
        departure_date="2026-07-04",
        return_date="2026-07-10",
        duration_days=6,
        locale="en",
        pick_count=2,
    )

    inspire_stub = AsyncMock(
        return_value=_make_inspire_response(
            [
                {"iata": "BCN", "price": "120"},
                {"iata": "LIS", "price": "140"},
                {"iata": "ROM", "price": "180"},
            ]
        )
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        inspire_stub,
    )
    # Open-Meteo and Unsplash are best-effort — short-circuit them.
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.get_weather",
        AsyncMock(
            return_value={
                "avg_temp_c": 25,
                "min_temp_c": 18,
                "max_temp_c": 32,
                "rain_probability": 10,
                "description": "Warm and pleasant",
                "source": "open-meteo",
            }
        ),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value="https://images.unsplash.com/some.jpg"),
    )

    llm_picks = {
        "destinations": [
            {
                "iata": "BCN",
                "match_reason": "Coastal architecture and tapas — perfect 6-day couple's trip.",
                "weather_summary": "18-32°C in summer",
                "top_activities": ["Sagrada Família", "Tapas crawl", "Park Güell"],
            },
            {
                "iata": "LIS",
                "match_reason": "Pastel-coloured hills and pastel de nata, easy 6-day pace.",
                "weather_summary": "20-30°C in summer",
                "top_activities": ["Alfama walk", "Pastel de nata", "Belém Tower"],
            },
        ]
    }
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(json.dumps(llm_picks)),
    )

    events = await _drain(InspireOrchestrator.stream(req))

    types = [t for t, _ in events]
    assert "progress" in types
    assert "destinations" in types
    assert types[-1] == "complete"

    dest_payload = next(p for t, p in events if t == "destinations")
    iatas = [d["iata"] for d in dest_payload["destinations"]]
    assert iatas == ["BCN", "LIS"]
    # Each card has the LLM narrative + the deterministic data.
    bcn = dest_payload["destinations"][0]
    assert "tapas" in bcn["match_reason"].lower()
    assert bcn["weather"] is not None
    assert bcn["price_from"]["amount"] == 120.0
    assert bcn["price_from"]["currency"] == "EUR"
    assert bcn["image_url"].startswith("https://images.unsplash.com")
    assert bcn["topActivities"][0] == "Sagrada Família"

    complete_payload = next(p for t, p in events if t == "complete")
    assert complete_payload["source"] == "amadeus_inspire"
    assert complete_payload["originIata"] == "CDG"


@pytest.mark.asyncio
async def test_llm_hallucinates_iata_outside_candidate_set(monkeypatch):
    """If the LLM returns an IATA not in the candidate list, it's silently dropped."""
    req = InspireRequest(origin_city="Paris", pick_count=4)
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(
            return_value=_make_inspire_response(
                [
                    {"iata": "BCN", "price": "120"},
                    {"iata": "LIS", "price": "140"},
                ]
            )
        ),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.get_weather",
        AsyncMock(return_value={"avg_temp_c": 25, "description": "warm"}),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value=None),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.get_fallback_url",
        MagicMock(return_value="https://fallback"),
    )

    # LLM returns one valid IATA and one fake one — only the valid one survives.
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "BCN",
                            "match_reason": "ok",
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
            )
        ),
    )

    events = await _drain(InspireOrchestrator.stream(req))
    payload = next(p for t, p in events if t == "destinations")
    iatas = [d["iata"] for d in payload["destinations"]]
    assert iatas == ["BCN"]


@pytest.mark.asyncio
async def test_amadeus_failure_falls_back_to_llm_only(monkeypatch):
    """Amadeus 5xx → SSE warning + LLM-only suggestions still ship with IATAs."""
    req = InspireRequest(origin_city="Paris", pick_count=2, locale="en")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "boom")),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value="https://img"),
    )
    # The fallback uses ``destination_quick``: the LLM ships an IATA code
    # per destination as the resolution key plus English city/country.
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "LIS",
                            "city": "Lisbon",
                            "country": "Portugal",
                            "match_reason": "Pastel cliffs and sunshine.",
                            "weather_summary": "20-28°C",
                            "top_activities": ["Alfama", "Pastel de nata", "Belém"],
                        },
                        {
                            "iata": "BCN",
                            "city": "Barcelona",
                            "country": "Spain",
                            "match_reason": "Beach plus Gaudí.",
                            "weather_summary": "22-32°C",
                            "top_activities": ["Sagrada", "Tapas", "Park Güell"],
                        },
                    ]
                }
            )
        ),
    )

    events = await _drain(InspireOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "warning" in types
    warning = next(p for t, p in events if t == "warning")
    assert warning["code"] == "INSPIRE_AMADEUS_DOWN"

    complete = next(p for t, p in events if t == "complete")
    assert complete["source"] == "llm_only"
    iatas = [d["iata"] for d in complete["destinations"]]
    assert iatas == ["LIS", "BCN"]
    # Every destination must carry a 3-letter IATA — that's the audit C3
    # contract — and run through the shared serialiser (cover image, keys).
    for dest in complete["destinations"]:
        assert isinstance(dest["iata"], str) and len(dest["iata"]) == 3
        assert dest["image_url"] == "https://img"
        assert dest["topActivities"]
        assert dest["price_from"] is None


@pytest.mark.asyncio
async def test_inspire_returns_only_unknown_iatas_falls_back(monkeypatch):
    """If every Amadeus IATA is unknown to airportsdata, fall back rather than ship blanks."""
    req = InspireRequest(origin_city="Paris", pick_count=2, locale="en")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(
            return_value=_make_inspire_response(
                [
                    {"iata": "ZZZ", "price": "100"},
                    {"iata": "QQQ", "price": "120"},
                ]
            )
        ),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value=None),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.get_fallback_url",
        MagicMock(return_value="https://fallback"),
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "CDG",
                            "city": "Paris",
                            "country": "France",
                            "match_reason": "Iconic museums and riverside strolls.",
                            "weather_summary": "12-18°C",
                            "top_activities": ["Eiffel", "Louvre", "Marais"],
                        }
                    ]
                }
            )
        ),
    )

    events = await _drain(InspireOrchestrator.stream(req))
    complete = next(p for t, p in events if t == "complete")
    assert complete["source"] == "llm_only"
    iatas = [d["iata"] for d in complete["destinations"]]
    assert iatas == ["CDG"]
    assert all(len(i) == 3 for i in iatas)


@pytest.mark.asyncio
async def test_fallback_city_search_when_iata_unknown(monkeypatch):
    """A hallucinated IATA degrades to an English city-name lookup.

    The resolver must still pin Manchester to MAN (GB) and not MHT (US)
    via the English country hint.
    """
    req = InspireRequest(origin_city="Paris", pick_count=1, locale="en")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "down")),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value=None),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.get_fallback_url",
        MagicMock(return_value="https://fallback"),
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "ZZZ",  # not a real airport — forces the city fallback
                            "city": "Manchester",
                            "country": "United Kingdom",
                            "match_reason": "Football and post-industrial culture.",
                            "weather_summary": "10-18°C",
                            "top_activities": ["Old Trafford", "Curry Mile", "Northern Quarter"],
                        }
                    ]
                }
            )
        ),
    )
    events = await _drain(InspireOrchestrator.stream(req))
    complete = next(p for t, p in events if t == "complete")
    iatas = [d["iata"] for d in complete["destinations"]]
    # IATA "ZZZ" is unknown → city search; the country hint pins GB.
    assert iatas == ["MAN"]


@pytest.mark.asyncio
async def test_fallback_french_locale_returns_full_list(monkeypatch):
    """Regression: a French run must not collapse to a single card.

    The bug — ``destination_quick`` in FR made the LLM emit French city
    names ("Lisbonne", "Athènes") that the English ``airportsdata``
    couldn't resolve, so 3 of 4 cards were silently dropped. With
    IATA-first resolution the locale no longer touches the lookup key.
    """
    req = InspireRequest(origin_city="Paris", pick_count=4, locale="fr")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 404, "Resource not found")),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value="https://img"),
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "LIS",
                            "city": "Lisbon",
                            "country": "Portugal",
                            "match_reason": "Collines pastel et soleil doux, parfait en couple.",
                            "weather_summary": "20-28°C au printemps",
                            "top_activities": ["Alfama", "Pastel de nata", "Belém"],
                        },
                        {
                            "iata": "ATH",
                            "city": "Athens",
                            "country": "Greece",
                            "match_reason": "Berceau antique et tavernes animées pour une escapade.",
                            "weather_summary": "18-26°C au printemps",
                            "top_activities": ["Acropole", "Plaka", "Musée national"],
                        },
                        {
                            "iata": "VIE",
                            "city": "Vienna",
                            "country": "Austria",
                            "match_reason": "Cafés impériaux et musées à foison pour les curieux.",
                            "weather_summary": "12-20°C au printemps",
                            "top_activities": ["Schönbrunn", "Ringstrasse", "Café Sacher"],
                        },
                        {
                            "iata": "CPH",
                            "city": "Copenhagen",
                            "country": "Denmark",
                            "match_reason": "Design scandinave et balades à vélo le long des canaux.",
                            "weather_summary": "10-18°C au printemps",
                            "top_activities": ["Nyhavn", "Tivoli", "Christiania"],
                        },
                    ]
                }
            )
        ),
    )
    events = await _drain(InspireOrchestrator.stream(req))
    complete = next(p for t, p in events if t == "complete")
    assert complete["source"] == "llm_only"
    iatas = [d["iata"] for d in complete["destinations"]]
    # All four resolve — the French narrative never reached the resolver.
    assert iatas == ["LIS", "ATH", "VIE", "CPH"]


@pytest.mark.asyncio
async def test_fallback_overfetch_compensates_unresolvable(monkeypatch):
    """Over-fetch: unresolvable suggestions don't shrink the list below pick_count."""
    req = InspireRequest(origin_city="Paris", pick_count=2, locale="en")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "down")),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value="https://img"),
    )
    # 4 suggestions (pick_count + FALLBACK_OVERFETCH): two unresolvable,
    # two valid — the final list must still hold pick_count cards.
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub(
            json.dumps(
                {
                    "destinations": [
                        {
                            "iata": "ZZZ",
                            "city": "Zzxqqland",
                            "country": "Nowherestan",
                            "match_reason": "unresolvable",
                            "weather_summary": "n/a",
                            "top_activities": ["a", "b", "c"],
                        },
                        {
                            "iata": "LIS",
                            "city": "Lisbon",
                            "country": "Portugal",
                            "match_reason": "Pastel cliffs and sunshine.",
                            "weather_summary": "20-28°C",
                            "top_activities": ["Alfama", "Pastel de nata", "Belém"],
                        },
                        {
                            "iata": "QQQ",
                            "city": "Qqzzxton",
                            "country": "Nowherestan",
                            "match_reason": "unresolvable",
                            "weather_summary": "n/a",
                            "top_activities": ["a", "b", "c"],
                        },
                        {
                            "iata": "BCN",
                            "city": "Barcelona",
                            "country": "Spain",
                            "match_reason": "Beach plus Gaudí.",
                            "weather_summary": "22-32°C",
                            "top_activities": ["Sagrada", "Tapas", "Park Güell"],
                        },
                    ]
                }
            )
        ),
    )
    events = await _drain(InspireOrchestrator.stream(req))
    complete = next(p for t, p in events if t == "complete")
    iatas = [d["iata"] for d in complete["destinations"]]
    assert iatas == ["LIS", "BCN"]


@pytest.mark.asyncio
async def test_llm_invalid_json_emits_error(monkeypatch):
    """Defensive: a non-JSON ranker reply surfaces a clean SSE error rather than a 500."""
    req = InspireRequest(origin_city="Paris")
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.AmadeusService.search_flight_destinations",
        AsyncMock(
            return_value=_make_inspire_response(
                [{"iata": "BCN", "price": "120"}, {"iata": "LIS", "price": "140"}]
            )
        ),
    )
    monkeypatch.setattr(
        "src.services.inspire_orchestrator.get_weather",
        AsyncMock(return_value={"avg_temp_c": 25, "description": "warm"}),
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _llm_chat_completion_stub("not json at all"),
    )

    events = await _drain(InspireOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "error" in types
    err = next(p for t, p in events if t == "error")
    assert err["code"] == "INSPIRE_RANK_INVALID_JSON"
