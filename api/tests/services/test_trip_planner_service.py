"""Tests for :class:`TripPlannerService.stream_plan`.

The service is a thin SSE wrapper now: W1 ``destinations_only`` mode
forwards :class:`InspireOrchestrator` events; the full-plan path runs
:class:`FullPlanOrchestrator`, applies :func:`schedule_activities` and
persists via :class:`PlanDraftService`. Both paths emit a terminal
``done`` from a ``finally`` block.

Each test stubs the heavy collaborators and asserts the SSE
event sequence + the persistence side-effects (or their absence).
"""

from __future__ import annotations

import json
from datetime import date
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest

from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.services.trip_planner_service import (
    TripPlannerService,
    _sse,
    _to_full_plan_request,
    _to_inspire_request,
    _trip_draft_from_dict,
)

# ── _sse() formatter ───────────────────────────────────────────────────


class TestSseFormat:
    def test_event_and_data_lines(self):
        out = _sse("progress", {"phase": "starting"})
        assert out.startswith("event: progress\n")
        assert 'data: {"phase": "starting"}' in out
        assert out.endswith("\n\n")

    def test_dates_serialise(self):
        out = _sse("x", {"d": date(2026, 4, 11)})
        assert "2026-04-11" in out

    def test_non_ascii_passthrough(self):
        out = _sse("x", {"msg": "héllo"})
        assert "héllo" in out


# ── Wizard payload → orchestrator request mapping ─────────────────────


class TestRequestMappers:
    def test_inspire_mapping_picks_camel_case_fields(self):
        req = PlanTripRequest(
            originCity="Paris",
            travelTypes="culture",
            durationDays=5,
            departureDate="2026-07-04",
            returnDate="2026-07-10",
            companions="couple",
            constraints="budget moyen",
            nbTravelers=2,
            budgetPreset="COMFORTABLE",
            locale="fr",
            mode="destinations_only",
        )
        ir = _to_inspire_request(req)
        assert ir.origin_city == "Paris"
        assert ir.duration_days == 5
        assert ir.locale == "fr"
        assert ir.budget_preset == "COMFORTABLE"

    def test_full_plan_mapping_carries_destination_iata_and_target_budget(self):
        req = PlanTripRequest(
            originCity="Paris",
            destinationCity="Marseille",
            destinationIata="MRS",
            durationDays=4,
            departureDate="2026-06-12",
            returnDate="2026-06-15",
            constraints="TGV depuis Paris",
            nbTravelers=3,
            budgetPreset="COMFORTABLE",
            targetBudget=1800.0,
            locale="fr",
        )
        fr = _to_full_plan_request(req)
        assert fr.destination_iata == "MRS"
        assert fr.target_budget == 1800.0
        assert fr.constraints == "TGV depuis Paris"


# ── trip_draft round-trip (orchestrator dict → DTO) ───────────────────


class TestTripDraftRoundTrip:
    def test_minimal_payload_rebuilds_to_dataclass(self):
        payload = {
            "origin_iata": "CDG",
            "origin_city": "Paris",
            "destination_iata": "MRS",
            "destination_city": "Marseille",
            "destination_country": "France",
            "destination_country_code": "FR",
            "destination_lat": 43.44,
            "destination_lon": 5.22,
            "start_date": "2026-06-12",
            "end_date": "2026-06-15",
            "duration_days": 4,
            "nb_travelers": 3,
            "target_budget": None,
            "locale": "fr",
            "cover_image_url": None,
            "weather": None,
            "activities": [
                {
                    "title": "Vieux-Port walk",
                    "description": "Stroll the harbour.",
                    "category": "CULTURE",
                    "estimated_cost": 0.0,
                    "suggested_day": 1,
                    "time_of_day": "morning",
                    "location": "Vieux-Port",
                }
            ],
            "accommodations": [],
            "transport": [],
            "baggage": [],
            "budget": {},
        }
        cmd = _trip_draft_from_dict(payload)
        assert cmd.destination_iata == "MRS"
        assert cmd.activities[0].title == "Vieux-Port walk"
        assert cmd.budget.currency == "EUR"


# ── stream_plan — W1 path ─────────────────────────────────────────────


