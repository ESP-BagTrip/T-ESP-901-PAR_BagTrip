"""Unit tests for `redis_lock`.

Covers:
- Happy path — acquire, run body, release via Lua CAS
- Contended path — second acquirer sees False and skips the body
- Release script failure is logged but does not raise
- Fallback when Redis is unavailable yields True and runs the body
- `blocking=True` raises `NotImplementedError`
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from src.utils.distributed_lock import redis_lock


class TestRedisLockAcquisition:
    @pytest.mark.asyncio
    async def test_happy_path_acquires_and_releases(self, fake_redis):
        # fake_redis.set() with nx returns True on first acquire
        with patch("src.utils.distributed_lock.get_redis_client", return_value=fake_redis):
            executed = False
            async with redis_lock("job:test", ttl_seconds=60) as acquired:
                assert acquired is True
                executed = True
                # Lock key is stored
                assert fake_redis.get("lock:job:test") is not None
            # After exit, the Lua CAS deletes the key
            assert fake_redis.get("lock:job:test") is None
            assert executed

    @pytest.mark.asyncio
    async def test_contended_lock_returns_false(self, fake_redis):
        """Second worker sees False while the first worker still holds the lock."""
        with patch("src.utils.distributed_lock.get_redis_client", return_value=fake_redis):
            async with redis_lock("job:contended", ttl_seconds=60) as first:
                assert first is True
                async with redis_lock("job:contended", ttl_seconds=60) as second:
                    assert second is False

    @pytest.mark.asyncio
    async def test_different_lock_names_do_not_collide(self, fake_redis):
        with patch("src.utils.distributed_lock.get_redis_client", return_value=fake_redis):
            async with redis_lock("job:a", ttl_seconds=60) as a:
                async with redis_lock("job:b", ttl_seconds=60) as b:
                    assert a is True
                    assert b is True


class TestRedisLockReleaseFailure:
    @pytest.mark.asyncio
    async def test_release_failure_is_swallowed(self, fake_redis):
        """A broken `eval` during release should not propagate to the caller."""
        broken = MagicMock(wraps=fake_redis)
        broken.set = fake_redis.set
        broken.eval.side_effect = RuntimeError("lua died")
        with patch("src.utils.distributed_lock.get_redis_client", return_value=broken):
            async with redis_lock("job:broken", ttl_seconds=60) as acquired:
                assert acquired is True
            # Release failed but the context manager exited cleanly
            broken.eval.assert_called_once()


class TestRedisLockFallback:
    @pytest.mark.asyncio
    async def test_fallback_when_redis_unavailable(self):
        """Without Redis, the lock yields True and runs the body (best-effort)."""
        # Clear the warning cache so we actually hit the warn branch
        from src.utils import distributed_lock as module

        module._warned_fallback.clear()
        with patch("src.utils.distributed_lock.get_redis_client", return_value=None):
            executed = False
            async with redis_lock("job:nolock", ttl_seconds=60) as acquired:
                assert acquired is True
                executed = True
            assert executed
            # The fallback should have been flagged in the warned set
            assert "job:nolock" in module._warned_fallback

    @pytest.mark.asyncio
    async def test_fallback_warns_once_per_lock_name(self):
        from src.utils import distributed_lock as module

        module._warned_fallback.clear()
        with (
            patch("src.utils.distributed_lock.get_redis_client", return_value=None),
            patch("src.utils.distributed_lock.logger.warn") as mock_warn,
        ):
            async with redis_lock("job:once", ttl_seconds=60):
                pass
            async with redis_lock("job:once", ttl_seconds=60):
                pass
            # Only one warning emitted despite two entries
            assert mock_warn.call_count == 1


class TestRedisLockArguments:
    @pytest.mark.asyncio
    async def test_blocking_raises_not_implemented(self):
        with pytest.raises(NotImplementedError):
            async with redis_lock("x", ttl_seconds=60, blocking=True):
                pass  # pragma: no cover — never reached
