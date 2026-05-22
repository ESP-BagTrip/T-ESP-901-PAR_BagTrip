"""Tests for :class:`FullPlanOrchestrator` (W2 — full plan path).

The orchestrator is a black-box async generator: callers feed in a
:class:`FullPlanRequest`, drain the SSE event tuples, and the final
``complete`` event carries a :class:`TripDraftCommand` dict. The tests
mock the resolver, Amadeus and the LLM router; live behaviour is
verified separately by the Phase 0 PoC and the Phase 3a smoke run.
"""

from __future__ import annotations

import json
import time
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest

from src.services import currency_service
from src.services.full_plan_orchestrator import (
    AccommodationDraft,
    FullPlanOrchestrator,
    FullPlanRequest,
    TransportLeg,
    TripDraftCommand,
)
from src.services.llm_router import LLMRouter
from src.services.location_resolver import ResolvedLocation
from src.utils.errors import AppError
from src.utils.idempotency import idempotency_cache

# ── Fixtures ──────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def _isolate_state() -> None:
    LLMRouter.reset_for_tests()
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]
    yield
    LLMRouter.reset_for_tests()
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]


def _stub_chat(content: str) -> AsyncMock:
    return AsyncMock(
        return_value={
            "choices": [{"message": {"role": "assistant", "content": content}}],
            "usage": {"prompt_tokens": 100, "completion_tokens": 100},
        }
    )


