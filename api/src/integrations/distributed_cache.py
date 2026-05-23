"""Small distributed key/value cache for slow external integrations.

Several integration clients (Unsplash covers, AirLabs flight lookups, ...) used
to keep their own per-process ``dict`` cache. In a multi-worker deployment that
means every worker re-hits the upstream provider for the same key, burning
quota and latency.

This helper centralises the pattern: it uses the **shared** Redis client
(``get_redis_client()`` — same connection pool as the rate limiter, idempotency
cache and distributed lock) and falls back to a per-process ``TTLCache`` when
Redis is unavailable. Values are JSON-serialised, so callers can store strings
or plain dicts transparently.

Usage::

    _cache = DistributedCache("unsplash", ttl_seconds=3600)
    hit = _cache.get(key)
    if hit is None:
        hit = expensive_lookup()
        _cache.set(key, hit)
"""

from __future__ import annotations

import json
from typing import Any

from cachetools import TTLCache

from src.integrations.redis_client import get_redis_client
from src.utils.logger import logger


class DistributedCache:
    """JSON cache backed by shared Redis with an in-process TTL fallback."""

    def __init__(self, namespace: str, ttl_seconds: int, max_memory_items: int = 1000):
        self._ns = namespace
        self._ttl = ttl_seconds
        self._memory: TTLCache = TTLCache(maxsize=max_memory_items, ttl=ttl_seconds)

    def _key(self, key: str) -> str:
        return f"cache:{self._ns}:{key}"

    def get(self, key: str) -> Any | None:
        """Return the cached value (JSON-decoded) or ``None`` on miss."""
        redis_key = self._key(key)
        client = get_redis_client()
        if client is not None:
            try:
                raw = client.get(redis_key)
                if raw is not None:
                    return json.loads(raw)
                return None
            except Exception as exc:
                logger.warn(f"DistributedCache[{self._ns}] Redis GET failed, using memory: {exc}")
        return self._memory.get(key)

    def set(self, key: str, value: Any) -> None:
        """Store ``value`` (JSON-serialisable) under ``key`` with the namespace TTL."""
        redis_key = self._key(key)
        client = get_redis_client()
        if client is not None:
            try:
                client.setex(redis_key, self._ttl, json.dumps(value, default=str))
                return
            except Exception as exc:
                logger.warn(f"DistributedCache[{self._ns}] Redis SET failed, using memory: {exc}")
        self._memory[key] = value

    def clear(self) -> None:
        """Drop every entry in this namespace (in-memory + Redis). Mainly for tests."""
        self._memory.clear()
        client = get_redis_client()
        if client is not None:
            try:
                for redis_key in client.scan_iter(f"cache:{self._ns}:*"):
                    client.delete(redis_key)
            except Exception as exc:
                logger.warn(f"DistributedCache[{self._ns}] Redis clear failed: {exc}")
