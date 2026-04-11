"""Shared fixtures for amadeus integration tests.

The production code now pulls its AsyncClient from a process-wide singleton
(`src.integrations.http_client.get_http_client`) instead of constructing one
per call, so tests must patch that symbol in each amadeus submodule rather
than patching `httpx.AsyncClient` at the top level.
"""

from unittest.mock import AsyncMock, patch

import pytest


@pytest.fixture
def mock_http_client():
    """Patch `get_http_client` in every amadeus submodule to return a shared AsyncMock.

    Tests configure the mock's methods (post, get) to shape the response, and
    assert on call args the same way they did against the old per-request client.
    """
    mock_client = AsyncMock()
    with (
        patch(
            "src.integrations.amadeus.auth.get_http_client",
            return_value=mock_client,
        ),
        patch(
            "src.integrations.amadeus.flights.get_http_client",
            return_value=mock_client,
        ),
        patch(
            "src.integrations.amadeus.hotels.get_http_client",
            return_value=mock_client,
        ),
        patch(
            "src.integrations.amadeus.locations.get_http_client",
            return_value=mock_client,
        ),
    ):
        yield mock_client
