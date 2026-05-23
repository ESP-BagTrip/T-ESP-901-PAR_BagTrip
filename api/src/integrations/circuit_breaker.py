"""In-process async circuit breaker for outbound integrations.

Today every integration (Amadeus, AirLabs, …) retries on transient errors but
keeps hammering a provider that is fully down: each user request still pays the
full timeout × retry budget before failing. A circuit breaker short-circuits
that — once a provider has failed ``failure_threshold`` times in a row we trip
the circuit OPEN and fail-fast for ``reset_timeout`` seconds, then allow a single
probe (HALF_OPEN) to test recovery.

Deliberately small and dependency-free:
  - one breaker instance per integration (module-level singleton),
  - an ``asyncio.Lock`` makes the state transitions safe within a worker,
  - the clock is injectable (``time_fn``) so tests never sleep.

States
------
CLOSED      normal operation; failures are counted.
OPEN        fail-fast immediately (raise ``CircuitOpenError``) until the cooldown
            elapses.
HALF_OPEN   a single probe call is allowed through; success closes the circuit,
            failure re-opens it for another cooldown.
"""

from __future__ import annotations

import asyncio
from collections.abc import Awaitable, Callable
from enum import Enum
from time import monotonic
from typing import TypeVar

from src.utils.logger import logger

T = TypeVar("T")

# Defaults tuned for third-party REST providers behind the shared httpx pool:
# a handful of consecutive failures is a strong "provider is down" signal, and a
# 30s cooldown keeps us from stampeding the upstream while still recovering fast.
_DEFAULT_FAILURE_THRESHOLD = 5
_DEFAULT_RESET_TIMEOUT = 30.0


class CircuitState(str, Enum):
    """Lifecycle states of a circuit breaker."""

    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitOpenError(Exception):
    """Raised when a call is rejected because the circuit is OPEN.

    Callers that want a graceful fallback (e.g. AirLabs' swallow-and-warn) catch
    this and degrade; callers that propagate failures let it bubble and map it to
    their usual error contract.
    """

    def __init__(self, name: str, retry_after: float) -> None:
        self.name = name
        self.retry_after = retry_after
        super().__init__(f"Circuit '{name}' is open; failing fast for ~{retry_after:.1f}s")


class CircuitBreaker:
    """Async, in-process circuit breaker around a single integration.

    Args:
        name: Human-readable identifier used in logs.
        failure_threshold: Consecutive failures before the circuit trips OPEN.
        reset_timeout: Seconds the circuit stays OPEN before a HALF_OPEN probe.
        time_fn: Monotonic clock source (injected in tests).
    """

    def __init__(
        self,
        name: str,
        *,
        failure_threshold: int = _DEFAULT_FAILURE_THRESHOLD,
        reset_timeout: float = _DEFAULT_RESET_TIMEOUT,
        time_fn: Callable[[], float] = monotonic,
    ) -> None:
        if failure_threshold < 1:
            raise ValueError("failure_threshold must be >= 1")
        if reset_timeout <= 0:
            raise ValueError("reset_timeout must be > 0")
        self.name = name
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self._time_fn = time_fn
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._opened_at: float | None = None
        self._lock = asyncio.Lock()

    @property
    def state(self) -> CircuitState:
        """Current breaker state (without advancing the OPEN→HALF_OPEN clock)."""
        return self._state

    def _cooldown_remaining(self) -> float:
        if self._opened_at is None:
            return 0.0
        return max(0.0, self.reset_timeout - (self._time_fn() - self._opened_at))

    async def _before_call(self) -> None:
        """Gate a call; raise ``CircuitOpenError`` if the circuit is OPEN."""
        async with self._lock:
            if self._state is CircuitState.OPEN:
                if self._cooldown_remaining() <= 0:
                    # Cooldown elapsed: allow exactly one probe through.
                    self._state = CircuitState.HALF_OPEN
                    logger.info("Circuit half-open; probing recovery", {"circuit": self.name})
                else:
                    raise CircuitOpenError(self.name, self._cooldown_remaining())

    async def _on_success(self) -> None:
        async with self._lock:
            if self._state is not CircuitState.CLOSED:
                logger.info("Circuit closed after success", {"circuit": self.name})
            self._state = CircuitState.CLOSED
            self._failure_count = 0
            self._opened_at = None

    async def _on_failure(self) -> None:
        async with self._lock:
            if self._state is CircuitState.HALF_OPEN:
                # Probe failed → straight back to OPEN with a fresh cooldown.
                self._trip_open()
                return
            self._failure_count += 1
            if self._failure_count >= self.failure_threshold:
                self._trip_open()

    def _trip_open(self) -> None:
        self._state = CircuitState.OPEN
        self._opened_at = self._time_fn()
        logger.warn(
            "Circuit opened; failing fast",
            {
                "circuit": self.name,
                "failures": self._failure_count,
                "reset_timeout": self.reset_timeout,
            },
        )

    async def call(self, fn: Callable[[], Awaitable[T]]) -> T:
        """Run ``fn`` through the breaker.

        Raises ``CircuitOpenError`` immediately when OPEN. Otherwise runs ``fn``;
        any raised exception counts as a failure and is re-raised, while a normal
        return counts as a success.
        """
        await self._before_call()
        try:
            result = await fn()
        except Exception:
            await self._on_failure()
            raise
        await self._on_success()
        return result
