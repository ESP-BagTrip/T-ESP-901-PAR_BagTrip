"""Unit tests for the Amadeus integration."""

import time
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from src.integrations.amadeus.auth import fetch_token
from src.integrations.amadeus.client import AmadeusClient
from src.integrations.amadeus.flights import (
    confirm_flight_price,
    create_flight_order,
    search_flight_cheapest_dates,
    search_flight_destinations,
    search_flight_offers,
)
from src.integrations.amadeus.hotels import (
    search_hotel_list,
    search_hotel_offers,
)
from src.integrations.amadeus.locations import (
    search_location_by_id,
    search_location_nearest,
    search_locations_by_keyword,
)
from src.integrations.amadeus.types import (
    FlightCheapestDateSearchQuery,
    FlightInspirationSearchQuery,
    FlightOffer,
    FlightOfferSearchQuery,
    HotelListSearchQuery,
    HotelOffersSearchQuery,
    LocationIdSearchQuery,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)
from src.utils.errors import AppError


@pytest.fixture
def mock_token():
    """Mock the fetch_token function."""
    with (
        patch("src.integrations.amadeus.auth._token_cache", None),
        patch("src.integrations.amadeus.auth.fetch_token", return_value="test_token") as mock,
    ):
        yield mock


class TestAmadeusAuth:
    """Tests for the Amadeus authentication."""

    @pytest.mark.asyncio
    async def test_fetch_token_success(self, mock_http_client):
        """Test successful token retrieval."""
        with patch("src.integrations.amadeus.auth.settings") as mock_settings:
            mock_settings.AMADEUS_BASE_URL = "https://test.api.amadeus.com"
            mock_settings.AMADEUS_CLIENT_ID = "client_id"
            mock_settings.AMADEUS_CLIENT_SECRET = "client_secret"

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {
                "access_token": "new_token",
                "expires_in": 1800,
                "token_type": "Bearer",
            }
            mock_http_client.post.return_value = mock_response

            with patch("src.integrations.amadeus.auth._token_cache", None):
                token = await fetch_token()
                assert token == "new_token"
                mock_http_client.post.assert_called_once()

    @pytest.mark.asyncio
    async def test_fetch_token_cached(self):
        """Test token retrieval from cache."""
        future_time = (time.time() + 1000) * 1000
        cache = {"access_token": "cached_token", "expires_at": future_time}

        with patch("src.integrations.amadeus.auth._token_cache", cache):
            token = await fetch_token()
            assert token == "cached_token"

    @pytest.mark.asyncio
    async def test_fetch_token_expired_cache(self, mock_http_client):
        """Test token retrieval when cache is expired."""
        past_time = (time.time() - 1000) * 1000
        cache = {"access_token": "expired_token", "expires_at": past_time}

        with (
            patch("src.integrations.amadeus.auth._token_cache", cache),
            patch("src.integrations.amadeus.auth.settings"),
        ):
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"access_token": "fresh_token", "expires_in": 1800}
            mock_http_client.post.return_value = mock_response

            token = await fetch_token()
            assert token == "fresh_token"

    @pytest.mark.asyncio
    async def test_fetch_token_error(self, mock_http_client):
        """Test token retrieval error handling."""
        with patch("src.integrations.amadeus.auth.settings"):
            mock_response = MagicMock()
            mock_response.status_code = 400
            mock_response.text = "Error"
            mock_http_client.post.return_value = mock_response

            with (
                patch("src.integrations.amadeus.auth._token_cache", None),
                pytest.raises(AppError) as exc_info,
            ):
                await fetch_token()
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_AUTH_ERROR"

    @pytest.mark.asyncio
    async def test_fetch_token_missing_token_in_response(self, mock_http_client):
        """Test response with missing access_token."""
        with patch("src.integrations.amadeus.auth.settings"):
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"foo": "bar"}  # No access_token
            mock_http_client.post.return_value = mock_response

            with (
                patch("src.integrations.amadeus.auth._token_cache", None),
                pytest.raises(AppError) as exc_info,
            ):
                await fetch_token()
            assert exc_info.value.status_code == 502
            assert "missing access_token" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_fetch_token_http_error(self, mock_http_client):
        """Test HTTP error during token fetch."""
        with patch("src.integrations.amadeus.auth.settings"):
            # Mock request object on exception
            mock_request = MagicMock()
            mock_request.url = "http://test.url"
            error = httpx.HTTPError("Network Error")
            error.request = mock_request
            mock_http_client.post.side_effect = error

            with (
                patch("src.integrations.amadeus.auth._token_cache", None),
                pytest.raises(AppError) as exc_info,
            ):
                await fetch_token()
            assert exc_info.value.status_code == 503
            assert exc_info.value.code == "UPSTREAM_UNAVAILABLE"


