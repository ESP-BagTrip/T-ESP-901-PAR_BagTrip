"""Shared Redis client factory.

Three pieces of the backend currently want Redis:
- `src/middleware/rate_limit.py` — token-bucket / sliding-window counters
- `src/utils/idempotency.py` — agent tool result cache
- `src/utils/distributed_lock.py` — scheduler singleton enforcement (Sprint 3)

Before this module, each of those did its own lazy import + `from_url` +
`ping` + fallback logic. That's three places to change every time we touch
Redis concerns (connection pooling, SSL, auth) and three drift opportunities.

This module is the **single entry point**. Callers do:

    from src.integrations.redis_client import get_redis_client

    client = get_redis_client()
    if client is None:
        # REDIS_URL not configured or Redis unreachable — fall back to in-process
        ...

The return type is intentionally `Any | None` because `redis` is an optional
dependency in dev and we don't want a hard import on module load.

Caching
-------
The client is memoised for the lifetime of the process. We NEVER call
`ping()` more than once per process — the first `get_redis_client()` call does
the connectivity probe and caches the result (`None` if Redis is down). If you
need to force a reconnect (tests, failover), call `reset_redis_client()`.
"""

from __future__ import annotations

from typing import Any

from src.config.env import settings
from src.utils.logger import logger

_client: Any | None = None
_initialized: bool = False


def get_redis_client() -> Any | None:
    """Return the shared Redis client, or `None` if Redis is unavailable.

    The first call does a lazy import + `from_url` + `ping`. Subsequent calls
    are free — the result (including `None` for unavailable) is memoised.
    """
    global _client, _initialized

    if _initialized:
        return _client

    _initialized = True

    if not settings.REDIS_URL:
        logger.info("redis_client: REDIS_URL not set, using in-memory fallbacks")
        return None

    try:
        import redis as redis_lib  # local import keeps `redis` optional
    except ImportError:
        logger.warn("redis_client: `redis` package not installed, falling back to in-memory")
        return None

    try:
        client = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)
        client.ping()
    except Exception as exc:
        logger.warn(f"redis_client: connection failed ({exc}), falling back to in-memory")
        return None

    _client = client
    logger.info("redis_client: connected")
    return _client


def reset_redis_client() -> None:
    """Forget the cached client — only useful for tests and manual failover."""
    global _client, _initialized
    _client = None
    _initialized = False
