"""Unit tests for the in-process async circuit breaker.

A fake monotonic clock is injected so cooldown transitions are exercised
without ever sleeping.
"""

from __future__ import annotations

import pytest

from src.integrations.circuit_breaker import (
    CircuitBreaker,
    CircuitOpenError,
    CircuitState,
)


class _Clock:
    """Injectable monotonic clock; advance manually with ``tick``."""

    def __init__(self) -> None:
        self.now = 0.0

    def __call__(self) -> float:
        return self.now

    def tick(self, seconds: float) -> None:
        self.now += seconds


def _make_breaker(clock: _Clock, *, threshold: int = 3, reset: float = 30.0) -> CircuitBreaker:
    return CircuitBreaker(
        "test",
        failure_threshold=threshold,
        reset_timeout=reset,
        time_fn=clock,
    )


async def _ok() -> str:
    return "ok"


async def _boom() -> str:
    raise RuntimeError("upstream down")


def test_invalid_config_rejected():
    with pytest.raises(ValueError):
        CircuitBreaker("x", failure_threshold=0)
    with pytest.raises(ValueError):
        CircuitBreaker("x", reset_timeout=0)


@pytest.mark.asyncio
async def test_passes_through_when_closed():
    breaker = _make_breaker(_Clock())
    assert await breaker.call(_ok) == "ok"
    assert breaker.state is CircuitState.CLOSED


@pytest.mark.asyncio
async def test_opens_after_threshold_consecutive_failures():
    breaker = _make_breaker(_Clock(), threshold=3)

    for _ in range(3):
        with pytest.raises(RuntimeError):
            await breaker.call(_boom)

    assert breaker.state is CircuitState.OPEN


@pytest.mark.asyncio
async def test_success_resets_failure_count():
    breaker = _make_breaker(_Clock(), threshold=3)

    with pytest.raises(RuntimeError):
        await breaker.call(_boom)
    with pytest.raises(RuntimeError):
        await breaker.call(_boom)
    # A success in between resets the streak…
    await breaker.call(_ok)
    with pytest.raises(RuntimeError):
        await breaker.call(_boom)

    # …so two more failures are not enough to trip it.
    assert breaker.state is CircuitState.CLOSED


@pytest.mark.asyncio
async def test_fail_fast_while_open():
    breaker = _make_breaker(_Clock(), threshold=2)
    for _ in range(2):
        with pytest.raises(RuntimeError):
            await breaker.call(_boom)
    assert breaker.state is CircuitState.OPEN

    calls = {"n": 0}

    async def _counted() -> str:
        calls["n"] += 1
        return "ok"

    with pytest.raises(CircuitOpenError):
        await breaker.call(_counted)
    # The wrapped fn must never run while OPEN.
    assert calls["n"] == 0


@pytest.mark.asyncio
async def test_half_open_after_cooldown_then_recovers():
    clock = _Clock()
    breaker = _make_breaker(clock, threshold=2, reset=30.0)
    for _ in range(2):
        with pytest.raises(RuntimeError):
            await breaker.call(_boom)
    assert breaker.state is CircuitState.OPEN

    # Still OPEN before cooldown elapses.
    clock.tick(29.0)
    with pytest.raises(CircuitOpenError):
        await breaker.call(_ok)

    # Cooldown elapsed → one probe allowed; success closes the circuit.
    clock.tick(2.0)
    assert await breaker.call(_ok) == "ok"
    assert breaker.state is CircuitState.CLOSED


@pytest.mark.asyncio
async def test_half_open_probe_failure_reopens():
    clock = _Clock()
    breaker = _make_breaker(clock, threshold=2, reset=30.0)
    for _ in range(2):
        with pytest.raises(RuntimeError):
            await breaker.call(_boom)

    clock.tick(31.0)
    # Probe runs (HALF_OPEN) but fails → straight back to OPEN with fresh cooldown.
    with pytest.raises(RuntimeError):
        await breaker.call(_boom)
    assert breaker.state is CircuitState.OPEN

    # And it fails fast again immediately after.
    with pytest.raises(CircuitOpenError):
        await breaker.call(_ok)
