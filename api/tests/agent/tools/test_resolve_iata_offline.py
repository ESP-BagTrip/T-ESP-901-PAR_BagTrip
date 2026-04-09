"""Unit tests for resolve_iata_code using offline aviation data."""

from unittest.mock import patch

import pytest

from src.agent.tools import resolve_iata_code
from src.integrations.amadeus.types import (
    Location,
    LocationAddress,
    LocationGeoCode,
    LocationSelf,
)


def _make_location(iata: str, city: str, country: str, lat: float, lon: float) -> Location:
    return Location(
        type="location",
        subType="AIRPORT",
        name=f"{city} Airport",
        detailedName=f"{city} Airport, {city}",
        id=iata,
        self_=LocationSelf(href=f"/v1/travel/locations/{iata}", methods=["GET"]),
        timeZoneOffset="+00:00",
        iataCode=iata,
        geoCode=LocationGeoCode(latitude=lat, longitude=lon),
        address=LocationAddress(
            cityName=city,
            cityCode=iata,
            countryName=country,
            countryCode="FR",
            regionCode="EU",
        ),
    )


class TestResolveIataCodeOffline:
    """Tests for resolve_iata_code using offline aviation data."""

    @pytest.mark.asyncio
    @patch("src.agent.tools.aviation_data_service")
    async def test_resolve_paris(self, mock_service):
        """Resolving 'Paris' returns CDG IATA code."""
        mock_service.search_by_keyword.return_value = [
            _make_location("CDG", "Paris", "France", 49.01, 2.55)
        ]

        result = await resolve_iata_code("Paris")

        assert result["iata"] == "CDG"
        assert result["city"] == "Paris"
        assert result["country"] == "France"
        assert result["lat"] == 49.01
        assert result["lon"] == 2.55
        mock_service.search_by_keyword.assert_called_once_with(
            "Paris", sub_type="CITY,AIRPORT", limit=1
        )

    @pytest.mark.asyncio
    @patch("src.agent.tools.aviation_data_service")
    async def test_resolve_unknown_city(self, mock_service):
        """Unknown city returns error dict."""
        mock_service.search_by_keyword.return_value = []

        result = await resolve_iata_code("Atlantis")

        assert "error" in result
        assert "Atlantis" in result["error"]

    @pytest.mark.asyncio
    @patch("src.agent.tools.aviation_data_service")
    async def test_no_amadeus_call(self, mock_service):
        """Verify no Amadeus API call is made (offline only)."""
        mock_service.search_by_keyword.return_value = [
            _make_location("JFK", "New York", "United States", 40.64, -73.78)
        ]

        with patch("src.agent.tools.amadeus_client") as mock_amadeus:
            await resolve_iata_code("New York")
            # amadeus_client should never be called
            mock_amadeus.search_locations_by_keyword.assert_not_called()

    @pytest.mark.asyncio
    @patch("src.agent.tools.aviation_data_service")
    async def test_error_handling(self, mock_service):
        """Service exception returns error dict gracefully."""
        mock_service.search_by_keyword.side_effect = RuntimeError("data corrupted")

        result = await resolve_iata_code("Berlin")

        assert "error" in result
        assert "data corrupted" in result["error"]
