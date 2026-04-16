"""Rate limiting middleware — Redis-backed with in-memory fallback.

Rate limits must survive across multi-worker deployments, so the counters live
in Redis when `REDIS_URL` is configured. In dev (no Redis) we fall back to the
original in-memory `cachetools.TTLCache` / list-per-user store so local work
keeps functioning with the same semantics, just per-process.

## The two limiters

- **AI rate limiter** (`ai_rate_limiter`) — per-user, protects the agent chat /
  suggestion endpoints from abuse. Sliding window (~60 s).
- **Auth rate limiter** — per-IP, protects signup/login/refresh from credential
  stuffing. Fixed window (60 s).

Both use the same `_CounterStore` abstraction so the Redis/in-memory switch is
transparent to callers.
"""

from __future__ import annotations

from collections import defaultdict
from typing import Any

from cachetools import TTLCache
from fastapi import Request
from fastapi.responses import JSONResponse

from src.api.auth.middleware import verify_jwt_token
from src.utils.logger import logger


class _CounterStore:
    """Unified counter API — increment a key and return the new value.

    Redis implementation uses an atomic INCR+EXPIRE so the window is
    consistent across workers. In-memory falls back to a per-process map.
    """

    def __init__(self, window_seconds: int, redis_client: Any | None = None):
        self._window = window_seconds
        self._redis = redis_client
        # In-memory fallback: TTLCache gives us automatic expiry at the window
        # boundary without a background sweep thread.
        self._memory: TTLCache = TTLCache(maxsize=10000, ttl=window_seconds)

    def incr(self, key: str) -> int:
        """Bump the counter for `key` and return its new value."""
        if self._redis is not None:
            try:
                pipe = self._redis.pipeline()
                pipe.incr(key)
                pipe.expire(key, self._window)
                count, _ = pipe.execute()
                return int(count)
            except Exception as exc:
                logger.warn(f"Rate limiter: Redis INCR failed, using memory: {exc}")

        current = self._memory.get(key, 0) + 1
        self._memory[key] = current
        return current

    def get(self, key: str) -> int:
        """Return the current counter value for `key`."""
        if self._redis is not None:
            try:
                raw = self._redis.get(key)
                return int(raw) if raw is not None else 0
            except Exception:
                pass
        return int(self._memory.get(key, 0))

    def ttl(self, key: str) -> int:
        """Return how many seconds remain before `key` expires."""
        if self._redis is not None:
            try:
                ttl = self._redis.ttl(key)
                if ttl is not None and ttl > 0:
                    return int(ttl)
            except Exception:
                pass
        # Memory cache can't give us a precise TTL — return the full window.
        return self._window


def _build_redis_client() -> Any | None:
    """Return a configured redis client or None if Redis isn't available."""
    from src.config.env import settings

    if not settings.REDIS_URL:
        logger.info("Rate limiter using in-memory backend (REDIS_URL not set)")
        return None
    try:
        import redis as redis_lib

        client = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)
        client.ping()
        logger.info("Rate limiter using Redis backend")
        return client
    except Exception as exc:
        logger.warn(f"Rate limiter: Redis unavailable, falling back to memory: {exc}")
        return None


_redis_client = _build_redis_client()


class RateLimiter:
    """Per-key rate limiter backed by `_CounterStore`."""

    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._store = _CounterStore(window_seconds, redis_client=_redis_client)
        # Legacy per-process sliding window — kept only for the `is_allowed`
        # signature consumers still expect in tests. Not used when Redis is on.
        self._legacy_requests: dict[str, list] = defaultdict(list)

    def is_allowed(self, user_id: str) -> tuple[bool, int]:
        """Check + increment. Returns (allowed, remaining_requests)."""
        key = f"rl:{user_id}"
        # Tentative increment first — if it puts us over the limit, decrement is
        # not possible atomically but the overage is at most one request per
        # worker per window, which is acceptable.
        count = self._store.incr(key)
        if count > self.max_requests:
            return False, 0
        return True, max(0, self.max_requests - count)

    def get_retry_after(self, user_id: str) -> int:
        """Return how many seconds before the window resets for `user_id`."""
        return self._store.ttl(f"rl:{user_id}")


# Rate limiter pour les endpoints agent chat (10 / min)
agent_chat_rate_limiter = RateLimiter(max_requests=10, window_seconds=60)

# Rate limiter pour les endpoints IA (5 / min)
ai_rate_limiter = RateLimiter(max_requests=5, window_seconds=60)

# Auth rate limiter: per-IP, 5 / min, backed by the same store.
_AUTH_RATE_LIMIT_MAX = 5
_AUTH_RATE_LIMIT_WINDOW = 60
_auth_store = _CounterStore(_AUTH_RATE_LIMIT_WINDOW, redis_client=_redis_client)

_AUTH_RATE_LIMITED_PATHS = {
    "/v1/auth/login",
    "/v1/auth/register",
    "/v1/auth/google",
    "/v1/auth/apple",
    "/v1/auth/refresh",
}


def _get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


async def auth_rate_limit_middleware(request: Request, call_next):
    """Per-IP rate limiting for auth endpoints."""
    if request.method == "POST" and request.url.path in _AUTH_RATE_LIMITED_PATHS:
        ip = _get_client_ip(request)
        key = f"auth:{ip}"
        count = _auth_store.incr(key)
        if count > _AUTH_RATE_LIMIT_MAX:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": "Too many requests. Please try again later.",
                    "retry_after": _AUTH_RATE_LIMIT_WINDOW,
                },
                headers={"Retry-After": str(_AUTH_RATE_LIMIT_WINDOW)},
            )

    return await call_next(request)


async def rate_limit_middleware(request: Request, call_next):
    """Middleware pour appliquer le rate limiting sur les endpoints IA."""
    ai_rate_limited = (
        request.url.path.endswith("/agent/chat")
        or "/v1/ai/" in request.url.path
        or "/suggest" in request.url.path
    )
    if ai_rate_limited and request.method == "POST":
        auth_header = request.headers.get("Authorization")
        user_id = None

        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
            user_id = verify_jwt_token(token)
        else:
            cookie_token = request.cookies.get("access_token")
            if cookie_token:
                user_id = verify_jwt_token(cookie_token)

        if user_id:
            is_allowed, remaining = ai_rate_limiter.is_allowed(user_id)

            if not is_allowed:
                retry_after = ai_rate_limiter.get_retry_after(user_id)
                return JSONResponse(
                    status_code=429,
                    content={
                        "detail": "Rate limit exceeded. Please try again later.",
                        "retry_after": retry_after,
                    },
                    headers={"Retry-After": str(retry_after)},
                )

            response = await call_next(request)
            response.headers["X-RateLimit-Remaining"] = str(remaining)
            response.headers["X-RateLimit-Limit"] = str(ai_rate_limiter.max_requests)
            return response

    return await call_next(request)
