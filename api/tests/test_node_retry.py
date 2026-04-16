"""Tests for Phase 5 (API-4): retry logic, degradation."""

import asyncio
from unittest.mock import patch

import pytest

from src.agent.retry import _NODE_FIELD_MAP, with_retry


@pytest.mark.asyncio
async def test_success_on_first_attempt():
    async def ok_node(state):
        return {"activities": [{"title": "Hiking"}]}

    result = await with_retry(ok_node, {}, "activity_planner")
    assert result["activities"] == [{"title": "Hiking"}]


@pytest.mark.asyncio
async def test_failure_then_success_on_retry():
    call_count = 0

    async def flaky_node(state):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise RuntimeError("Temporary failure")
        return {"accommodations": [{"name": "Hotel Test"}]}

    result = await with_retry(flaky_node, {}, "accommodation")
    assert call_count == 2
    assert result["accommodations"] == [{"name": "Hotel Test"}]


@pytest.mark.asyncio
async def test_total_failure_returns_degraded_result():
    async def always_fails(state):
        raise RuntimeError("Permanent failure")

    result = await with_retry(always_fails, {}, "activity_planner")

    # Should return empty list for the mapped field
    assert result["activities"] == []
    # Should include warning event
    assert len(result["events"]) == 1
    assert result["events"][0]["event"] == "warning"
    assert result["events"][0]["data"]["section"] == "activity_planner"
    # Should include error message
    assert len(result["errors"]) == 1
    assert "activity_planner failed" in result["errors"][0]


@pytest.mark.asyncio
async def test_total_failure_unknown_node_uses_name_as_field():
    async def always_fails(state):
        raise RuntimeError("fail")

    result = await with_retry(always_fails, {}, "unknown_node")
    assert result["unknown_node"] == []


def test_node_field_map_covers_parallel_nodes():
    assert "activity_planner" in _NODE_FIELD_MAP
    assert "accommodation" in _NODE_FIELD_MAP
    assert "baggage" in _NODE_FIELD_MAP
    assert _NODE_FIELD_MAP["activity_planner"] == "activities"
    assert _NODE_FIELD_MAP["accommodation"] == "accommodations"
    assert _NODE_FIELD_MAP["baggage"] == "baggage_items"


@pytest.mark.asyncio
async def test_max_retries_custom():
    call_count = 0

    async def fails_twice(state):
        nonlocal call_count
        call_count += 1
        if call_count <= 2:
            raise RuntimeError("fail")
        return {"activities": []}

    result = await with_retry(fails_twice, {}, "activity_planner", max_retries=2)
    assert call_count == 3
    assert result["activities"] == []


# ---------------------------------------------------------------------------
# Timeout tests (asyncio.wait_for wrapping)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_timeout_triggers_retry():
    """A node that exceeds NODE_TIMEOUT_SECONDS is treated as a failure and retried."""
    call_count = 0

    async def slow_then_fast(state):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            await asyncio.sleep(999)  # Will be interrupted by timeout
        return {"activities": [{"title": "Recovered"}]}

    with patch("src.agent.retry.settings") as mock_settings:
        mock_settings.NODE_TIMEOUT_SECONDS = 0.1  # Very short timeout
        result = await with_retry(slow_then_fast, {}, "activity_planner")

    assert call_count == 2
    assert result["activities"] == [{"title": "Recovered"}]


@pytest.mark.asyncio
async def test_timeout_all_attempts_returns_degraded():
    """If all attempts timeout, returns degraded result."""

    async def always_slow(state):
        await asyncio.sleep(999)

    with patch("src.agent.retry.settings") as mock_settings:
        mock_settings.NODE_TIMEOUT_SECONDS = 0.1
        result = await with_retry(always_slow, {}, "activity_planner", max_retries=1)

    assert result["activities"] == []
    assert len(result["errors"]) == 1
    assert "activity_planner failed" in result["errors"][0]