async def _drain(agen) -> list[tuple[str, dict]]:
    out: list[tuple[str, dict]] = []
    async for raw in agen:
        head, _, _ = raw.partition("\n\n")
        parts = head.split("\n")
        out.append((parts[0].removeprefix("event: "), json.loads(parts[1].removeprefix("data: "))))
    return out


@pytest.mark.asyncio
async def test_destinations_only_delegates_to_inspire_orchestrator():
    """W1 path forwards InspireOrchestrator events verbatim + ``done``."""
    req = PlanTripRequest(mode="destinations_only", originCity="Paris")

    async def _fake_stream(_):
        yield "progress", {"phase": "starting"}
        yield "destinations", {"destinations": [{"iata": "BCN"}]}
        yield "complete", {"destinations": [], "mode": "destinations_only"}

    with patch(
        "src.services.trip_planner_service.InspireOrchestrator.stream",
        side_effect=_fake_stream,
    ):
        events = await _drain(TripPlannerService.stream_plan(req, "u1", MagicMock()))

    names = [n for n, _ in events]
    assert "progress" in names
    assert "destinations" in names
    assert "complete" in names
    assert names[-1] == "done"


# ── stream_plan — W2 path (full plan) ─────────────────────────────────


def _full_plan_request() -> PlanTripRequest:
    return PlanTripRequest(
        originCity="Paris",
        destinationCity="Marseille",
        destinationIata="MRS",
        durationDays=4,
        departureDate="2026-06-12",
        returnDate="2026-06-15",
        constraints="TGV depuis Paris",
        nbTravelers=3,
        budgetPreset="COMFORTABLE",
        locale="fr",
    )


def _orchestrator_complete_payload() -> dict:
    return {
        "origin_iata": "CDG",
        "origin_city": "Paris",
        "destination_iata": "MRS",
        "destination_city": "Marseille",
        "destination_country": "France",
        "destination_country_code": "FR",
        "destination_lat": 43.44,
        "destination_lon": 5.22,
        "start_date": "2026-06-12",
        "end_date": "2026-06-15",
        "duration_days": 4,
        "nb_travelers": 3,
        "target_budget": None,
        "locale": "fr",
        "cover_image_url": None,
        "weather": None,
        "activities": [],
        "accommodations": [],
        "transport": [
            {
                "mode": "TRAIN",
                "direction": "OUTBOUND",
                "carrier": "National rail",
                "code": "",
                "origin_iata": "CDG",
                "destination_iata": "MRS",
                "origin_city": "Paris",
                "destination_city": "Marseille",
                "departure_at": "2026-06-12",
                "arrival_at": "2026-06-12",
                "price": 60.0,
                "currency": "EUR",
                "source": "estimated",
            }
        ],
        "baggage": [],
        "budget": {},
    }


@pytest.mark.asyncio
async def test_full_plan_path_persists_and_emits_trip_id():
    """W2 path swallows orchestrator's ``complete``, re-emits with ``tripId``."""
    request = _full_plan_request()

    async def _fake_full_plan(_):
        yield "progress", {"phase": "starting"}
        yield "destinations", {"destinations": [{"iata": "MRS"}]}
        yield "transport", {"legs": [{"mode": "TRAIN"}]}
        yield "complete", {"trip_draft": _orchestrator_complete_payload(), "elapsed_s": 8.4}

    fake_user = SimpleNamespace(id="u1")
    fake_trip = SimpleNamespace(id="trip-uuid-123", status="DRAFT")
    fake_db = MagicMock()
    fake_db.query.return_value.filter.return_value.first.return_value = fake_user

    with (
        patch(
            "src.services.trip_planner_service.FullPlanOrchestrator.stream",
            side_effect=_fake_full_plan,
        ),
        patch(
            "src.services.trip_planner_service.PlanDraftService.create_draft_from_command",
            return_value=fake_trip,
        ) as persist,
        patch("src.services.trip_planner_service.PlanService.increment_ai_generation"),
    ):
        events = await _drain(TripPlannerService.stream_plan(request, "u1", fake_db))

    names = [n for n, _ in events]
    # The orchestrator's ``complete`` is swallowed; we re-emit one with tripId.
    completes = [d for n, d in events if n == "complete"]
    assert len(completes) == 1
    assert completes[0]["tripId"] == "trip-uuid-123"
    assert completes[0]["status"] == "DRAFT"
    assert completes[0]["tripDraft"]["destination_iata"] == "MRS"
    assert names[-1] == "done"
    persist.assert_called_once()


