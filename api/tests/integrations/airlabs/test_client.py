"""Unit tests for the async AirLabs client.

The client now pulls its AsyncClient from the process-wide singleton
(`src.integrations.http_client.get_http_client`) instead of doing a blocking
`httpx.get(...)` on the event loop. These tests patch that symbol and assert
the async path: API-key gating, success parsing, list/dict response shapes,
in-process caching and the swallow-and-warn failure fallback.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

import src.integrations.airlabs.client as airlabs_client_module
from src.integrations.airlabs.client import AirLabsClient


@pytest.fixture(autouse=True)
def _clear_cache():
    """Each test starts with a clean module-level cache."""
    airlabs_client_module._cache.clear()
    yield
    airlabs_client_module._cache.clear()


def _build_response(payload: dict) -> MagicMock:
    response = MagicMock()
    response.json.return_value = payload
    response.raise_for_status.return_value = None
    return response


@pytest.mark.asyncio
async def test_returns_none_when_api_key_missing():
    mock_client = AsyncMock()
    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", None),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        result = await AirLabsClient.lookup_flight("AF1234")
    assert result is None
    mock_client.get.assert_not_called()


@pytest.mark.asyncio
async def test_success_parses_dict_response_and_caches():
    data = {"flight_iata": "AF1234", "status": "en-route"}
    mock_client = AsyncMock()
    mock_client.get.return_value = _build_response({"response": data})
    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", "fake-key"),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        result = await AirLabsClient.lookup_flight("af1234")
        # Second call must hit the cache, not the network.
        cached = await AirLabsClient.lookup_flight("AF1234")

    assert result == data
    assert cached == data
    mock_client.get.assert_awaited_once()
    # IATA code is uppercased + stripped before the request.
    _, kwargs = mock_client.get.call_args
    assert kwargs["params"]["flight_iata"] == "AF1234"


@pytest.mark.asyncio
async def test_success_parses_list_response():
    first = {"flight_iata": "AF1234"}
    mock_client = AsyncMock()
    mock_client.get.return_value = _build_response({"response": [first, {"x": 1}]})
    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", "fake-key"),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        result = await AirLabsClient.lookup_flight("AF1234")
    assert result == first


@pytest.mark.asyncio
async def test_empty_response_returns_none():
    mock_client = AsyncMock()
    mock_client.get.return_value = _build_response({"response": None})
    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", "fake-key"),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        result = await AirLabsClient.lookup_flight("AF1234")
    assert result is None


@pytest.mark.asyncio
async def test_http_error_is_swallowed_and_returns_none():
    mock_client = AsyncMock()
    mock_client.get.side_effect = RuntimeError("boom")
    with (
        patch.object(airlabs_client_module.settings, "AIRLABS_API_KEY", "fake-key"),
        patch(
            "src.integrations.airlabs.client.get_http_client",
            return_value=mock_client,
        ),
    ):
        result = await AirLabsClient.lookup_flight("AF1234")
    assert result is None
