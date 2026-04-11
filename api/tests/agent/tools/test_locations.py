"""Unit tests for agent location tools."""

from unittest.mock import MagicMock, patch

import pytest

from src.agent.tools import resolve_iata_code


@pytest.mark.asyncio
async def test_resolve_iata_code_success():
    """Test successful IATA code resolution using offline aviation data."""
    mock_location = MagicMock()
    mock_location.iataCode = "CDG"
    mock_location.address.cityName = "Paris"
    mock_location.address.countryName = "France"
    mock_location.address.cityCode = "PAR"
    mock_location.geoCode.latitude = 49.0128
    mock_location.geoCode.longitude = 2.55

    with patch("src.agent.tools.locations.aviation_data_service") as mock_service:
        mock_service.search_by_keyword.return_value = [mock_location]

        result = await resolve_iata_code("Paris")

        assert result["iata"] == "CDG"
        assert result["city"] == "Paris"
        assert result["country"] == "France"
        assert result["lat"] == 49.0128
        assert result["lon"] == 2.55


@pytest.mark.asyncio
async def test_resolve_iata_code_not_found():
    """Test IATA resolution when no results returned."""
    with patch("src.agent.tools.locations.aviation_data_service") as mock_service:
        mock_service.search_by_keyword.return_value = []

        result = await resolve_iata_code("UnknownCity")

        assert "error" in result
        assert "No IATA code found" in result["error"]


@pytest.mark.asyncio
async def test_resolve_iata_code_exception():
    """Test IATA resolution error handling."""
    with patch("src.agent.tools.locations.aviation_data_service") as mock_service:
        mock_service.search_by_keyword.side_effect = Exception("Data lookup failed")

        result = await resolve_iata_code("NonExistentCityXYZ")

        assert "error" in result
        assert "Location search failed" in result["error"]
