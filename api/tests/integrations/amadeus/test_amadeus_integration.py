"""Unit tests for the Amadeus integration."""

import json
import time
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import httpx

from src.integrations.amadeus.client import AmadeusClient, amadeus_client
from src.integrations.amadeus.auth import fetch_token
from src.integrations.amadeus.flights import (
    search_flight_offers,
    search_flight_destinations,
    search_flight_cheapest_dates,
    confirm_flight_price,
    create_flight_order,
)
from src.integrations.amadeus.locations import (
    search_locations_by_keyword,
    search_location_by_id,
    search_location_nearest,
)
from src.integrations.amadeus.hotels import (
    search_hotel_offers,
    search_hotel_list_by_city,
    book_hotel,
)
from src.integrations.amadeus.types import (
    FlightOffer,
    FlightOrderTraveler,
    LocationKeywordSearchQuery,
    LocationIdSearchQuery,
    LocationNearestSearchQuery,
    FlightOfferSearchQuery,
    FlightInspirationSearchQuery,
    FlightCheapestDateSearchQuery,
)


@pytest.fixture
def mock_token():
    """Mock the fetch_token function."""
    with patch("src.integrations.amadeus.auth._token_cache", None):
        with patch("src.integrations.amadeus.auth.fetch_token", return_value="test_token") as mock:
            yield mock


@pytest.fixture
def mock_httpx_client():
    """Mock httpx.AsyncClient."""
    with patch("httpx.AsyncClient") as mock_client:
        mock_instance = AsyncMock()
        mock_client.return_value.__enter__.return_value = mock_instance
        mock_client.return_value.__aenter__.return_value = mock_instance
        yield mock_instance


class TestAmadeusAuth:
    """Tests for the Amadeus authentication."""

    @pytest.mark.asyncio
    async def test_fetch_token_success(self):
        """Test successful token retrieval."""
        with patch("src.integrations.amadeus.auth.settings") as mock_settings:
            mock_settings.AMADEUS_BASE_URL = "https://test.api.amadeus.com"
            mock_settings.AMADEUS_CLIENT_ID = "client_id"
            mock_settings.AMADEUS_CLIENT_SECRET = "client_secret"
            
            with patch("httpx.AsyncClient") as mock_client_cls:
                mock_client = AsyncMock()
                mock_client_cls.return_value.__aenter__.return_value = mock_client
                
                mock_response = MagicMock()
                mock_response.status_code = 200
                mock_response.json.return_value = {
                    "access_token": "new_token",
                    "expires_in": 1800,
                    "token_type": "Bearer"
                }
                mock_client.post.return_value = mock_response
                
                with patch("src.integrations.amadeus.auth._token_cache", None):
                    token = await fetch_token()
                    assert token == "new_token"
                    mock_client.post.assert_called_once()

    @pytest.mark.asyncio
    async def test_fetch_token_cached(self):
        """Test token retrieval from cache."""
        future_time = (time.time() + 1000) * 1000
        cache = {"access_token": "cached_token", "expires_at": future_time}
        
        with patch("src.integrations.amadeus.auth._token_cache", cache):
            token = await fetch_token()
            assert token == "cached_token"

    @pytest.mark.asyncio
    async def test_fetch_token_expired_cache(self):
        """Test token retrieval when cache is expired."""
        past_time = (time.time() - 1000) * 1000
        cache = {"access_token": "expired_token", "expires_at": past_time}
        
        with patch("src.integrations.amadeus.auth._token_cache", cache):
            with patch("src.integrations.amadeus.auth.settings"):
                with patch("httpx.AsyncClient") as mock_client_cls:
                    mock_client = AsyncMock()
                    mock_client_cls.return_value.__aenter__.return_value = mock_client
                    
                    mock_response = MagicMock()
                    mock_response.status_code = 200
                    mock_response.json.return_value = {"access_token": "fresh_token", "expires_in": 1800}
                    mock_client.post.return_value = mock_response
                    
                    token = await fetch_token()
                    assert token == "fresh_token"

    @pytest.mark.asyncio
    async def test_fetch_token_error(self):
        """Test token retrieval error handling."""
        with patch("src.integrations.amadeus.auth.settings"):
            with patch("httpx.AsyncClient") as mock_client_cls:
                mock_client = AsyncMock()
                mock_client_cls.return_value.__aenter__.return_value = mock_client
                
                mock_response = MagicMock()
                mock_response.status_code = 400
                mock_response.text = "Error"
                mock_client.post.return_value = mock_response
                
                with patch("src.integrations.amadeus.auth._token_cache", None):
                    with pytest.raises(Exception) as exc_info:
                        await fetch_token()
                    assert "Amadeus token error: 400" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_fetch_token_missing_token_in_response(self):
        """Test response with missing access_token."""
        with patch("src.integrations.amadeus.auth.settings"):
            with patch("httpx.AsyncClient") as mock_client_cls:
                mock_client = AsyncMock()
                mock_client_cls.return_value.__aenter__.return_value = mock_client
                
                mock_response = MagicMock()
                mock_response.status_code = 200
                mock_response.json.return_value = {"foo": "bar"}  # No access_token
                mock_client.post.return_value = mock_response
                
                with patch("src.integrations.amadeus.auth._token_cache", None):
                    with pytest.raises(Exception) as exc_info:
                        await fetch_token()
                    assert "missing access_token" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_fetch_token_http_error(self):
        """Test HTTP error during token fetch."""
        with patch("src.integrations.amadeus.auth.settings"):
            with patch("httpx.AsyncClient") as mock_client_cls:
                mock_client = AsyncMock()
                mock_client_cls.return_value.__aenter__.return_value = mock_client
                
                # Mock request object on exception
                mock_request = MagicMock()
                mock_request.url = "http://test.url"
                error = httpx.HTTPError("Network Error")
                error.request = mock_request
                mock_client.post.side_effect = error
                
                with patch("src.integrations.amadeus.auth._token_cache", None):
                    with pytest.raises(Exception) as exc_info:
                        await fetch_token()
                    assert "Amadeus token request failed" in str(exc_info.value)


