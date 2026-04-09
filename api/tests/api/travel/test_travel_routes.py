"""Unit tests for the travel routes."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.travel.routes import router as travel_router
from src.integrations.amadeus.types import (
    Location,
    LocationAddress,
    LocationGeoCode,
    LocationSelf,
)

# Setup the test app
app = FastAPI()
app.include_router(travel_router)


@pytest.fixture(autouse=True)
def mock_settings():
    """Mock the settings instance to avoid ValidationError during testing."""
    mock_settings_obj = MagicMock()
    mock_settings_obj.AMADEUS_CLIENT_ID = "test_id"
    mock_settings_obj.AMADEUS_CLIENT_SECRET = "test_secret"
    mock_settings_obj.LLM_API_KEY = "test_llm_key"

    with patch("src.config.env.settings", new=mock_settings_obj):
        yield


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def valid_location():
    """A Location model instance for testing."""
    return Location(
        type="location",
        subType="CITY",
        name="Paris",
        detailedName="Paris, France",
        id="PAR",
        self_=LocationSelf(href="/v1/travel/locations/PAR", methods=["GET"]),
        timeZoneOffset="+02:00",
        iataCode="PAR",
        geoCode=LocationGeoCode(latitude=49.0, longitude=2.35),
        address=LocationAddress(
            cityName="Paris",
            cityCode="PAR",
            countryName="France",
            countryCode="FR",
            regionCode="EU",
        ),
    )


# ============================================================================
# LOCATION ENDPOINTS — Now using aviation_data_service (offline)
# ============================================================================


@patch("src.api.travel.routes.aviation_data_service")
class TestSearchLocationsByKeyword:
    """Test suite for the search_locations_by_keyword endpoint."""

    def test_search_locations_by_keyword_success(self, mock_service, client, valid_location):
        """Test successful search for locations by keyword."""
        mock_service.search_by_keyword.return_value = [valid_location]
        response = client.get("/v1/travel/locations?subType=CITY,AIRPORT&keyword=paris")
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 1
        assert data["locations"][0]["name"] == "Paris"
        mock_service.search_by_keyword.assert_called_once_with(
            "paris", sub_type="CITY,AIRPORT"
        )

    def test_search_locations_by_keyword_missing_params(self, mock_service, client):
        """Test search with missing query parameters."""
        response = client.get("/v1/travel/locations?keyword=paris")
        assert response.status_code == 422  # FastAPI's validation error

        response = client.get("/v1/travel/locations?subType=CITY")
        assert response.status_code == 422

    def test_search_locations_by_keyword_empty_results(self, mock_service, client):
        """Test search that returns no results."""
        mock_service.search_by_keyword.return_value = []
        response = client.get("/v1/travel/locations?subType=CITY,AIRPORT&keyword=xyznotexist")
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0
        assert data["locations"] == []

    def test_search_locations_by_keyword_generic_error(self, mock_service, client):
        """Test that a generic exception is handled as a 500 error."""
        mock_service.search_by_keyword.side_effect = Exception("Generic error")
        response = client.get("/v1/travel/locations?subType=CITY,AIRPORT&keyword=paris")
        assert response.status_code == 500
        assert response.json()["detail"]["code"] == "INTERNAL_ERROR"
        assert response.json()["detail"]["error"] == "Failed to search locations"


@patch("src.api.travel.routes.aviation_data_service")
class TestSearchLocationById:
    """Test suite for the search_location_by_id endpoint."""

    def test_search_location_by_id_success(self, mock_service, client, valid_location):
        """Test successful search for a location by ID."""
        mock_service.get_by_id.return_value = valid_location
        response = client.get("/v1/travel/locations/CDG")
        assert response.status_code == 200
        assert response.json()["name"] == "Paris"
        mock_service.get_by_id.assert_called_once_with("CDG")

    def test_search_location_by_id_not_found(self, mock_service, client):
        """Test searching for an ID that doesn't exist."""
        mock_service.get_by_id.return_value = None
        response = client.get("/v1/travel/locations/UNKNOWN")
        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Location not found"


@patch("src.api.travel.routes.aviation_data_service")
class TestSearchLocationNearest:
    """Test suite for the search_location_nearest endpoint."""

    def test_search_location_nearest_success(self, mock_service, client, valid_location):
        """Test successful search for nearest locations."""
        mock_service.search_nearest.return_value = [valid_location]
        response = client.get("/v1/travel/locations/nearest?latitude=48.8566&longitude=2.3522")
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 1
        mock_service.search_nearest.assert_called_once_with(48.8566, 2.3522)

    def test_search_location_nearest_invalid_latitude(self, mock_service, client):
        """Test with out-of-range latitude."""
        response = client.get("/v1/travel/locations/nearest?latitude=91&longitude=2.35")
        assert response.status_code == 422

    def test_search_location_nearest_missing_params(self, mock_service, client):
        """Test with missing parameters."""
        response = client.get("/v1/travel/locations/nearest?latitude=48.85")
        assert response.status_code == 422


# ============================================================================
# FLIGHT ENDPOINTS — Still using amadeus_client
# ============================================================================


