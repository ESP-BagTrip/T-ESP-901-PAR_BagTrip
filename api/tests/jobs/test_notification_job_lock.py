"""Tests for the notification scheduler's distributed-lock guard (SMP327-026).

The scheduler body runs under ``async with redis_lock(...) as acquired:`` so a
multi-worker FastAPI deploy can't fire the same tick twice. These tests exercise
the three lock outcomes against the real `redis_lock` helper, using the
dict-backed `fake_redis` stub for the "acquired" / "busy" cases and a `None`
client for the Redis-unavailable fallback.

`notification_scheduler()` is an infinite loop; we let exactly one tick run by
patching `asyncio.sleep` to raise `CancelledError`, which the loop re-raises.
"""

from __future__ import annotations

import asyncio
from unittest.mock import patch

import pytest

import src.utils.distributed_lock as distributed_lock
from src.jobs.notification_job import notification_scheduler, run_notification_checks


async def _run_one_tick() -> None:
    """Drive `notification_scheduler` through a single iteration then stop it.

    The first `asyncio.sleep` (the inter-tick wait) raises `CancelledError`,
    which the scheduler's outer handler re-raises — so we swallow it here.
    """
    with (
        patch(
            "src.jobs.notification_job.asyncio.sleep",
            side_effect=asyncio.CancelledError,
        ),
        pytest.raises(asyncio.CancelledError),
    ):
        await notification_scheduler()


class TestSchedulerLock:
    @pytest.mark.asyncio
    async def test_lock_acquired_runs_checks(self, fake_redis):
        """Free lock -> the tick body executes the notification checks once."""
        with (
            patch.object(distributed_lock, "get_redis_client", return_value=fake_redis),
            patch(
                "src.jobs.notification_job.run_notification_checks",
                return_value={"departure_reminders": 0},
            ) as mock_checks,
        ):
            await _run_one_tick()

        mock_checks.assert_called_once()
        # Lock must be released after the tick — the next worker can re-acquire.
        assert fake_redis.get("lock:job:notification") is None

    @pytest.mark.asyncio
    async def test_lock_busy_skips_checks(self, fake_redis):
        """Lock already held by a peer worker -> checks must NOT run (no dupes)."""
        # Simulate a peer worker that grabbed the lock first.
        fake_redis.set("lock:job:notification", "peer-token", nx=True, ex=3600)

        with (
            patch.object(distributed_lock, "get_redis_client", return_value=fake_redis),
            patch("src.jobs.notification_job.run_notification_checks") as mock_checks,
        ):
            await _run_one_tick()

        mock_checks.assert_not_called()
        # The peer's lock is untouched (our worker must not release a lock it
        # never owned — Lua CAS guarantees this).
        assert fake_redis.get("lock:job:notification") == "peer-token"

    @pytest.mark.asyncio
    async def test_redis_unavailable_falls_back_to_running(self):
        """No Redis -> degrade to "acquired" so the mono-worker dev flow keeps working."""
        # Reset the once-per-name warn dedup so the fallback path is exercised
        # deterministically regardless of test ordering.
        distributed_lock._warned_fallback.discard("job:notification")

        with (
            patch.object(distributed_lock, "get_redis_client", return_value=None),
            patch(
                "src.jobs.notification_job.run_notification_checks",
                return_value={"flight_h1": 1},
            ) as mock_checks,
        ):
            await _run_one_tick()

        mock_checks.assert_called_once()

    @pytest.mark.asyncio
    async def test_checks_exception_does_not_break_loop_or_lock(self, fake_redis):
        """A crash inside the checks is swallowed; the lock is still released."""
        with (
            patch.object(distributed_lock, "get_redis_client", return_value=fake_redis),
            patch(
                "src.jobs.notification_job.run_notification_checks",
                side_effect=RuntimeError("boom"),
            ) as mock_checks,
        ):
            await _run_one_tick()

        mock_checks.assert_called_once()
        # Even though the body raised, the lock context manager released it.
        assert fake_redis.get("lock:job:notification") is None


class TestRunNotificationChecks:
    def test_aggregates_all_check_results(self):
        """`run_notification_checks` returns the per-check counts and closes the session."""
        with (
            patch("src.jobs.notification_job.SessionLocal") as mock_session_local,
            patch("src.jobs.notification_job._check_departure_reminders", return_value=1) as m_dep,
            patch("src.jobs.notification_job._check_flight_alerts", side_effect=[2, 3]) as m_flight,
            patch("src.jobs.notification_job._check_morning_summary", return_value=4) as m_morn,
            patch("src.jobs.notification_job._check_activity_reminders", return_value=5) as m_act,
            patch(
                "src.jobs.notification_job.NotificationService.retry_unsent",
                return_value=6,
            ) as m_retry,
        ):
            mock_db = mock_session_local.return_value = type(
                "S", (), {"close": lambda self: None}
            )()
            mock_session_local.return_value = mock_db

            results = run_notification_checks()

        assert results == {
            "departure_reminders": 1,
            "flight_h4": 2,
            "flight_h1": 3,
            "morning_summary": 4,
            "activity_h1": 5,
            "retried_unsent": 6,
        }
        m_dep.assert_called_once()
        assert m_flight.call_count == 2
        m_morn.assert_called_once()
        m_act.assert_called_once()
        m_retry.assert_called_once()

    def test_session_closed_even_on_error(self):
        """The DB session is closed in `finally` even when a check raises."""
        closed = {"v": False}

        class _Sess:
            def close(self) -> None:
                closed["v"] = True

        with (
            patch("src.jobs.notification_job.SessionLocal", return_value=_Sess()),
            patch(
                "src.jobs.notification_job._check_departure_reminders",
                side_effect=RuntimeError("db down"),
            ),
            pytest.raises(RuntimeError),
        ):
            run_notification_checks()

        assert closed["v"] is True
