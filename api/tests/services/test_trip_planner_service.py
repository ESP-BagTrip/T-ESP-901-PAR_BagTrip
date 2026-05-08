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
    _enrich_destinations_with_images,
    _sse,
    _to_inspire_request,
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
        assert state["target_budget"] is None

    def test_target_budget_threaded_into_state(self):
        """Topic 01 (B2): the numeric target reaches the agent state."""
        req = PlanTripRequest(targetBudget=2500.0)
        state = _build_initial_state(req)
        assert state["target_budget"] == 2500.0


# ---------------------------------------------------------------------------
# _to_inspire_request() — wizard payload → orchestrator dataclass mapping
# ---------------------------------------------------------------------------


class TestToInspireRequest:
    def test_maps_camel_case_request_into_inspire_dataclass(self):
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
        assert ir.travel_types == "culture"
        assert ir.duration_days == 5
        assert ir.departure_date == "2026-07-04"
        assert ir.return_date == "2026-07-10"
        assert ir.companions == "couple"
        assert ir.constraints == "budget moyen"
        assert ir.nb_travelers == 2
        assert ir.budget_preset == "COMFORTABLE"
        assert ir.locale == "fr"

    def test_defaults_for_minimal_request(self):
        ir = _to_inspire_request(PlanTripRequest())
        assert ir.origin_city == ""
        assert ir.duration_days == 7
        assert ir.companions == "solo"
        assert ir.nb_travelers == 1
        assert ir.locale == "en"


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


class TestEnrichDestinationsWithImages:
    @pytest.mark.asyncio
    async def test_adds_image_url_from_unsplash(self):
        destinations = [{"city": "Tokyo", "country": "Japan"}]
        with patch("src.services.trip_planner_service.unsplash_client") as mock_unsplash:
            mock_unsplash.fetch_cover_image = AsyncMock(
                return_value="https://unsplash.com/tokyo.jpg"
            )
            result = await _enrich_destinations_with_images(destinations)
        assert result[0]["image_url"] == "https://unsplash.com/tokyo.jpg"

    @pytest.mark.asyncio
    async def test_uses_fallback_when_unsplash_returns_none(self):
        destinations = [{"city": "Paris", "country": "France"}]
        with patch("src.services.trip_planner_service.unsplash_client") as mock_unsplash:
            mock_unsplash.fetch_cover_image = AsyncMock(return_value=None)
            mock_unsplash.get_fallback_url = MagicMock(return_value="https://fallback.jpg")
            result = await _enrich_destinations_with_images(destinations)
        assert result[0]["image_url"] == "https://fallback.jpg"

    @pytest.mark.asyncio
    async def test_skips_empty_city(self):
        destinations = [{"country": "Unknown"}]
        with patch("src.services.trip_planner_service.unsplash_client") as mock_unsplash:
            mock_unsplash.fetch_cover_image = AsyncMock()
            result = await _enrich_destinations_with_images(destinations)
        mock_unsplash.fetch_cover_image.assert_not_awaited()
        assert "image_url" not in result[0]


class TestStreamPlan:
    @pytest.mark.asyncio
    async def test_destinations_only_delegates_to_inspire_orchestrator(self, mock_db_session):
        """W1 path: stream_plan forwards InspireOrchestrator events as SSE."""
        req = PlanTripRequest(mode="destinations_only", originCity="Paris")

        async def _fake_stream(_):
            yield "progress", {"phase": "starting"}
            yield "destinations", {"destinations": [{"iata": "BCN", "city": "Barcelona"}]}
            yield "complete", {"destinations": [], "mode": "destinations_only"}

        with patch(
            "src.services.trip_planner_service.InspireOrchestrator.stream",
            side_effect=_fake_stream,
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        # The orchestrator emits its own ``progress``/``destinations``/
        # ``complete`` events; ``stream_plan`` only adds the terminal
        # ``done`` from its ``finally`` block. The legacy "Starting trip
        # planning…" duplicate progress event was removed for W1.
        assert "progress" in event_names
        assert "destinations" in event_names
        assert "complete" in event_names
        assert event_names[-1] == "done"
        # The destinations payload comes verbatim from the orchestrator.
        dest_event = next(d for n, d in events if n == "destinations")
        assert dest_event["destinations"][0]["iata"] == "BCN"

    @pytest.mark.asyncio
    async def test_destinations_only_orchestrator_failure_still_emits_done(self, mock_db_session):
        req = PlanTripRequest(mode="destinations_only", originCity="Paris")

        async def _fake_stream(_):
            raise RuntimeError("inspire blew up")
            yield  # pragma: no cover - generator marker

        with patch(
            "src.services.trip_planner_service.InspireOrchestrator.stream",
            side_effect=_fake_stream,
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        assert "error" in event_names
        assert event_names[-1] == "done"

    @pytest.mark.asyncio
    async def test_destinations_only_hung_call_emits_timeout_error(self, mock_db_session):
        """SMP-324 — the destinations_only path used to hang silently
        when the LLM never came back. The fast-path now caps the work
        at ``GRAPH_TIMEOUT_SECONDS`` and emits an explicit error event."""
        import asyncio

        async def _hang(_state):
            await asyncio.sleep(60)

        req = PlanTripRequest(mode="destinations_only")
        with (
            patch(
                "src.services.trip_planner_service._quick_destination_suggestions",
                _hang,
            ),
            patch("src.services.trip_planner_service.settings.GRAPH_TIMEOUT_SECONDS", 0.1),
        ):
            lines = await _collect(TripPlannerService.stream_plan(req, "u1", mock_db_session))

        events = _parse_sse_events(lines)
        event_names = [name for name, _ in events]
        assert "error" in event_names
        # Errors must always be followed by a done so the client can
        # close cleanly; that's the contract the SSE consumer relies on.
        assert event_names[-1] == "done"
        # The error payload carries the documented code so the client
        # can branch on it (retry vs surface a translated message).
        error_payload = next(payload for name, payload in events if name == "error")
        assert error_payload.get("code") == "DESTINATIONS_TIMEOUT"

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

        # SMP-324 — stream_plan now persists a DRAFT trip after the
        # graph finishes, then ships its tripId in the ``complete`` SSE
        # event. We patch the persistence call so the test stays focused
        # on the streaming contract (a dedicated suite covers the
        # service end-to-end).
        fake_trip = MagicMock(id="trip-uuid", status="DRAFT")

        with (
            patch(
                "src.services.trip_planner_service.async_generator_with_timeout",
                lambda gen, total_timeout_seconds: gen,
            ),
            patch("src.services.plan_service.PlanService.increment_ai_generation") as mock_incr,
            patch(
                "src.services.trip_planner_service.PlanDraftService.create_draft_from_state",
                new=AsyncMock(return_value=fake_trip),
            ),
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
        assert "complete" in event_names
        assert event_names[-1] == "done"
        complete_payload = next(payload for name, payload in events if name == "complete")
        assert complete_payload["tripId"] == "trip-uuid"
        assert complete_payload["status"] == "DRAFT"
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