class TestAmadeusLocations:
    """Tests for location-related functions."""

    @pytest.mark.asyncio
    async def test_search_locations_by_keyword(self, mock_httpx_client):
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
                    "address": {"cityName": "Paris", "cityCode": "PAR", "countryName": "France", "countryCode": "FR", "regionCode": "EU"}
                }
            ]
        }
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationKeywordSearchQuery(keyword="Paris", subType="CITY")
            locations = await search_locations_by_keyword(query)
            
            assert len(locations) == 1
            assert locations[0].name == "Paris"

    @pytest.mark.asyncio
    async def test_search_locations_by_keyword_error(self, mock_httpx_client):
        """Test search_locations_by_keyword error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationKeywordSearchQuery(keyword="Paris", subType="CITY")
            with pytest.raises(Exception) as exc_info:
                await search_locations_by_keyword(query)
            assert "Amadeus location search failed: 500" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_location_by_id(self, mock_httpx_client):
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
                "address": {"cityName": "Paris", "cityCode": "PAR", "countryName": "France", "countryCode": "FR", "regionCode": "EU"}
            }
        }
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            location = await search_location_by_id(query)
            
            assert location.id == "PAR"

    @pytest.mark.asyncio
    async def test_search_location_by_id_not_found(self, mock_httpx_client):
        """Test search_location_by_id with no data."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": None}
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            with pytest.raises(Exception) as exc_info:
                await search_location_by_id(query)
            assert "Location not found" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_location_by_id_http_error(self, mock_httpx_client):
        """Test search_location_by_id HTTP error."""
        mock_httpx_client.get.side_effect = httpx.HTTPError("Network Error")

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationIdSearchQuery(id="PAR")
            with pytest.raises(Exception) as exc_info:
                await search_location_by_id(query)
            assert "Amadeus location search failed" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_location_nearest(self, mock_httpx_client):
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
                    "address": {"cityName": "Paris", "cityCode": "PAR", "countryName": "France", "countryCode": "FR", "regionCode": "EU"}
                }
            ]
        }
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationNearestSearchQuery(latitude=49.0, longitude=2.5)
            locations = await search_location_nearest(query)
            
            assert len(locations) == 1
            assert locations[0].id == "CDG"

    @pytest.mark.asyncio
    async def test_search_location_nearest_error(self, mock_httpx_client):
        """Test search_location_nearest error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.locations.fetch_token", return_value="token"):
            query = LocationNearestSearchQuery(latitude=49.0, longitude=2.5)
            with pytest.raises(Exception) as exc_info:
                await search_location_nearest(query)
            assert "Amadeus location nearest search failed: 400" in str(exc_info.value)


class TestAmadeusFlights:
    """Tests for flight-related functions."""

    @pytest.mark.asyncio
    async def test_search_flight_offers_all_params(self, mock_httpx_client):
        """Test search_flight_offers with all optional parameters."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_httpx_client.get.return_value = mock_response

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
                includedAirlineCodes="AF,BA"
            )
            await search_flight_offers(query)
            
            # Check if all params were passed
            call_args = mock_httpx_client.get.call_args
            params = call_args[1]["params"]
            assert params["returnDate"] == "2025-12-20"
            assert params["children"] == 1
            assert params["includedAirlineCodes"] == "AF,BA"

    @pytest.mark.asyncio
    async def test_search_flight_offers_conflict_airlines(self, mock_httpx_client):
        """Test search_flight_offers with conflicting airline codes."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightOfferSearchQuery(
                originLocationCode="PAR",
                destinationLocationCode="NYC",
                departureDate="2025-12-15",
                adults=1,
                includedAirlineCodes="AF",
                excludedAirlineCodes="BA"
            )
            await search_flight_offers(query)
            
            # Check priority logic
            call_args = mock_httpx_client.get.call_args
            params = call_args[1]["params"]
            assert "includedAirlineCodes" in params
            assert "excludedAirlineCodes" not in params

    @pytest.mark.asyncio
    async def test_search_flight_offers_error(self, mock_httpx_client):
        """Test search_flight_offers error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Error"
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightOfferSearchQuery(originLocationCode="PAR", destinationLocationCode="NYC", departureDate="2025-12-15", adults=1)
            with pytest.raises(Exception) as exc_info:
                await search_flight_offers(query)
            assert "Amadeus flight offers search failed: 500" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_flight_destinations_all_params(self, mock_httpx_client):
        """Test search_flight_destinations with optional params."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightInspirationSearchQuery(
                origin="PAR",
                departureDate="2025-12-01",
                oneWay=True,
                duration=5,
                nonStop=True,
                maxPrice=500,
                viewBy="COUNTRY"
            )
            await search_flight_destinations(query)
            
            call_args = mock_httpx_client.get.call_args
            params = call_args[1]["params"]
            assert params["viewBy"] == "COUNTRY"

    @pytest.mark.asyncio
    async def test_search_flight_destinations_error(self, mock_httpx_client):
        """Test search_flight_destinations error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightInspirationSearchQuery(origin="PAR")
            with pytest.raises(Exception) as exc_info:
                await search_flight_destinations(query)
            assert "Amadeus flight destinations search failed: 400" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_flight_cheapest_dates(self, mock_httpx_client):
        """Test search_flight_cheapest_dates."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"data": []}
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightCheapestDateSearchQuery(origin="PAR", destination="NYC")
            await search_flight_cheapest_dates(query)
            mock_httpx_client.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_search_flight_cheapest_dates_error(self, mock_httpx_client):
        """Test search_flight_cheapest_dates error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            query = FlightCheapestDateSearchQuery(origin="PAR", destination="NYC")
            with pytest.raises(Exception) as exc_info:
                await search_flight_cheapest_dates(query)
            assert "Amadeus flight cheapest dates search failed: 500" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_confirm_flight_price_error(self, mock_httpx_client):
        """Test confirm_flight_price error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_httpx_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            # Minimal mock offer
            offer = FlightOffer(type="flight-offer", id="1", source="GDS", instantTicketingRequired=False, nonHomogeneous=False, itineraries=[], price={"currency": "EUR", "total": "100", "base": "100", "grandTotal": "100"}, pricingOptions={"fareType": ["P"], "includedCheckedBagsOnly": True}, validatingAirlineCodes=["AF"], travelerPricings=[])
            with pytest.raises(Exception) as exc_info:
                await confirm_flight_price(offer)
            assert "Amadeus flight price confirmation failed: 400" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_create_flight_order_error(self, mock_httpx_client):
        """Test create_flight_order error."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        mock_httpx_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.flights.fetch_token", return_value="token"):
            offer = FlightOffer(type="flight-offer", id="1", source="GDS", instantTicketingRequired=False, nonHomogeneous=False, itineraries=[], price={"currency": "EUR", "total": "100", "base": "100", "grandTotal": "100"}, pricingOptions={"fareType": ["P"], "includedCheckedBagsOnly": True}, validatingAirlineCodes=["AF"], travelerPricings=[])
            with pytest.raises(Exception) as exc_info:
                await create_flight_order(offer, [])
            assert "Amadeus flight order creation failed: 400" in str(exc_info.value)