@patch("src.api.travel.routes.amadeus_client", new_callable=AsyncMock)
class TestSearchFlightOffers:
    """Test suite for the search_flight_offers endpoint."""

    def setup_method(self):
        """Clear flight search cache before each test."""
        from src.api.travel.routes import _flight_search_cache

        _flight_search_cache.clear()

    def test_search_flight_offers_success(self, mock_amadeus_client, client):
        """Test successful search for flight offers."""
        mock_amadeus_client.search_flight_offers.return_value = {"data": "some flight data"}
        response = client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=1"
        )
        assert response.status_code == 200
        assert response.json() == {"data": "some flight data"}
        mock_amadeus_client.search_flight_offers.assert_called_once()

    def test_search_flight_offers_cache_hit(self, mock_amadeus_client, client):
        """Test that identical search uses cache on second call."""
        mock_amadeus_client.search_flight_offers.return_value = {"data": "cached"}
        url = "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=1"

        # First call — cache miss
        response1 = client.get(url)
        assert response1.status_code == 200
        assert mock_amadeus_client.search_flight_offers.call_count == 1

        # Second call — cache hit
        response2 = client.get(url)
        assert response2.status_code == 200
        assert response2.json() == {"data": "cached"}
        # Amadeus should NOT be called again
        assert mock_amadeus_client.search_flight_offers.call_count == 1

    def test_search_flight_offers_cache_miss_different_params(self, mock_amadeus_client, client):
        """Test that different params produce cache miss."""
        mock_amadeus_client.search_flight_offers.return_value = {"data": "result"}

        client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=1"
        )
        client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=BCN&departureDate=2025-12-15&adults=1"
        )
        # Two different destinations = 2 Amadeus calls
        assert mock_amadeus_client.search_flight_offers.call_count == 2

    def test_search_flight_offers_missing_required_params(self, mock_amadeus_client, client):
        """Test flight offer search with missing required parameters."""
        response = client.get(
            "/v1/travel/flight/offers?destinationLocationCode=FCO&departureDate=2025-12-15&adults=1"
        )
        assert response.status_code == 422

    def test_search_flight_offers_invalid_adults(self, mock_amadeus_client, client):
        """Test flight offer search with invalid number of adults."""
        response = client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=10"
        )
        assert response.status_code == 422  # FastAPI validation

    def test_search_flight_offers_infants_exceed_adults(self, mock_amadeus_client, client):
        """Test validation where infants outnumber adults."""
        response = client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=1&infants=2"
        )
        assert response.status_code == 400
        assert "infants cannot exceed the number of adults" in response.json()["detail"]["error"]

    def test_search_flight_offers_conflicting_airline_codes(self, mock_amadeus_client, client):
        """Test validation for using both included and excluded airline codes."""
        response = client.get(
            "/v1/travel/flight/offers?originLocationCode=PAR&destinationLocationCode=FCO&departureDate=2025-12-15&adults=1"
            "&includedAirlineCodes=AF&excludedAirlineCodes=BA"
        )
        assert response.status_code == 400
        assert "cannot be used together" in response.json()["detail"]["error"]


@patch("src.api.travel.routes.amadeus_client", new_callable=AsyncMock)
class TestSearchFlightDestinations:
    """Test suite for the search_flight_destinations endpoint."""

    def test_search_flight_destinations_success(self, mock_amadeus_client, client):
        """Test successful search for flight destinations."""
        mock_amadeus_client.search_flight_destinations.return_value = {
            "data": "some destination data"
        }
        response = client.get("/v1/travel/flight/destinations?origin=PAR")
        assert response.status_code == 200
        assert response.json() == {"data": "some destination data"}
        mock_amadeus_client.search_flight_destinations.assert_called_once()

    def test_search_flight_destinations_missing_origin(self, mock_amadeus_client, client):
        """Test flight destination search with missing origin."""
        response = client.get("/v1/travel/flight/destinations")
        assert response.status_code == 422

    def test_search_flight_destinations_invalid_duration(self, mock_amadeus_client, client):
        """Test with an invalid duration."""
        response = client.get("/v1/travel/flight/destinations?origin=PAR&duration=0")
        assert response.status_code == 422  # FastAPI validation


@patch("src.api.travel.routes.amadeus_client", new_callable=AsyncMock)
class TestSearchFlightCheapestDates:
    """Test suite for the search_flight_cheapest_dates endpoint."""

    def test_search_flight_cheapest_dates_success(self, mock_amadeus_client, client):
        """Test successful search for cheapest flight dates."""
        mock_amadeus_client.search_flight_cheapest_dates.return_value = {
            "data": "some cheap date data"
        }
        response = client.get("/v1/travel/flight/cheapest-dates?origin=PAR&destination=NYC")
        assert response.status_code == 200
        assert response.json() == {"data": "some cheap date data"}
        mock_amadeus_client.search_flight_cheapest_dates.assert_called_once()

    def test_search_flight_cheapest_dates_missing_params(self, mock_amadeus_client, client):
        """Test with missing origin or destination."""
        response = client.get("/v1/travel/flight/cheapest-dates?destination=NYC")
        assert response.status_code == 422
        response = client.get("/v1/travel/flight/cheapest-dates?origin=PAR")
        assert response.status_code == 422

    def test_search_flight_cheapest_dates_invalid_price(self, mock_amadeus_client, client):
        """Test with an invalid maxPrice."""
        response = client.get(
            "/v1/travel/flight/cheapest-dates?origin=PAR&destination=NYC&maxPrice=0"
        )
        assert response.status_code == 422  # FastAPI validation