class TestAmadeusLocations:
    """Tests for location-related functions."""

    @pytest.mark.asyncio
    async def test_search_locations_by_keyword(self, mock_http_client):
        """Test search_locations_by_keyword."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "type": "location",
                    "subType": "CITY",
                    "name": "Paris",
                    "detailedName": "Paris, France",
                    "id": "PAR",
                    "self": {"href": "url", "methods": ["GET"]},
                    "timeZoneOffset": "+02:00",
                    "geoCode": {"latitude": 49.0, "longitude": 2.35},
                    "address": {
                        "cityName": "Paris",
                        "cityCode": "PAR",
                        "countryName": "France",
                        "countryCode": "FR",
                        "regionCode": "EU",
                    },
                }
            ]
        }
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationKeywordSearchQuery(keyword="Paris", subType="CITY")
            locations = await search_locations_by_keyword(query)

            assert len(locations) == 1
            assert locations[0].name == "Paris"

    @pytest.mark.asyncio
    async def test_search_locations_by_keyword_error(self, mock_http_client):
        """Test search_locations_by_keyword error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationKeywordSearchQuery(keyword="Paris", subType="CITY")
            with pytest.raises(AppError) as exc_info:
                await search_locations_by_keyword(query)
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_ERROR"

    @pytest.mark.asyncio
    async def test_search_location_by_id(self, mock_http_client):
        """Test search_location_by_id."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": {
                "type": "location",
                "subType": "CITY",
                "name": "Paris",
                "detailedName": "Paris, France",
                "id": "PAR",
                "self": {"href": "url", "methods": ["GET"]},
                "timeZoneOffset": "+02:00",
                "geoCode": {"latitude": 49.0, "longitude": 2.35},
                "address": {
                    "cityName": "Paris",
                    "cityCode": "PAR",
                    "countryName": "France",
                    "countryCode": "FR",
                    "regionCode": "EU",
                },
            }
        }
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            location = await search_location_by_id(query)

            assert location.id == "PAR"

    @pytest.mark.asyncio
    async def test_search_location_by_id_not_found(self, mock_http_client):
        """Test search_location_by_id with no data."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": None}
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            with pytest.raises(AppError) as exc_info:
                await search_location_by_id(query)
            assert exc_info.value.status_code == 404
            assert exc_info.value.code == "NOT_FOUND"

    @pytest.mark.asyncio
    async def test_search_location_by_id_http_error(self, mock_http_client):
        """Test search_location_by_id HTTP error."""
        mock_http_client.get.side_effect = httpx.HTTPError("Network Error")

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            with pytest.raises(AppError) as exc_info:
                await search_location_by_id(query)
            assert exc_info.value.status_code == 503
            assert exc_info.value.code == "UPSTREAM_UNAVAILABLE"

    @pytest.mark.asyncio
    async def test_search_location_nearest(self, mock_http_client):
        """Test search_location_nearest."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "type": "location",
                    "subType": "AIRPORT",
                    "name": "CDG",
                    "detailedName": "Charles de Gaulle",
                    "id": "CDG",
                    "self": {"href": "url", "methods": ["GET"]},
                    "timeZoneOffset": "+02:00",
                    "geoCode": {"latitude": 49.01, "longitude": 2.55},
                    "address": {
                        "cityName": "Paris",
                        "cityCode": "PAR",
                        "countryName": "France",
                        "countryCode": "FR",
                        "regionCode": "EU",
                    },
                }
            ]
        }
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationNearestSearchQuery(latitude=49.0, longitude=2.5)
            locations = await search_location_nearest(query)

            assert len(locations) == 1
            assert locations[0].id == "CDG"

    @pytest.mark.asyncio
    async def test_search_location_nearest_error(self, mock_http_client):
        """Test search_location_nearest error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationNearestSearchQuery(latitude=49.0, longitude=2.5)
            with pytest.raises(AppError) as exc_info:
                await search_location_nearest(query)
            assert exc_info.value.status_code == 400
            assert exc_info.value.code == "INVALID_REQUEST"


