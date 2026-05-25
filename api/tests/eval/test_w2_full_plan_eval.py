"""W2 — full-plan eval cases.

The audit's worst W2 findings were:

- C1: trip dates were silently overwritten by ``today + 30`` because
  the orchestrator's final state never carried ``departure_date`` /
  ``return_date``.
- C2: Marseille (FR / FR, ~660 km) got a fictitious flight quote
  instead of being routed to TGV.
- C6: empty Amadeus accommodation rows were persisted as placeholders.
- C7: the budget shipped a FLIGHT line without a matching
  ``ManualFlight`` row.

These tests pin those contracts on the new pipeline. They each run
the orchestrator with stubbed external services and assert on the
shipped DTO shape.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services.full_plan_orchestrator import (
    FullPlanOrchestrator,
    FullPlanRequest,
)
from src.services.llm_router import LLMRouter
from src.services.location_resolver import ResolvedLocation
from src.utils.errors import AppError
from tests.eval.conftest import (
    amadeus_flight_offers_response,
    amadeus_hotel_list_response,
    amadeus_hotel_offers_response,
    drain,
    llm_chat_stub,
)

# ── Stub helpers ──────────────────────────────────────────────────────


def _stub_resolver(monkeypatch, *, origin_city: str, dest_city: str):
    """Drive :class:`LocationResolver` to return canned origin/destination."""
    paris = ResolvedLocation(
        iata="CDG",
        city="Paris",
        country="France",
        country_code="FR",
        lat=49.01,
        lon=2.55,
        source="airportsdata",
        raw_query="Paris",
        raw_locale="fr",
    )
    marseille = ResolvedLocation(
        iata="MRS",
        city="Marseille",
        country="France",
        country_code="FR",
        lat=43.44,
        lon=5.22,
        source="airportsdata",
        raw_query="Marseille",
        raw_locale="fr",
    )
    singapore = ResolvedLocation(
        iata="SIN",
        city="Singapore",
        country="Singapore",
        country_code="SG",
        lat=1.35,
        lon=103.99,
        source="open-meteo+nearest",
        raw_query="Singapour",
        raw_locale="fr",
    )

    async def _resolve(name: str, *, country_hint: str = "", locale: str = "en"):
        if name in {"Paris", "CDG"}:
            return paris
        if name in {"Marseille", "MRS"}:
            return marseille
        if name in {"Singapour", "Singapore", "SIN"}:
            return singapore
        return None

    monkeypatch.setattr("src.services.full_plan_orchestrator.LocationResolver.resolve", _resolve)


def _stub_weather(monkeypatch, *, payload: dict | None = None):
    if payload is None:
        payload = {
            "avg_temp_c": 25,
            "min_temp_c": 18,
            "max_temp_c": 32,
            "rain_probability": 10,
            "description": "Warm and sunny",
            "source": "open-meteo",
        }
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.get_weather",
        AsyncMock(return_value=payload),
    )


def _stub_unsplash(monkeypatch):
    """Stub the SMP-330 cover image pipeline for full-plan eval tests."""
    from src.integrations.cover_image.types import CoverCandidate
    from src.services.cover_image.service import CoverResult

    result = CoverResult(
        primary_url="https://images.unsplash.com/cover.jpg",
        primary_source="wikipedia",
        candidates=[
            CoverCandidate(
                url="https://images.unsplash.com/cover.jpg", source="wikipedia"
            ),
        ],
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.cover_image_service.pick_cover",
        AsyncMock(return_value=result),
    )


def _stub_amadeus_hotels(monkeypatch, *, hotel_id: str, name: str, price_total: float):
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_list",
        AsyncMock(return_value=amadeus_hotel_list_response([hotel_id])),
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_offers",
        AsyncMock(
            return_value=amadeus_hotel_offers_response(
                [
                    {
                        "name": name,
                        "hotel_id": hotel_id,
                        "price_total": price_total,
                        "currency": "EUR",
                    }
                ]
            )
        ),
    )


def _stub_amadeus_flights_down(monkeypatch):
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_flight_offers",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "amadeus down")),
    )


def _stub_amadeus_flights(monkeypatch, legs: list[dict]):
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_flight_offers",
        AsyncMock(return_value=amadeus_flight_offers_response(legs)),
    )


def _stub_amadeus_hotels_down(monkeypatch):
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_list",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "amadeus down")),
    )


# ── Eval cases ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_eval_w2_marseille_tgv_routes_train_with_audit_dates(monkeypatch):
    """Audit C1 + C2 + C6 + C7 in one fixture.

    Paris → Marseille with a "TGV depuis Paris" constraint. Expect:
    - dates round-trip from input to DTO (C1)
    - 2 TRAIN legs, 0 ManualFlight call (C2)
    - accommodation is real (no blank-name placeholder) (C6)
    - budget transport > 0 with no FLIGHT line (C7)
    """
    _stub_resolver(monkeypatch, origin_city="Paris", dest_city="Marseille")
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    _stub_amadeus_hotels(
        monkeypatch,
        hotel_id="HMRS001",
        name="Hôtel Le Vieux-Port",
        price_total=320.0,
    )
    flight_stub = AsyncMock(side_effect=AssertionError("flight should not be called"))
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_flight_offers",
        flight_stub,
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "activities": [
                    {
                        "title": "Vieux-Port walk",
                        "description": "Stroll along the harbour.",
                        "category": "CULTURE",
                        "estimated_cost": 0.0,
                        "suggested_day": 1,
                        "time_of_day": "morning",
                        "location": "Vieux-Port",
                    }
                ],
                "items": [
                    {
                        "name": "TGV ticket",
                        "quantity": 1,
                        "category": "DOCUMENTS",
                        "reason": "Required at boarding.",
                    }
                ],
            }
        ),
    )

    req = FullPlanRequest(
        origin_city="Paris",
        destination_city="Marseille",
        duration_days=4,
        departure_date="2026-06-12",
        return_date="2026-06-15",
        budget_preset="COMFORTABLE",
        nb_travelers=3,
        locale="fr",
        constraints="TGV depuis Paris",
    )
    events = await drain(FullPlanOrchestrator.stream(req))
    cmd = events[-1][1]["trip_draft"]

    flight_stub.assert_not_called()  # C2

    # C1 — dates round-trip.
    assert cmd["start_date"] == "2026-06-12"
    assert cmd["end_date"] == "2026-06-15"

    # C2 — exclusively TRAIN, both directions priced.
    assert len(cmd["transport"]) == 2
    assert all(leg["mode"] == "TRAIN" for leg in cmd["transport"])
    assert all(leg["price"] is not None and leg["price"] > 0 for leg in cmd["transport"])

    # C6 — accommodation came from Amadeus, no blank placeholder.
    assert cmd["accommodations"], "expected at least one accommodation row"
    for acc in cmd["accommodations"]:
        assert acc["name"], "accommodation name must not be blank"
        assert acc["source"] == "amadeus"
    assert cmd["accommodations"][0]["price_total"] == 320.0

    # C7 — budget is keyed by category, no fake FLIGHT line.
    budget = cmd["budget"]
    assert budget["transport"] > 0
    assert budget["accommodation"] == 320.0
    assert budget["food"] > 0
    assert "flight" not in budget  # the new shape has no top-level FLIGHT key


@pytest.mark.asyncio
async def test_eval_w2_singapore_cross_border_uses_amadeus_flight(monkeypatch):
    """Cross-country → FLIGHT mode, Amadeus offer carried in the DTO."""
    _stub_resolver(monkeypatch, origin_city="Paris", dest_city="Singapour")
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    _stub_amadeus_hotels(
        monkeypatch,
        hotel_id="HSIN001",
        name="Marina Bay Sands",
        price_total=1500.0,
    )
    _stub_amadeus_flights(
        monkeypatch,
        [
            {
                "origin": "CDG",
                "destination": "SIN",
                "departure_at": "2026-07-04T22:00:00",
                "arrival_at": "2026-07-05T17:30:00",
                "carrier": "AF",
                "number": "256",
                "price": 540.0,
            },
            {
                "origin": "SIN",
                "destination": "CDG",
                "departure_at": "2026-07-09T11:30:00",
                "arrival_at": "2026-07-09T19:00:00",
                "carrier": "AF",
                "number": "257",
                "price": 540.0,
            },
        ],
    )
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "activities": [
                    {
                        "title": "Gardens by the Bay",
                        "description": "Iconic conservatory.",
                        "category": "NATURE",
                        "estimated_cost": 28.0,
                        "suggested_day": 1,
                        "time_of_day": "afternoon",
                        "location": "Marina Bay",
                    }
                ],
                "items": [
                    {
                        "name": "Passport",
                        "quantity": 1,
                        "category": "DOCUMENTS",
                        "reason": "Required for SG entry.",
                    }
                ],
            }
        ),
    )

    req = FullPlanRequest(
        origin_city="Paris",
        destination_city="Singapour",
        duration_days=5,
        departure_date="2026-07-04",
        return_date="2026-07-09",
        budget_preset="COMFORTABLE",
        nb_travelers=2,
        locale="fr",
    )
    events = await drain(FullPlanOrchestrator.stream(req))
    cmd = events[-1][1]["trip_draft"]

    assert len(cmd["transport"]) == 2
    assert all(leg["mode"] == "FLIGHT" for leg in cmd["transport"])
    assert all(leg["source"] == "amadeus" for leg in cmd["transport"])
    assert all(leg["currency"] == "EUR" for leg in cmd["transport"])
    assert cmd["transport"][0]["origin_iata"] == "CDG"
    assert cmd["transport"][0]["destination_iata"] == "SIN"


@pytest.mark.asyncio
async def test_eval_w2_amadeus_down_dto_still_ships_with_warnings(monkeypatch):
    """When Amadeus is unreachable, the DTO still ships with the LLM-only sub-tasks."""
    _stub_resolver(monkeypatch, origin_city="Paris", dest_city="Singapour")
    _stub_weather(monkeypatch)
    _stub_unsplash(monkeypatch)
    _stub_amadeus_flights_down(monkeypatch)
    _stub_amadeus_hotels_down(monkeypatch)
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        llm_chat_stub(
            {
                "activities": [
                    {
                        "title": "Hawker centre lunch",
                        "description": "Local food court tour.",
                        "category": "FOOD",
                        "estimated_cost": 12.0,
                        "suggested_day": 1,
                        "time_of_day": "afternoon",
                        "location": "Lau Pa Sat",
                    }
                ],
                "items": [
                    {
                        "name": "Passport",
                        "quantity": 1,
                        "category": "DOCUMENTS",
                        "reason": "Mandatory entry doc.",
                    }
                ],
            }
        ),
    )

    req = FullPlanRequest(
        origin_city="Paris",
        destination_city="Singapour",
        duration_days=5,
        departure_date="2026-07-04",
        return_date="2026-07-09",
        nb_travelers=2,
        locale="fr",
    )
    events = await drain(FullPlanOrchestrator.stream(req))
    types = [t for t, _ in events]
    warning_codes = [d["code"] for t, d in events if t == "warning"]
    assert "TRANSPORT_AMADEUS_DOWN" in warning_codes
    assert "ACCOMMODATIONS_AMADEUS_DOWN" in warning_codes
    assert types[-1] == "complete"

    cmd = events[-1][1]["trip_draft"]
    # No transport / accommodations — Amadeus tipped over.
    assert cmd["transport"] == []
    assert cmd["accommodations"] == []
    # Activities + baggage still ship.
    assert cmd["activities"] and cmd["baggage"]


@pytest.mark.asyncio
async def test_eval_w2_origin_unresolved_short_circuits(monkeypatch):
    """An unresolved origin emits an ``error`` event and never calls the LLM."""

    async def _no_resolve(*_args, **_kwargs):
        return None

    monkeypatch.setattr("src.services.full_plan_orchestrator.LocationResolver.resolve", _no_resolve)
    chat_stub = AsyncMock(side_effect=AssertionError("LLM must not be reached"))
    monkeypatch.setattr(LLMRouter, "chat_completion", chat_stub)

    req = FullPlanRequest(
        origin_city="ZzqxNoCity",
        destination_city="Marseille",
        duration_days=4,
        departure_date="2026-06-12",
        return_date="2026-06-15",
    )
    events = await drain(FullPlanOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "error" in types
    err = next(d for t, d in events if t == "error")
    assert err["code"] == "ORIGIN_UNRESOLVED"
    chat_stub.assert_not_called()
