"""Integration test: Amadeus breaker trips OPEN under repeated provider failures.

Exercises the real ``amadeus_breaker`` decorator + its shared breaker, verifying
that repeated provider-health failures fail-fast with a clean
``UPSTREAM_UNAVAILABLE`` AppError, while client-side 400/404 errors never trip it.
"""

from __future__ import annotations

import pytest

import src.integrations.amadeus.breaker as breaker_module
from src.integrations.amadeus.breaker import amadeus_breaker
from src.integrations.circuit_breaker import CircuitBreaker, CircuitState
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _fresh_amadeus_breaker():
    """Install a fresh shared breaker so tests don't leak state into each other."""
    original = breaker_module._breaker
    breaker_module._breaker = CircuitBreaker(
        "amadeus-test", failure_threshold=3, reset_timeout=30.0
    )
    yield
    breaker_module._breaker = original


@pytest.mark.asyncio
async def test_repeated_transient_failures_open_circuit_and_fail_fast():
    calls = {"n": 0}

    @amadeus_breaker
    async def flaky() -> str:
        calls["n"] += 1
        # 503 is a provider-health failure → counted by the breaker.
        raise AppError("UPSTREAM_UNAVAILABLE", 503, "amadeus down")

    # Threshold failures: the original AppError propagates each time.
    for _ in range(3):
        with pytest.raises(AppError) as exc:
            await flaky()
        assert exc.value.status_code == 503

    assert breaker_module._breaker.state is CircuitState.OPEN
    calls_before = calls["n"]

    # Circuit OPEN: fail-fast with a clean unavailable error, fn not invoked.
    with pytest.raises(AppError) as exc:
        await flaky()
    assert exc.value.code == "UPSTREAM_UNAVAILABLE"
    assert exc.value.detail is not None
    assert exc.value.detail.get("circuit") == "amadeus-test"
    assert calls["n"] == calls_before


@pytest.mark.asyncio
async def test_client_errors_do_not_trip_the_circuit():
    @amadeus_breaker
    async def bad_request() -> str:
        # 400/404 say nothing about provider health → must NOT trip the breaker.
        raise AppError("INVALID_REQUEST", 400, "bad query")

    for _ in range(10):
        with pytest.raises(AppError) as exc:
            await bad_request()
        # The original client error is preserved, not masked as UNAVAILABLE.
        assert exc.value.code == "INVALID_REQUEST"
        assert exc.value.status_code == 400

    assert breaker_module._breaker.state is CircuitState.CLOSED
