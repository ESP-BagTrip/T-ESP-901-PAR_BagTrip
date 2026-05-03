"""Unit tests for the agent ``resolve_iata_code`` façade."""

from unittest.mock import AsyncMock, patch

import pytest

from src.agent.tools import resolve_iata_code
from src.services.location_resolver import ResolvedCity


@pytest.mark.asyncio
async def test_resolve_iata_code_success():
    """Façade translates a ResolvedCity into the legacy dict shape."""
    resolved = ResolvedCity(
        iata="CDG",
        city="Paris",
        country="France",
        country_code="FR",
        latitude=49.0128,
        longitude=2.55,
        source="airportsdata.keyword",
    )
    with patch(
        "src.agent.tools.locations.resolve_city",
        new=AsyncMock(return_value=resolved),
    ):
        result = await resolve_iata_code("Paris")

    assert result["iata"] == "CDG"
    assert result["city"] == "Paris"
    assert result["country"] == "France"
    assert result["lat"] == 49.0128
    assert result["lon"] == 2.55


@pytest.mark.asyncio
async def test_resolve_iata_code_not_found():
    """A None resolution surfaces as an error dict."""
    with patch(
        "src.agent.tools.locations.resolve_city",
        new=AsyncMock(return_value=None),
    ):
        result = await resolve_iata_code("UnknownCity")

    assert "error" in result
    assert "No IATA code found" in result["error"]


@pytest.mark.asyncio
async def test_resolve_iata_code_exception():
    """Resolver exceptions are caught and translated into an error dict."""
    with patch(
        "src.agent.tools.locations.resolve_city",
        new=AsyncMock(side_effect=Exception("Data lookup failed")),
    ):
        result = await resolve_iata_code("NonExistentCityXYZ")

    assert "error" in result
    assert "Location search failed" in result["error"]