@pytest.mark.asyncio
async def test_full_plan_path_orchestrator_error_skips_persist():
    """Orchestrator yields ``error`` before ``complete`` → no persist, ``done`` still fires."""
    request = _full_plan_request()

    async def _fake_full_plan(_):
        yield "progress", {"phase": "starting"}
        yield "error", {"code": "ORIGIN_UNRESOLVED", "message": "boom"}

    fake_db = MagicMock()
    with (
        patch(
            "src.services.trip_planner_service.FullPlanOrchestrator.stream",
            side_effect=_fake_full_plan,
        ),
        patch(
            "src.services.trip_planner_service.PlanDraftService.create_draft_from_command"
        ) as persist,
    ):
        events = await _drain(TripPlannerService.stream_plan(request, "u1", fake_db))

    names = [n for n, _ in events]
    assert "error" in names
    assert names[-1] == "done"
    persist.assert_not_called()


@pytest.mark.asyncio
async def test_full_plan_path_persistence_failure_emits_error_and_done():
    """If the persistence layer raises, we surface a clean ``error`` SSE."""
    request = _full_plan_request()

    async def _fake_full_plan(_):
        yield "complete", {"trip_draft": _orchestrator_complete_payload()}

    fake_user = SimpleNamespace(id="u1")
    fake_db = MagicMock()
    fake_db.query.return_value.filter.return_value.first.return_value = fake_user

    with (
        patch(
            "src.services.trip_planner_service.FullPlanOrchestrator.stream",
            side_effect=_fake_full_plan,
        ),
        patch(
            "src.services.trip_planner_service.PlanDraftService.create_draft_from_command",
            side_effect=RuntimeError("db fell over"),
        ),
    ):
        events = await _drain(TripPlannerService.stream_plan(request, "u1", fake_db))

    names = [n for n, _ in events]
    assert names[-1] == "done"
    err = next(d for n, d in events if n == "error")
    assert "db fell over" in err["message"]


@pytest.mark.asyncio
async def test_full_plan_path_user_disappeared_raises_clean_error():
    """A user_id that no longer maps to a row → graceful ``error`` event."""
    request = _full_plan_request()

    async def _fake_full_plan(_):
        yield "complete", {"trip_draft": _orchestrator_complete_payload()}

    fake_db = MagicMock()
    fake_db.query.return_value.filter.return_value.first.return_value = None

    with patch(
        "src.services.trip_planner_service.FullPlanOrchestrator.stream",
        side_effect=_fake_full_plan,
    ):
        events = await _drain(TripPlannerService.stream_plan(request, "u-gone", fake_db))

    names = [n for n, _ in events]
    err = next(d for n, d in events if n == "error")
    assert "u-gone" in err["message"]
    assert names[-1] == "done"


@pytest.mark.asyncio
async def test_full_plan_path_quota_increment_failure_does_not_break_stream():
    """Quota increment is best-effort — its failure must not eat the trip."""
    request = _full_plan_request()

    async def _fake_full_plan(_):
        yield "complete", {"trip_draft": _orchestrator_complete_payload()}

    fake_user = SimpleNamespace(id="u1")
    fake_trip = SimpleNamespace(id="trip-2", status="DRAFT")
    fake_db = MagicMock()
    fake_db.query.return_value.filter.return_value.first.return_value = fake_user

    with (
        patch(
            "src.services.trip_planner_service.FullPlanOrchestrator.stream",
            side_effect=_fake_full_plan,
        ),
        patch(
            "src.services.trip_planner_service.PlanDraftService.create_draft_from_command",
            return_value=fake_trip,
        ),
        patch(
            "src.services.trip_planner_service.PlanService.increment_ai_generation",
            side_effect=RuntimeError("quota tracker offline"),
        ),
    ):
        events = await _drain(TripPlannerService.stream_plan(request, "u1", fake_db))

    # Trip still completes; quota error is logged but never bubbles.
    names = [n for n, _ in events]
    completes = [d for n, d in events if n == "complete"]
    assert completes and completes[0]["tripId"] == "trip-2"
    assert names[-1] == "done"
