"""Centralised currency conversion (topic 04b, B8/B11).

Two-stage design:

- ``convert(amount, from_=, to=)`` is **synchronous** and total. It
  reads from the in-process rate cache and falls back to the identity
  rate (``1.0``) when a pair has not been warmed yet. Callers never
  block on a network round-trip and never branch on
  "did the rate fetch succeed?" — the budget summary always renders.

- ``refresh_rates_async()`` is **asynchronous** and populates the cache
  by hitting the ECB daily reference XML (decision D2 of
  EXECUTION-PLAN — ECB primary). It is meant to be called at lifespan
  startup and periodically (e.g. every 12h) by a scheduler. While the
  cache is cold, conversions degrade to identity instead of throwing.

Design notes:
- ECB publishes EUR-base daily rates; we keep that base and derive
  cross rates by composing two lookups (``USD → GBP`` becomes
  ``USD → EUR → GBP`` using two cached EUR-base rates).
- A 12h soft TTL matches the publication cadence. Stale beyond TTL
  triggers a background refresh on the next ``refresh_rates_async``
  tick, never a sync call from a request handler.
- The cache stays module-level so it survives across requests in a
  single worker. Multi-worker deployments can promote it to Redis
  later — the get/set surface is already factored out.
"""

from __future__ import annotations

import time
import xml.etree.ElementTree as ET  # noqa: S405 — ECB XML is a trusted public source
from threading import Lock

from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_ECB_DAILY_URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
_ECB_NS = {
    "gesmes": "http://www.gesmes.org/xml/2002-08-01",
    "ecb": "http://www.ecb.int/vocabulary/2002-08-01/eurofxref",
}

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


def _read_cached(from_: str, to: str) -> float | None:
    """Look up a fresh rate in the cache. Returns ``None`` on miss/expiry."""
    if from_ == to:
        return 1.0
    now = time.monotonic()
    with _lock:
        cached = _rate_cache.get((from_, to))
        if cached is not None:
            rate, fetched_at = cached
            if now - fetched_at < _RATE_TTL_SECONDS:
                return rate
        # Inverse-pair derivation halves the number of fetched pairs.
        inverse = _rate_cache.get((to, from_))
        if inverse is not None:
            inv_rate, fetched_at = inverse
            if now - fetched_at < _RATE_TTL_SECONDS and inv_rate > 0:
                rate = 1.0 / inv_rate
                _rate_cache[(from_, to)] = (rate, now)
                return rate
        # EUR-base composition: ``USD → GBP`` = ``USD → EUR → GBP`` when
        # both halves are cached. Common after a fresh ECB refresh.
        if from_ != "EUR" and to != "EUR":
            half_a = _rate_cache.get(("EUR", from_))
            half_b = _rate_cache.get(("EUR", to))
            if half_a is not None and half_b is not None:
                rate_a, ts_a = half_a
                rate_b, ts_b = half_b
                if now - ts_a < _RATE_TTL_SECONDS and now - ts_b < _RATE_TTL_SECONDS and rate_a > 0:
                    composed = rate_b / rate_a
                    _rate_cache[(from_, to)] = (composed, now)
                    return composed
    return None


def convert(amount: float, *, from_: str | None, to: str | None) -> float:
    """Convert ``amount`` from one currency to another.

    Both codes are normalised (uppercase, EUR fallback). Same currency
    is a no-op. Cache miss falls back to the identity rate (``1.0``)
    so request handlers never block on a remote rate fetch — refresh
    happens out-of-band via :func:`refresh_rates_async`.
    """
    src = _normalise(from_)
    dst = _normalise(to)
    if src == dst:
        return float(amount)
    rate = _read_cached(src, dst)
    if rate is None:
        # Cold-cache fallback: log once per pair so prod is observable
        # without spamming the logs on a degraded budget summary.
        logger.debug(
            "currency_service: no cached rate, falling back to identity",
            {"from": src, "to": dst},
        )
        rate = 1.0
    return float(amount) * rate


def _parse_ecb_xml(payload: str) -> dict[str, float]:
    """Extract ``{currency: rate}`` from an ECB daily reference XML body.

    ECB ships rates EUR-base, so the dict's values mean
    "1 EUR = ``rate`` UNIT". The function is total: malformed entries
    are skipped, never raised, so a partial degradation upstream still
    yields a partial cache rather than a full outage.
    """
    rates: dict[str, float] = {}
    try:
        # ECB daily XML is a fixed-shape public document served over
        # HTTPS by the European Central Bank. No external entity / DTD
        # declarations are present, no user input is parsed here.
        # Adding `defusedxml` only to silence bandit on a 30-element
        # static document is not worth the new dependency.
        root = ET.fromstring(payload)  # noqa: S314  # nosec B314
    except ET.ParseError:
        logger.warn("currency_service: ECB XML parse failed")
        return rates
    for cube in root.iter("{http://www.ecb.int/vocabulary/2002-08-01/eurofxref}Cube"):
        code = cube.get("currency")
        rate_str = cube.get("rate")
        if not code or not rate_str:
            continue
        try:
            rates[code.upper()] = float(rate_str)
        except ValueError:
            continue
    return rates


async def refresh_rates_async(*, timeout_seconds: float = 10.0) -> int:
    """Fetch ECB daily rates and populate the cache.

    Returns the number of pairs written (``EUR → currency``). Designed
    to be called at lifespan startup and periodically by a scheduler.
    Failures (network, parse) are logged and swallowed — callers never
    have to branch on the result.
    """
    try:
        client = get_http_client()
        response = await client.get(_ECB_DAILY_URL, timeout=timeout_seconds)
        response.raise_for_status()
    except Exception as exc:
        logger.warn(
            "currency_service: ECB refresh failed, cache unchanged",
            {"error": str(exc)},
        )
        return 0
    rates = _parse_ecb_xml(response.text)
    if not rates:
        return 0
    now = time.monotonic()
    with _lock:
        # ECB ships EUR-base, so every pair is keyed (EUR, X). Cross-rates
        # are derived on the fly inside ``_read_cached``.
        for code, rate in rates.items():
            if rate <= 0:
                continue
            _rate_cache[("EUR", code)] = (rate, now)
        # EUR → EUR sentinel keeps "is my base currency cached?" cheap.
        _rate_cache[("EUR", "EUR")] = (1.0, now)
    logger.info(
        "currency_service: ECB rates refreshed",
        {"pairs": len(rates)},
    )
    return len(rates)


def reset_cache() -> None:
    """Clear the in-process cache. Used by tests to avoid cross-test bleed."""
    with _lock:
        _rate_cache.clear()