class TestAmadeusFlights:
    """Tests for flight-related functions."""

    @pytest.mark.asyncio
    async def test_search_flight_offers_all_params(self, mock_http_client):
        """Test search_flight_offers with all optional parameters."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightOfferSearchQuery(
                originLocationCode="PAR",
                destinationLocationCode="NYC",
                departureDate="2025-12-15",
                adults=1,
                returnDate="2025-12-20",
                children=1,
                infants=0,
                travelClass="ECONOMY",
                nonStop=True,
                currencyCode="EUR",
                maxPrice=1000,
                max=5,
                includedAirlineCodes="AF,BA",
            )
            await search_flight_offers(query)

            # Check if all params were passed
            call_args = mock_http_client.get.call_args
            params = call_args[1]["params"]
            assert params["returnDate"] == "2025-12-20"
            assert params["children"] == 1
            assert params["includedAirlineCodes"] == "AF,BA"

    @pytest.mark.asyncio
    async def test_search_flight_offers_conflict_airlines(self, mock_http_client):
        """Test search_flight_offers with conflicting airline codes."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightOfferSearchQuery(
                originLocationCode="PAR",
                destinationLocationCode="NYC",
                departureDate="2025-12-15",
                adults=1,
                includedAirlineCodes="AF",
                excludedAirlineCodes="BA",
            )
            await search_flight_offers(query)

            # Check priority logic
            call_args = mock_http_client.get.call_args
            params = call_args[1]["params"]
            assert "includedAirlineCodes" in params
            assert "excludedAirlineCodes" not in params

    @pytest.mark.asyncio
    async def test_search_flight_offers_error(self, mock_http_client):
        """Test search_flight_offers error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Error"
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightOfferSearchQuery(
                originLocationCode="PAR",
                destinationLocationCode="NYC",
                departureDate="2025-12-15",
                adults=1,
            )
            with pytest.raises(AppError) as exc_info:
                await search_flight_offers(query)
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_ERROR"

    @pytest.mark.asyncio
    async def test_search_flight_destinations_all_params(self, mock_http_client):
        """Test search_flight_destinations with optional params."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightInspirationSearchQuery(
                origin="PAR",
                departureDate="2025-12-01",
                oneWay=True,
                duration=5,
                nonStop=True,
                maxPrice=500,
                viewBy="COUNTRY",
            )
            await search_flight_destinations(query)

            call_args = mock_http_client.get.call_args
            params = call_args[1]["params"]
            assert params["viewBy"] == "COUNTRY"

    @pytest.mark.asyncio
    async def test_search_flight_destinations_error(self, mock_http_client):
        """Test search_flight_destinations error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightInspirationSearchQuery(origin="PAR")
            with pytest.raises(AppError) as exc_info:
                await search_flight_destinations(query)
            assert exc_info.value.status_code == 400
            assert exc_info.value.code == "INVALID_REQUEST"

    @pytest.mark.asyncio
    async def test_search_flight_cheapest_dates(self, mock_http_client):
        """Test search_flight_cheapest_dates."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightCheapestDateSearchQuery(origin="PAR", destination="NYC")
            await search_flight_cheapest_dates(query)
            mock_http_client.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_search_flight_cheapest_dates_error(self, mock_http_client):
        """Test search_flight_cheapest_dates error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightCheapestDateSearchQuery(origin="PAR", destination="NYC")
            with pytest.raises(AppError) as exc_info:
                await search_flight_cheapest_dates(query)
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_ERROR"

    @pytest.mark.asyncio
    async def test_confirm_flight_price_error(self, mock_http_client):
        """Test confirm_flight_price error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_response.json.return_value = {"errors": [{"detail": "Invalid offer"}]}
        mock_http_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            # Minimal mock offer
            offer = FlightOffer(
                type="flight-offer",
                id="1",
                source="GDS",
                instantTicketingRequired=False,
                nonHomogeneous=False,
                itineraries=[],
                price={"currency": "EUR", "total": "100", "base": "100", "grandTotal": "100"},
                pricingOptions={"fareType": ["P"], "includedCheckedBagsOnly": True},
                validatingAirlineCodes=["AF"],
                travelerPricings=[],
            )
            with pytest.raises(AppError) as exc_info:
                await confirm_flight_price(offer)
            assert exc_info.value.status_code == 400
            assert exc_info.value.code == "INVALID_REQUEST"

    @pytest.mark.asyncio
    async def test_create_flight_order_error(self, mock_http_client):
        """Test create_flight_order error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_response.json.return_value = {"errors": [{"detail": "Invalid order"}]}
        mock_http_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            offer = FlightOffer(
                type="flight-offer",
                id="1",
                source="GDS",
                instantTicketingRequired=False,
                nonHomogeneous=False,
                itineraries=[],
                price={"currency": "EUR", "total": "100", "base": "100", "grandTotal": "100"},
                pricingOptions={"fareType": ["P"], "includedCheckedBagsOnly": True},
                validatingAirlineCodes=["AF"],
                travelerPricings=[],
            )
            with pytest.raises(AppError) as exc_info:
                await create_flight_order(offer, [])
            assert exc_info.value.status_code == 400
            assert exc_info.value.code == "INVALID_REQUEST"


class TestAmadeusHotels:
    """Tests for hotel-related functions."""

    @pytest.mark.asyncio
    async def test_search_hotel_list_error(self, mock_http_client):
        """Test search_hotel_list error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            query = HotelListSearchQuery(cityCode="PAR")
            with pytest.raises(AppError) as exc_info:
                await search_hotel_list(query)
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_ERROR"

    @pytest.mark.asyncio
    async def test_search_hotel_offers_error(self, mock_http_client):
        """Test search_hotel_offers error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.json.side_effect = Exception("not json")
        mock_http_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            query = HotelOffersSearchQuery(hotelIds="H1,H2")
            with pytest.raises(AppError) as exc_info:
                await search_hotel_offers(query)
            assert exc_info.value.status_code == 502
            assert exc_info.value.code == "UPSTREAM_ERROR"


class TestAmadeusClient:
    """Tests for the unified AmadeusClient class."""

    @pytest.mark.asyncio
    async def test_client_methods_call(self):
        """Test client methods delegate correctly."""
        client = AmadeusClient()

        # Locations are now handled by aviation_data (offline), not AmadeusClient.

        # Flights
        with patch(
            "src.integrations.amadeus.client.search_flight_offers", new_callable=AsyncMock
        ) as mock_impl:
            await client.search_flight_offers("query")
            mock_impl.assert_called_once()

        with patch(
            "src.integrations.amadeus.client.search_flight_destinations", new_callable=AsyncMock
        ) as mock_impl:
            await client.search_flight_destinations("query")
            mock_impl.assert_called_once()

        with patch(
            "src.integrations.amadeus.client.search_flight_cheapest_dates", new_callable=AsyncMock
        ) as mock_impl:
            await client.search_flight_cheapest_dates("query")
            mock_impl.assert_called_once()

        with patch(
            "src.integrations.amadeus.client.confirm_flight_price", new_callable=AsyncMock
        ) as mock_impl:
            await client.confirm_flight_price("offer")
            mock_impl.assert_called_once()

        with patch(
            "src.integrations.amadeus.client.create_flight_order", new_callable=AsyncMock
        ) as mock_impl:
            await client.create_flight_order("offer", [])
            mock_impl.assert_called_once()

        # Hotels
        with patch(
            "src.integrations.amadeus.client.search_hotel_list", new_callable=AsyncMock
        ) as mock_impl:
            query = HotelListSearchQuery(cityCode="PAR")
            await client.search_hotel_list(query)
            mock_impl.assert_called_once()

        with patch(
            "src.integrations.amadeus.client.search_hotel_offers", new_callable=AsyncMock
        ) as mock_impl:
            query = HotelOffersSearchQuery(hotelIds="H1")
            await client.search_hotel_offers(query)
            mock_impl.assert_called_once()
