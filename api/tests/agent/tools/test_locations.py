"""Unit tests for agent location tools."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.agent.tools import resolve_iata_code


@pytest.mark.asyncio
async def test_resolve_iata_code_success():
    """Test successful IATA code resolution."""
    mock_location = MagicMock()
    mock_location.iataCode = "CDG"
    mock_location.address.cityName = "Paris"
    mock_location.address.countryName = "France"
    mock_location.address.cityCode = "PAR"
    mock_location.geoCode.latitude = 48.85
    mock_location.geoCode.longitude = 2.35

    with patch("src.agent.tools.amadeus_client") as mock_amadeus:
        mock_amadeus.search_locations_by_keyword = AsyncMock(return_value=[mock_location])

        result = await resolve_iata_code("Paris")

        assert result["iata"] == "CDG"
        assert result["city"] == "Paris"
        assert result["country"] == "France"
        assert result["lat"] == 48.85
        assert result["lon"] == 2.35


@pytest.mark.asyncio
async def test_resolve_iata_code_not_found():
    """Test IATA resolution when no results returned."""
    with patch("src.agent.tools.amadeus_client") as mock_amadeus:
        mock_amadeus.search_locations_by_keyword = AsyncMock(return_value=[])

        result = await resolve_iata_code("UnknownCity")

        assert "error" in result


@pytest.mark.asyncio
async def test_resolve_iata_code_exception():
    """Test IATA resolution error handling."""
    with patch("src.agent.tools.amadeus_client") as mock_amadeus:
        mock_amadeus.search_locations_by_keyword = AsyncMock(side_effect=Exception("Amadeus Error"))

        # Use a different city name to avoid hitting the idempotency cache from a previous test
        result = await resolve_iata_code("NonExistentCityXYZ")

        assert "error" in result
        assert "Amadeus" in result["error"]