def _origin_loc() -> ResolvedLocation:
    return ResolvedLocation(
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


def _dest_marseille() -> ResolvedLocation:
    return ResolvedLocation(
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


def _dest_singapore() -> ResolvedLocation:
    return ResolvedLocation(
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


def _patch_resolver(monkeypatch, *, origin, destination) -> None:
    """Make :class:`LocationResolver` return canned values."""

    async def _resolve(name: str, *, country_hint: str = "", locale: str = "en"):
        if name in {"Paris", "CDG"}:
            return origin
        return destination

    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.LocationResolver.resolve",
        _resolve,
    )


def _patch_weather(monkeypatch, *, payload: dict[str, Any] | None) -> None:
    if payload is None:

        async def _miss(*_args, **_kwargs):
            raise RuntimeError("offline")
    else:

        async def _miss(*_args, **_kwargs):
            return payload

    monkeypatch.setattr("src.services.full_plan_orchestrator.get_weather", _miss)


def _patch_unsplash(monkeypatch, url: str | None = "https://img") -> None:
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.unsplash_client.fetch_cover_image",
        AsyncMock(return_value=url),
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.unsplash_client.get_fallback_url",
        MagicMock(return_value="https://fallback"),
    )


async def _drain(agen) -> list[tuple[str, dict]]:
    return [item async for item in agen]


# ── Transport mode picker (deterministic) ─────────────────────────────


def test_pick_transport_train_for_short_domestic():
    """Paris → Marseille (660 km, FR/FR) lands TRAIN — kills audit C2."""
    mode = FullPlanOrchestrator._pick_transport_mode(
        _origin_loc(),
        _dest_marseille(),
        FullPlanRequest(origin_city="Paris", destination_city="Marseille"),
    )
    assert mode == "TRAIN"


def test_pick_transport_flight_cross_country():
    """Paris → Singapore (cross-country) is always FLIGHT."""
    mode = FullPlanOrchestrator._pick_transport_mode(
        _origin_loc(),
        _dest_singapore(),
        FullPlanRequest(origin_city="Paris", destination_city="Singapour"),
    )
    assert mode == "FLIGHT"


def test_pick_transport_train_when_constraint_mentions_tgv():
    """Even on long-distance, an explicit ``TGV`` constraint forces train."""
    paris = _origin_loc()
    far_dest = ResolvedLocation(
        iata="MAD",
        city="Madrid",
        country="Spain",
        country_code="ES",
        lat=40.42,
        lon=-3.70,
        source="airportsdata",
        raw_query="Madrid",
        raw_locale="fr",
    )
    mode = FullPlanOrchestrator._pick_transport_mode(
        paris,
        far_dest,
        FullPlanRequest(
            origin_city="Paris",
            destination_city="Madrid",
            constraints="TGV ou train de nuit",
        ),
    )
    assert mode == "TRAIN"


# ── End-to-end flow (mocked) ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_marseille_train_path_emits_complete_with_dto(monkeypatch):
    """Paris → Marseille produces a TripDraftCommand with TRAIN legs and no Amadeus flight call."""
    _patch_resolver(monkeypatch, origin=_origin_loc(), destination=_dest_marseille())
    _patch_weather(
        monkeypatch,
        payload={
            "avg_temp_c": 25,
            "min_temp_c": 18,
            "max_temp_c": 32,
            "rain_probability": 10,
            "description": "Warm and sunny",
            "source": "open-meteo",
        },
    )
    _patch_unsplash(monkeypatch)

    # Activities + baggage LLM stubs.
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _stub_chat(
            json.dumps(
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
            )
        ),
    )

    # Amadeus stubs — accommodations return a plausible offer; flight stub
    # must NOT be hit because we route via TRAIN.
    flight_stub = AsyncMock(side_effect=AssertionError("flight should not be called"))
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_flight_offers",
        flight_stub,
    )

    hotel_list_stub = AsyncMock(
        return_value=MagicMock(
            data=[
                MagicMock(hotelId="HMRS001", name="Sample"),
                MagicMock(hotelId="HMRS002", name="Sample 2"),
            ]
        )
    )
    hotel_offers_stub = AsyncMock(
        return_value=MagicMock(
            data=[
                MagicMock(
                    hotel={"name": "Hôtel Le Vieux-Port", "hotelId": "HMRS001"},
                    offers=[
                        MagicMock(
                            price=MagicMock(total="320", currency="EUR"),
                        )
                    ],
                )
            ]
        )
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_list",
        hotel_list_stub,
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_offers",
        hotel_offers_stub,
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
    events = await _drain(FullPlanOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "progress" in types
    assert "complete" in types
    assert types[-1] == "complete"

    flight_stub.assert_not_called()  # the contract that fixes audit C2

    cmd = events[-1][1]["trip_draft"]
    assert cmd["destination_iata"] == "MRS"
    assert cmd["origin_iata"] == "CDG"
    assert cmd["start_date"] == "2026-06-12"
    assert cmd["end_date"] == "2026-06-15"
    assert cmd["weather"]["avg_temp_c"] == 25
    # Two TRAIN legs (outbound + return), priced.
    assert len(cmd["transport"]) == 2
    assert all(leg["mode"] == "TRAIN" for leg in cmd["transport"])
    assert all(leg["price"] is not None for leg in cmd["transport"])
    # Accommodation has Amadeus origin and a real total.
    assert cmd["accommodations"][0]["source"] == "amadeus"
    assert cmd["accommodations"][0]["price_total"] == 320.0
    # Activities + baggage came from the LLM stub.
    assert cmd["activities"][0]["title"] == "Vieux-Port walk"
    assert cmd["baggage"][0]["name"] == "TGV ticket"
    # Budget cohérent — non-zero across categories that have data.
    assert cmd["budget"]["transport"] > 0
    assert cmd["budget"]["accommodation"] == 320.0
    assert cmd["budget"]["food"] > 0


@pytest.mark.asyncio
async def test_resolution_failure_emits_error_and_stops(monkeypatch):
    """An unresolved origin short-circuits before any LLM/Amadeus call."""

    async def _no_resolve(*_args, **_kwargs):
        return None

    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.LocationResolver.resolve",
        _no_resolve,
    )
    req = FullPlanRequest(origin_city="ZzqxNoCity", destination_city="Marseille")
    events = await _drain(FullPlanOrchestrator.stream(req))
    types = [t for t, _ in events]
    assert "error" in types
    assert next(d for t, d in events if t == "error")["code"] == "ORIGIN_UNRESOLVED"


@pytest.mark.asyncio
async def test_amadeus_failure_does_not_kill_pipeline(monkeypatch):
    """An Amadeus 5xx surfaces as a ``warning`` event but the DTO still ships."""
    _patch_resolver(monkeypatch, origin=_origin_loc(), destination=_dest_singapore())
    _patch_weather(
        monkeypatch,
        payload={
            "avg_temp_c": 28,
            "min_temp_c": 25,
            "max_temp_c": 32,
            "rain_probability": 60,
            "description": "Tropical",
            "source": "open-meteo",
        },
    )
    _patch_unsplash(monkeypatch)
    monkeypatch.setattr(
        LLMRouter,
        "chat_completion",
        _stub_chat(
            json.dumps(
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
            )
        ),
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_flight_offers",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "down")),
    )
    monkeypatch.setattr(
        "src.services.full_plan_orchestrator.AmadeusService.search_hotel_list",
        AsyncMock(side_effect=AppError("UPSTREAM_ERROR", 502, "down")),
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
    events = await _drain(FullPlanOrchestrator.stream(req))
    types = [t for t, _ in events]
    warning_codes = [d["code"] for t, d in events if t == "warning"]
    assert "TRANSPORT_AMADEUS_DOWN" in warning_codes
    assert "ACCOMMODATIONS_AMADEUS_DOWN" in warning_codes
    assert types[-1] == "complete"

    cmd = events[-1][1]["trip_draft"]
    # No transport / accommodations in the DTO since Amadeus tipped over.
    assert cmd["transport"] == []
    assert cmd["accommodations"] == []
    # Activities + baggage still ship — the LLM-only sub-tasks succeeded.
    assert cmd["activities"][0]["title"] == "Gardens by the Bay"
    assert cmd["baggage"][0]["name"] == "Passport"


@pytest.mark.asyncio
async def test_dto_round_trip_through_dataclasses_asdict():
    """The DTO survives ``asdict`` round-trip — required for SSE serialisation."""
    cmd = TripDraftCommand(
        origin_iata="CDG",
        origin_city="Paris",
        destination_iata="MRS",
        destination_city="Marseille",
        destination_country="France",
        destination_country_code="FR",
        destination_lat=43.44,
        destination_lon=5.22,
        start_date="2026-06-12",
        end_date="2026-06-15",
        duration_days=4,
        nb_travelers=3,
        target_budget=None,
        locale="fr",
        cover_image_url=None,
        weather=None,
    )
    from src.services.full_plan_orchestrator import _command_to_dict

    payload = _command_to_dict(cmd)
    assert payload["destination_iata"] == "MRS"
    assert payload["activities"] == []
    assert payload["budget"]["currency"] == "EUR"


# ── Budget currency normalisation ─────────────────────────────────────


class TestComputeBudgetCurrency:
    """``_compute_budget`` normalises foreign-currency Amadeus prices.

    Amadeus quotes hotels/flights in the property's *local* currency; the
    budget breakdown must convert each line to EUR before summing —
    otherwise a Seoul stay priced in KRW ships as a six-figure euro line
    ("1 578 000 €" instead of ~1 088 €).
    """

    @staticmethod
    def _req() -> FullPlanRequest:
        return FullPlanRequest(
            origin_city="Paris",
            destination_city="Seoul",
            duration_days=6,
            departure_date="2026-05-23",
            return_date="2026-05-29",
            budget_preset="COMFORTABLE",
            nb_travelers=1,
        )

    def test_krw_accommodation_is_converted_to_eur(self):
        currency_service.reset_cache()
        # Warm the cache as the ECB refresh job would: 1 EUR = 1450 KRW.
        currency_service._rate_cache[("EUR", "KRW")] = (1450.0, time.monotonic())
        try:
            budget = FullPlanOrchestrator._compute_budget(
                transport=[],
                accommodations=[
                    AccommodationDraft(
                        name="InterContinental Seoul",
                        price_total=1_578_000.0,
                        price_per_night=263_000.0,
                        nights=6,
                        currency="KRW",
                        source="amadeus",
                    )
                ],
                activities=[],
                weather=None,
                req=self._req(),
            )
        finally:
            currency_service.reset_cache()
        # 1 578 000 KRW / 1450 ≈ 1088 €, not the raw six-figure number.
        assert budget.accommodation == pytest.approx(1_578_000 / 1450, abs=1.0)
        assert budget.accommodation < 2_000
        assert budget.currency == "EUR"

    def test_eur_accommodation_is_unchanged_even_on_cold_cache(self):
        # Same-currency conversion is a no-op and never needs a rate.
        currency_service.reset_cache()
        budget = FullPlanOrchestrator._compute_budget(
            transport=[],
            accommodations=[
                AccommodationDraft(
                    name="Hôtel de Paris",
                    price_total=900.0,
                    currency="EUR",
                    source="amadeus",
                )
            ],
            activities=[],
            weather=None,
            req=self._req(),
        )
        assert budget.accommodation == 900.0

    def test_foreign_currency_transport_leg_is_converted(self):
        currency_service.reset_cache()
        currency_service._rate_cache[("EUR", "KRW")] = (1450.0, time.monotonic())
        try:
            budget = FullPlanOrchestrator._compute_budget(
                transport=[
                    TransportLeg(
                        mode="FLIGHT",
                        direction="OUTBOUND",
                        price=290_000.0,
                        currency="KRW",
                        source="amadeus",
                    )
                ],
                accommodations=[],
                activities=[],
                weather=None,
                req=self._req(),
            )
        finally:
            currency_service.reset_cache()
        # Leg: 290 000 KRW / 1450 = 200 €, plus the deterministic
        # local-transport allowance (COMFORTABLE = 15 €/day × 6 days).
        assert budget.transport == pytest.approx(200.0 + 90.0)
