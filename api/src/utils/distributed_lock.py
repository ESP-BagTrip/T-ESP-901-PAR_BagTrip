"""Distributed lock on Redis with a best-effort in-process fallback.

Scheduler jobs (`notification_job`, `trip_status_job`) run once per FastAPI
worker via `asyncio.create_task()` in the lifespan. In a multi-worker deploy
(`uvicorn --workers N`) that means N copies of the same tick fire at the same
time, and the current `_already_sent()` window check is a TOCTOU race.

`redis_lock` wraps the body of a tick in an atomic `SET NX EX` so only one
worker across the fleet executes it. The lock is released via Lua CAS (check
that the token matches before deleting) so a slow worker can't release a lock
its successor is already holding — the classic "lock expired on worker A
while worker B was already working" foot-gun.

Fallback policy
---------------
Per the Sprint 3 plan, if Redis is unavailable we **do NOT** block the job
from running. That keeps the mono-worker dev experience (no Redis required)
but tolerates one edge case: if you deploy with `--workers 2` WITHOUT Redis
you still get duplicates. We emit a WARN log on first fallback so this shows
up in prod monitoring.
"""

from __future__ import annotations

import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from src.integrations.redis_client import get_redis_client
from src.utils.logger import logger

# Lua CAS release script — atomic "delete iff value matches".
# Parameters: KEYS[1]=lock key, ARGV[1]=token to match.
_RELEASE_SCRIPT = """
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
"""

_warned_fallback: set[str] = set()


@asynccontextmanager
async def redis_lock(
    name: str,
    ttl_seconds: int,
    *,
    blocking: bool = False,
) -> AsyncIterator[bool]:
    """Acquire a named lock on Redis for at most `ttl_seconds`.

    Args:
        name: Logical lock name. The final Redis key is `lock:{name}`.
        ttl_seconds: Lock expiry — must exceed the expected runtime of the
            protected body by a comfortable margin (a sensible default is
            `max(runtime_estimate * 2, 2 * job_interval)`).
        blocking: Not implemented — always False. We only support try-acquire;
            a blocking variant would add complexity (retry loop, jitter) that
            the scheduler use case doesn't need.

    Yields:
        `True` if the lock was acquired (including fallback mode where no
        Redis is available), `False` if another worker already holds it.

    Example:
        async with redis_lock("job:notification", ttl_seconds=3600) as acquired:
            if not acquired:
                return
            # ... body — guaranteed single-worker execution
    """
    if blocking:
        raise NotImplementedError("blocking redis_lock not supported in Sprint 3")

    client = get_redis_client()
    key = f"lock:{name}"
    token = uuid.uuid4().hex

    if client is None:
        # Best-effort fallback — no Redis available. Yield True and warn once
        # per lock name so the log doesn't flood the scheduler output.
        if name not in _warned_fallback:
            logger.warn(
                "redis_lock: Redis unavailable, running WITHOUT distributed "
                f"lock for '{name}'. Multi-worker deployments may duplicate work.",
            )
            _warned_fallback.add(name)
        yield True
        return

    acquired = bool(client.set(key, token, nx=True, ex=ttl_seconds))
    try:
        yield acquired
    finally:
        if acquired:
            try:
                client.eval(_RELEASE_SCRIPT, 1, key, token)
            except Exception as exc:
                # Worst case: the TTL expires naturally — the lock is never
                # "stuck" forever. Log so operators can notice a broken Redis.
                logger.warn(
                    f"redis_lock: release script failed for '{name}' "
                    f"({type(exc).__name__}: {exc}); lock will expire on TTL",
                )