class TestAmadeusHotels:
    """Tests for hotel-related functions."""

    @pytest.mark.asyncio
    async def test_search_hotel_list_by_city_error(self, mock_httpx_client):
        """Test search_hotel_list_by_city error."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_httpx_client.get.return_value = mock_response

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            with pytest.raises(Exception) as exc_info:
                await search_hotel_list_by_city("PAR")
            assert "Amadeus hotel list by city failed: 500" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_search_hotel_offers_fallback(self, mock_httpx_client):
        """Test search_hotel_offers fallback logic."""
        # 1. search_hotel_list_by_city fails
        mock_list_response = MagicMock()
        mock_list_response.status_code = 500
        
        # 2. search_hotel_offers uses lat/long fallback
        mock_offers_response = MagicMock()
        mock_offers_response.status_code = 200
        mock_offers_response.json.return_value = {"data": []}
        
        mock_httpx_client.get.side_effect = [mock_list_response, mock_offers_response]

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            # Provide both city code and coordinates
            await search_hotel_offers(city_code="PAR", latitude=48.8, longitude=2.3)
            
            # Check that second call used lat/long
            call_args = mock_httpx_client.get.call_args
            params = call_args[1]["params"]
            assert "latitude" in params
            assert "hotelIds" not in params

    @pytest.mark.asyncio
    async def test_search_hotel_offers_no_params_error(self, mock_httpx_client):
        """Test search_hotel_offers raises error if insufficient params."""
        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            with pytest.raises(ValueError) as exc_info:
                await search_hotel_offers()
            assert "Either city_code" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_book_hotel_retry_401(self, mock_httpx_client):
        """Test book_hotel retries on 401."""
        # First call 401, second call 201
        response_401 = MagicMock()
        response_401.status_code = 401
        
        response_201 = MagicMock()
        response_201.status_code = 201
        response_201.json.return_value = {"data": [{"id": "123"}]}
        
        mock_httpx_client.post.side_effect = [response_401, response_201]

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            guests = [{"name": {"firstName": "John", "lastName": "Doe"}}]
            result = await book_hotel("offer1", "H1", guests)
            assert result["data"][0]["id"] == "123"
            assert mock_httpx_client.post.call_count == 2

    @pytest.mark.asyncio
    async def test_book_hotel_404_error(self, mock_httpx_client):
        """Test book_hotel 404 handling."""
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_response.text = "Not Found"
        mock_response.json.return_value = {"errors": [{"code": 38196, "detail": "Offer doesn't exist"}]}
        mock_httpx_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            guests = [{"name": {"firstName": "John", "lastName": "Doe"}}]
            with pytest.raises(Exception) as exc_info:
                await book_hotel("offer1", "H1", guests)
            assert "Amadeus hotel booking failed: 404" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_book_hotel_payments(self, mock_httpx_client):
        """Test book_hotel with payments."""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_response.json.return_value = {"data": []}
        mock_httpx_client.post.return_value = mock_response

        with patch("src.integrations.amadeus.hotels.fetch_token", return_value="token"):
            guests = [{"name": {"firstName": "John", "lastName": "Doe"}}]
            payments = [{"method": "CREDIT_CARD"}]
            await book_hotel("offer1", "H1", guests, payments)
            
            call_args = mock_httpx_client.post.call_args
            body = call_args[1]["json"]
            assert "payments" in body["data"]
            assert body["data"]["rooms"][0]["paymentId"] == 1


class TestAmadeusClient:
    """Tests for the unified AmadeusClient class."""

    @pytest.mark.asyncio
    async def test_client_methods_call(self):
        """Test client methods delegate correctly."""
        client = AmadeusClient()
        
        # Test all methods are delegated
        
        # Locations
        with patch("src.integrations.amadeus.client.search_locations_by_keyword", new_callable=AsyncMock) as mock_impl:
            await client.search_locations_by_keyword("query")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.search_location_by_id", new_callable=AsyncMock) as mock_impl:
            await client.search_location_by_id("query")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.search_location_nearest", new_callable=AsyncMock) as mock_impl:
            await client.search_location_nearest("query")
            mock_impl.assert_called_once()
            
        # Flights
        with patch("src.integrations.amadeus.client.search_flight_offers", new_callable=AsyncMock) as mock_impl:
            await client.search_flight_offers("query")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.search_flight_destinations", new_callable=AsyncMock) as mock_impl:
            await client.search_flight_destinations("query")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.search_flight_cheapest_dates", new_callable=AsyncMock) as mock_impl:
            await client.search_flight_cheapest_dates("query")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.confirm_flight_price", new_callable=AsyncMock) as mock_impl:
            await client.confirm_flight_price("offer")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.create_flight_order", new_callable=AsyncMock) as mock_impl:
            await client.create_flight_order("offer", [])
            mock_impl.assert_called_once()
            
        # Hotels
        with patch("src.integrations.amadeus.client.search_hotel_offers", new_callable=AsyncMock) as mock_impl:
            await client.search_hotel_offers(city_code="PAR")
            mock_impl.assert_called_once()
            
        with patch("src.integrations.amadeus.client.book_hotel", new_callable=AsyncMock) as mock_impl:
            await client.book_hotel("offer", "hotel", [])
            mock_impl.assert_called_once()

