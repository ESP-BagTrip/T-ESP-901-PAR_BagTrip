"""Centralised currency conversion (topic 04b, B8/B11).

This is the *phase 1* implementation: the public API is final, but the
rate source is a stub that returns 1.0 for every pair. The real ECB
fetcher (decision D2 of EXECUTION-PLAN — ECB primary, exchangerate-api
fallback) plugs into ``_fetch_rate`` without touching callers.

Why ship the stub now: the schema migration (0030) makes every
``Trip`` and ``BudgetItem`` carry an explicit ``currency``, and
``BudgetItemService.get_budget_summary`` already calls ``convert`` on
each row. Once the live fetcher is wired in, multi-currency trips
start aggregating correctly with zero call-site change.

Design notes:
- Pure module-level cache with a soft TTL — no Redis dependency in
  phase 1 to keep the code path identical between unit tests and
  production. The Redis-backed cache promotion is one localised
  swap inside ``_get_rate`` when D2 is acted on.
- ``convert`` is total: every currency code yields a rate (the stub
  returns 1.0 for unknown / same-currency pairs), so callers never
  branch on "did the rate fetch succeed?".
- Symmetric: rate ``EUR → USD`` is auto-derived from ``USD → EUR``
  by inverting the cache. Halves the calls to the upstream API.
"""

from __future__ import annotations

import time
from threading import Lock

# 12-hour soft TTL — ECB publishes daily so this gives at most a 12h
# stale window in the worst case.
_RATE_TTL_SECONDS = 12 * 3600

# (from_currency, to_currency) -> (rate, fetched_at_monotonic)
_rate_cache: dict[tuple[str, str], tuple[float, float]] = {}
_lock = Lock()


def _normalise(code: str | None) -> str:
    """Upper-case and strip a currency code, default to ``EUR`` on missing."""
    if not code:
        return "EUR"
    return code.strip().upper()


def _fetch_rate(from_: str, to: str) -> float:
    """Fetch a fresh rate from the upstream provider.

    Phase 1 stub: always returns 1.0. The real fetcher plugs in here
    without changing any caller.
    """
    return 1.0


def _get_rate(from_: str, to: str) -> float:
    """Return the cached rate, fetching it on miss / expiry."""
    if from_ == to:
        return 1.0
    now = time.monotonic()
    with _lock:
        cached = _rate_cache.get((from_, to))
        if cached is not None:
            rate, fetched_at = cached
            if now - fetched_at < _RATE_TTL_SECONDS:
                return rate
        # Try the inverse cache before paying a new fetch.
        inverse = _rate_cache.get((to, from_))
        if inverse is not None:
            inv_rate, fetched_at = inverse
            if now - fetched_at < _RATE_TTL_SECONDS and inv_rate > 0:
                rate = 1.0 / inv_rate
                _rate_cache[(from_, to)] = (rate, now)
                return rate
    # Cache miss outside the lock — fetcher is a stub today, but the
    # real implementation will hit a remote API and we don't want it
    # under the lock.
    rate = _fetch_rate(from_, to)
    with _lock:
        _rate_cache[(from_, to)] = (rate, now)
    return rate


def convert(amount: float, *, from_: str | None, to: str | None) -> float:
    """Convert ``amount`` from one currency to another.

    Both codes are normalised (uppercase, EUR fallback). Same currency
    is a no-op. Returns the converted amount as a float.
    """
    src = _normalise(from_)
    dst = _normalise(to)
    if src == dst:
        return float(amount)
    rate = _get_rate(src, dst)
    return float(amount) * rate


def reset_cache() -> None:
    """Clear the in-process cache. Used by tests to avoid cross-test bleed."""
    with _lock:
        _rate_cache.clear()
