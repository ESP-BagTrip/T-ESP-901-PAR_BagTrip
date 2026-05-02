"""Unit tests for `src.agent.runtime_budget`.

Covers:
- `remaining()` returns infinity when no deadline is set
- `remaining()` returns the correct delta when a deadline is in the future
- `remaining()` clamps to 0 (never negative) when the deadline has passed
- `guard()` passes silently when enough time remains
- `guard()` raises `BudgetExceeded` with a helpful message when too little time
- `track()` accumulates elapsed time into `budget_consumed_seconds`
- `track()` still accumulates on exceptions (finally block)
"""

from __future__ import annotations

import time

import pytest

from src.agent.runtime_budget import BudgetExceeded, consumed, guard, remaining, track


class TestRemaining:
    def test_returns_infinity_when_no_deadline(self):
        state: dict = {}
        assert remaining(state) == float("inf")

    def test_returns_positive_delta_for_future_deadline(self):
        state = {"budget_deadline_monotonic": time.monotonic() + 30.0}
        left = remaining(state)
        assert 29.0 < left <= 30.0

    def test_clamps_to_zero_when_deadline_passed(self):
        state = {"budget_deadline_monotonic": time.monotonic() - 10.0}
        assert remaining(state) == 0.0


class TestConsumed:
    def test_returns_zero_when_no_consumed_field(self):
        assert consumed({}) == 0.0

    def test_returns_tracked_value(self):
        assert consumed({"budget_consumed_seconds": 12.5}) == 12.5


class TestGuard:
    def test_passes_silently_when_enough_time_remains(self):
        state = {"budget_deadline_monotonic": time.monotonic() + 60.0}
        guard(state, min_required=5.0)  # no raise

    def test_raises_budget_exceeded_when_below_minimum(self):
        state = {
            "budget_deadline_monotonic": time.monotonic() + 1.0,
            "budget_consumed_seconds": 42.0,
        }
        with pytest.raises(BudgetExceeded) as exc:
            guard(state, min_required=5.0)
        assert "budget exhausted" in str(exc.value).lower()
        assert "42.0" in str(exc.value)  # consumed value in message

    def test_guard_with_no_deadline_never_raises(self):
        guard({}, min_required=999.0)  # infinite budget


class TestTrack:
    @pytest.mark.asyncio
    async def test_tracks_elapsed_time_into_state(self):
        state = {"budget_consumed_seconds": 0.0}
        async with track(state, "test_node"):
            await _sleep(0.05)
        assert state["budget_consumed_seconds"] >= 0.05

    @pytest.mark.asyncio
    async def test_accumulates_across_multiple_calls(self):
        state = {"budget_consumed_seconds": 0.0}
        async with track(state, "n1"):
            await _sleep(0.02)
        async with track(state, "n2"):
            await _sleep(0.02)
        assert state["budget_consumed_seconds"] >= 0.04

    @pytest.mark.asyncio
    async def test_still_tracks_on_exception(self):
        state = {"budget_consumed_seconds": 0.0}
        with pytest.raises(RuntimeError):
            async with track(state, "fail"):
                await _sleep(0.02)
                raise RuntimeError("boom")
        # Elapsed should still be recorded even though the body raised
        assert state["budget_consumed_seconds"] >= 0.02


async def _sleep(seconds: float) -> None:
    """Tiny helper — tests use short waits (<100ms) to stay fast."""
    import asyncio

    await asyncio.sleep(seconds)
