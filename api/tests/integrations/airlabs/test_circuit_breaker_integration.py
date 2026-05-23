"""Integration test: AirLabs breaker trips OPEN under repeated failures.

Verifies that a sustained AirLabs outage stops hitting the network (fail-fast)
while keeping the swallow-and-warn contract (``lookup_flight`` returns None).
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import httpx
import pytest

import src.integrations.airlabs.client as airlabs_client_module
from src.integrations.airlabs.client import AirLabsClient
from src.integrations.circuit_breaker import CircuitBreaker, CircuitState


@pytest.fixture(autouse=True)
def _fresh_breaker_and_cache():
    """Reset the module cache and install a fresh breaker per test."""
    airlabs_client_module._CACHE.clear()
    original = airlabs_client_module._breaker
    airlabs_client_module._breaker = CircuitBreaker(
        "airlabs-test", failure_threshold=3, reset_timeout=30.0
    )
    yield
    airlabs_client_module._breaker = original
    airlabs_client_module._CACHE.clear()


@pytest.mark.asyncio
async def test_repeated_failures_open_circuit_and_fail_fast():
    # Each call raises a connection error → counts as a breaker failure.
    mock_client = AsyncMock()
    mock_client.get.side_effect = httpx.ConnectError("airlabs unreachable")

    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", "fake-key"),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        # Three consecutive failures (threshold=3) — each still hits the network
        # and gracefully returns None.
        for i in range(3):
            assert await AirLabsClient.lookup_flight(f"AF{i}") is None

        assert airlabs_client_module._breaker.state is CircuitState.OPEN
        calls_before = mock_client.get.await_count

        # Circuit is now OPEN: subsequent lookups fail fast, still returning None
        # but WITHOUT touching the network.
        assert await AirLabsClient.lookup_flight("AF999") is None
        assert mock_client.get.await_count == calls_before
