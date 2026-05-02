"""Tests for the periodic ECB currency refresh job (topic 04b phase 3)."""

from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from unittest.mock import AsyncMock, patch

import pytest

from src.jobs import currency_refresh_job


@asynccontextmanager
async def _fake_lock(_name: str, *, ttl_seconds: int = 0, acquired: bool = True):
    yield acquired


@pytest.mark.asyncio
async def test_refresh_with_lock_invokes_service_when_acquired():
    refresh = AsyncMock(return_value=33)
    with (
        patch.object(currency_refresh_job, "redis_lock", _fake_lock),
        patch.object(currency_refresh_job, "refresh_rates_async", refresh),
    ):
        await currency_refresh_job._refresh_with_lock()

    refresh.assert_awaited_once()


@pytest.mark.asyncio
async def test_refresh_with_lock_skips_when_not_acquired():
    refresh = AsyncMock(return_value=0)

    @asynccontextmanager
    async def denied_lock(_name: str, *, ttl_seconds: int = 0):
        yield False

    with (
        patch.object(currency_refresh_job, "redis_lock", denied_lock),
        patch.object(currency_refresh_job, "refresh_rates_async", refresh),
    ):
        await currency_refresh_job._refresh_with_lock()

    refresh.assert_not_awaited()


@pytest.mark.asyncio
async def test_scheduler_runs_first_tick_immediately():
    """Boot tick must warm the cache before the first 12h sleep loop."""
    refresh_calls = 0

    async def fake_refresh():
        nonlocal refresh_calls
        refresh_calls += 1
        return 0

    sleep_called = asyncio.Event()

    async def fake_sleep(_):
        # Mark that we reached the first sleep, then bail out so the
        # test can finish deterministically. Raising CancelledError is
        # the loop's contract for shutdown.
        sleep_called.set()
        raise asyncio.CancelledError

    with (
        patch.object(currency_refresh_job, "redis_lock", _fake_lock),
        patch.object(currency_refresh_job, "refresh_rates_async", fake_refresh),
        patch.object(currency_refresh_job.asyncio, "sleep", fake_sleep),
    ):
        with pytest.raises(asyncio.CancelledError):
            await currency_refresh_job.currency_refresh_scheduler()

    # First tick fired before the sleep.
    assert refresh_calls == 1
    assert sleep_called.is_set()
