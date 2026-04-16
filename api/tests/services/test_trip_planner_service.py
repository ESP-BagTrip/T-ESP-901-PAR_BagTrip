"""Unit tests for `TripPlannerService.stream_plan` and friends.

The service owns the full SSE pipeline from request → LangGraph stream → SSE
event strings. Because the graph itself is external (and heavy), we stub it
per-test using `AsyncIterator` fakes and verify:
- `_build_initial_state` normalises the request into the graph state shape
- The `destinations_only` fast path emits a complete/done pair
- The full path yields graph events + always emits `done` via `try/finally`
- Timeouts and exceptions are surfaced as `error` events but still emit `done`
- Successful completion increments the AI quota
"""

from __future__ import annotations

import json
from datetime import date, timedelta
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.api.ai.plan_trip_schemas import PlanTripRequest
from src.services.trip_planner_service import (
    TripPlannerService,
    _build_initial_state,
    _quick_destination_suggestions,
    _sse,
)

# ---------------------------------------------------------------------------
# _sse() format helper
# ---------------------------------------------------------------------------


class TestSseFormat:
    def test_sse_format_includes_event_and_data_lines(self):
        out = _sse("progress", {"phase": "starting"})
        assert out.startswith("event: progress\n")
        assert 'data: {"phase": "starting"}' in out
        assert out.endswith("\n\n")

    def test_sse_serializes_dates_as_strings(self):
        out = _sse("x", {"d": date(2026, 4, 11)})
        assert "2026-04-11" in out

    def test_sse_non_ascii(self):
        out = _sse("x", {"msg": "héllo"})
        assert "héllo" in out


# ---------------------------------------------------------------------------
# _build_initial_state()
# ---------------------------------------------------------------------------


class TestBuildInitialState:
    def test_explicit_dates_preserved(self):
        req = PlanTripRequest(
            departureDate="2026-06-01",
            returnDate="2026-06-08",
            durationDays=7,
            travelTypes="nature",
            originCity="Paris",
        )
        state = _build_initial_state(req)
        assert state["departure_date"] == "2026-06-01"
        assert state["return_date"] == "2026-06-08"
        assert state["duration_days"] == 7
        assert state["travel_types"] == "nature"
        assert state["origin_city"] == "Paris"

    def test_preferred_month_derives_dates(self):
        req = PlanTripRequest(
            durationDays=5,
            preferredMonth=7,
            preferredYear=2027,
            dateMode="month",
        )
        state = _build_initial_state(req)
        assert state["departure_date"] == "2027-07-15"
        assert state["return_date"] == "2027-07-20"

    def test_flexible_mode_falls_back_to_30_days_out(self):
        req = PlanTripRequest(durationDays=4, dateMode="flexible")
        state = _build_initial_state(req)
        expected_start = date.today() + timedelta(days=30)
        assert state["departure_date"] == str(expected_start)
        assert state["return_date"] == str(expected_start + timedelta(days=4))

    def test_defaults_for_empty_request(self):
        req = PlanTripRequest()
        state = _build_initial_state(req)
        assert state["duration_days"] == 7  # default
        assert state["companions"] == "solo"
        assert state["nb_travelers"] == 1
        assert state["events"] == []
        assert state["errors"] == []


# ---------------------------------------------------------------------------
# _quick_destination_suggestions()
# ---------------------------------------------------------------------------


class TestQuickDestinationSuggestions:
    @pytest.mark.asyncio
    async def test_builds_prompt_and_returns_destinations(self):
        state = {
            "travel_types": "beach",
            "budget_preset": "mid",
            "duration_days": 7,
            "companions": "couple",
            "nb_travelers": 2,
        }
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(
            return_value={"destinations": [{"city": "Bali", "country": "Indonesia"}]}
        )
        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await _quick_destination_suggestions(state)
        assert len(result) == 1
        assert result[0]["city"] == "Bali"
        fake_llm.acall_llm.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_empty_state_uses_fallback_prompt(self):
        fake_llm = MagicMock()
        fake_llm.acall_llm = AsyncMock(return_value={"destinations": []})
        with patch("src.services.llm_service.LLMService", return_value=fake_llm):
            result = await _quick_destination_suggestions({})
        assert result == []
        _, user_prompt = fake_llm.acall_llm.call_args.args
        assert "diverse" in user_prompt.lower()


# ---------------------------------------------------------------------------
# stream_plan() — integration-style with stubbed graph
# ---------------------------------------------------------------------------


class _FakeAsyncIter:
    """Async iterator yielding a pre-seeded list of values."""

    def __init__(self, values):
        self._values = iter(values)

    def __aiter__(self):
        return self

    async def __anext__(self):
        try:
            return next(self._values)
        except StopIteration as exc:
            raise StopAsyncIteration from exc


async def _collect(agen):
    """Drain an async generator into a list of strings."""
    return [item async for item in agen]


