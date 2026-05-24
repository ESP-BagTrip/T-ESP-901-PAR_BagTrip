"""Per-account login lockout.

The existing rate limiter is **per-IP** (``src/middleware/rate_limit.py``), so an
attacker with a pool of IPs can still brute-force a single account. This service
adds a **per-email** failure counter on top: after ``MAX_FAILURES`` failed logins
inside ``WINDOW_SECONDS`` the account is temporarily locked regardless of source
IP. A successful login clears the counter.

It reuses the shared ``_CounterStore`` (Redis-backed, in-memory fallback) rather
than rolling its own counter. When Redis is unavailable the in-memory store is
per-worker, which weakens the guarantee — that is an accepted, documented
trade-off: this is defense-in-depth layered on the per-IP limiter, not the sole
control. The lockout therefore fails *open* (never blocks a legitimate user just
because Redis is down).

The Redis key is keyed on ``sha256(email)`` so a Redis dump never leaks the set
of email addresses that have been attacked.
"""

from __future__ import annotations

import hashlib

from src.middleware.rate_limit import _CounterStore, _redis_client

MAX_FAILURES = 10
WINDOW_SECONDS = 15 * 60


class AuthLockoutService:
    """Tracks failed login attempts per email and enforces a temporary lockout."""

    _store = _CounterStore(WINDOW_SECONDS, redis_client=_redis_client)

    @staticmethod
    def _key(email: str) -> str:
        digest = hashlib.sha256(email.strip().lower().encode("utf-8")).hexdigest()
        return f"login_fail:{digest}"

    @classmethod
    def is_locked(cls, email: str) -> tuple[bool, int]:
        """Return ``(locked, retry_after_seconds)`` for the given email."""
        count = cls._store.get(cls._key(email))
        if count >= MAX_FAILURES:
            return True, cls._store.ttl(cls._key(email))
        return False, 0

    @classmethod
    def record_failure(cls, email: str) -> int:
        """Increment the failure counter; returns the new count."""
        return cls._store.incr(cls._key(email))

    @classmethod
    def reset(cls, email: str) -> None:
        """Clear the failure counter after a successful login."""
        key = cls._key(email)
        if cls._store._redis is not None:
            try:
                cls._store._redis.delete(key)
                return
            except Exception:
                pass
        cls._store._memory.pop(key, None)