def _parse_sse_events(lines: list[str]) -> list[tuple[str, dict]]:
    """Parse `event: X\\ndata: {...}\\n\\n` strings into (event, payload) tuples."""
    events: list[tuple[str, dict]] = []
    for line in lines:
        head, _, _ = line.partition("\n\n")
        parts = head.split("\n")
        event = parts[0].removeprefix("event: ")
        data = json.loads(parts[1].removeprefix("data: "))
        events.append((event, data))
    return events


class TestStreamPlan:
    @pytest.mark.asyncio
    async def test_destinations_only_fast_path(self, mock_db_session):
        req = PlanTripRequest(mode="destinations_only", travelTypes="nature")
        with patch(
            "src.services.trip_planner_service._quick_destination_suggestions",
            AsyncMock(return_value=[{"city": "Kyoto"}]),
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        assert "progress" in event_names
        assert "destinations" in event_names
        assert "complete" in event_names
        assert event_names[-1] == "done"

    @pytest.mark.asyncio
    async def test_destinations_only_error_still_emits_done(self, mock_db_session):
        req = PlanTripRequest(mode="destinations_only")
        with patch(
            "src.services.trip_planner_service._quick_destination_suggestions",
            AsyncMock(side_effect=RuntimeError("LLM unavailable")),
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        assert "error" in event_names
        assert event_names[-1] == "done"

    @pytest.mark.asyncio
    async def test_full_graph_success_emits_done_and_increments_quota(
        self, mock_db_session, make_user
    ):
        req = PlanTripRequest(destinationCity="Paris")
        # Stub the graph to yield a destinations event then finish
        fake_graph = MagicMock()
        fake_graph.astream = MagicMock(
            return_value=_FakeAsyncIter(
                [
                    {
                        "destination_research": {
                            "events": [{"event": "destinations", "data": {"destinations": []}}],
                        }
                    }
                ]
            )
        )
        user = make_user()
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        with (
            patch(
                "src.services.trip_planner_service.async_generator_with_timeout",
                lambda gen, total_timeout_seconds: gen,
            ),
            patch("src.services.plan_service.PlanService.increment_ai_generation") as mock_incr,
            patch(
                "src.agent.graph.graph",
                new=fake_graph,
            ),
        ):
            lines = await _collect(
                TripPlannerService.stream_plan(req, str(user.id), mock_db_session)
            )

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        assert "destinations" in event_names
        assert event_names[-1] == "done"
        mock_incr.assert_called_once()

    @pytest.mark.asyncio
    async def test_graph_timeout_emits_error_and_done(self, mock_db_session):
        req = PlanTripRequest(destinationCity="Paris")

        async def _raise_timeout(*_args, **_kwargs):
            raise TimeoutError("graph too slow")
            yield  # pragma: no cover — needed to make this an async generator

        fake_graph = MagicMock()
        fake_graph.astream = MagicMock(return_value=_FakeAsyncIter([]))
        with (
            patch(
                "src.services.trip_planner_service.async_generator_with_timeout",
                _raise_timeout,
            ),
            patch("src.agent.graph.graph", new=fake_graph),
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        names = [n for n, _ in events]
        assert "error" in names
        assert names[-1] == "done"
        error_payload = next(data for name, data in events if name == "error")
        assert "timed out" in error_payload["message"].lower()

    @pytest.mark.asyncio
    async def test_graph_exception_emits_error_and_done(self, mock_db_session):
        req = PlanTripRequest(destinationCity="Paris")

        async def _raise_generic(*_args, **_kwargs):
            raise RuntimeError("graph crashed")
            yield  # pragma: no cover

        fake_graph = MagicMock()
        fake_graph.astream = MagicMock(return_value=_FakeAsyncIter([]))
        with (
            patch(
                "src.services.trip_planner_service.async_generator_with_timeout",
                _raise_generic,
            ),
            patch("src.agent.graph.graph", new=fake_graph),
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        names = [n for n, _ in events]
        assert "error" in names
        assert names[-1] == "done"

    @pytest.mark.asyncio
    async def test_stream_graph_dedupes_events_and_emits_progress(self):
        # Emit the same "destinations" event twice from the same node → should
        # only be sent once, followed by the parallel_planning progress event.
        node_update = {
            "destination_research": {
                "events": [
                    {"event": "destinations", "data": {"destinations": []}},
                    {"event": "destinations", "data": {"destinations": []}},
                ],
                "errors": [],
            }
        }
        fake_graph = SimpleNamespace(astream=MagicMock(return_value=_FakeAsyncIter([node_update])))
        with patch(
            "src.services.trip_planner_service.async_generator_with_timeout",
            lambda gen, total_timeout_seconds: gen,
        ):
            lines = await _collect(
                TripPlannerService._stream_graph(fake_graph, {"departure_date": ""})
            )

        events = _parse_sse_events(lines)
        dedup_count = sum(1 for name, _ in events if name == "destinations")
        assert dedup_count == 1
        progress_phases = [data.get("phase") for name, data in events if name == "progress"]
        assert "parallel_planning" in progress_phases
