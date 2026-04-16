"""Unit tests for Amadeus types."""

import pytest
from pydantic import ValidationError

from src.integrations.amadeus.types import (
    FlightInspirationSearchQuery,
    FlightOfferSearchQuery,
    FlightOrderTraveler,
    HotelListSearchQuery,
    Location,
    LocationKeywordSearchQuery,
    LocationNearestSearchQuery,
)


class TestAmadeusTypes:
    """Tests for the Amadeus Pydantic models."""

    def test_location_keyword_search_query_valid(self):
        """Test LocationKeywordSearchQuery with valid data."""
        data = {"subType": "CITY", "keyword": "paris"}
        query = LocationKeywordSearchQuery(**data)
        assert query.subType == "CITY"
        assert query.keyword == "paris"

    def test_location_keyword_search_query_missing_field(self):
        """Test LocationKeywordSearchQuery with missing field."""
        with pytest.raises(ValidationError):
            LocationKeywordSearchQuery(subType="CITY")

    def test_location_nearest_search_query_valid(self):
        """Test LocationNearestSearchQuery with valid data."""
        data = {"latitude": 48.8566, "longitude": 2.3522}
        query = LocationNearestSearchQuery(**data)
        assert query.latitude == 48.8566
        assert query.longitude == 2.3522

    def test_location_valid(self):
        """Test Location with valid data."""
        data = {
            "type": "location",
            "subType": "CITY",
            "name": "PARIS",
            "detailedName": "PARIS/FR",
            "id": "PCAR",
            "self": {"href": "https://api.amadeus.com/v1/locations/PCAR", "methods": ["GET"]},
            "timeZoneOffset": "+01:00",
            "iataCode": "PAR",
            "geoCode": {"latitude": 48.8566, "longitude": 2.3522},
            "address": {
                "cityName": "PARIS",
                "cityCode": "PAR",
                "countryName": "FRANCE",
                "countryCode": "FR",
                "regionCode": "EU",
            },
            "analytics": {"travelers": {"score": 100}},
        }
        location = Location(**data)
        assert location.name == "PARIS"
        assert location.self_.href == "https://api.amadeus.com/v1/locations/PCAR"
        assert location.geoCode.latitude == 48.8566

    def test_flight_offer_search_query_valid(self):
        """Test FlightOfferSearchQuery with valid data."""
        data = {
            "originLocationCode": "CDG",
            "destinationLocationCode": "JFK",
            "departureDate": "2025-12-25",
            "adults": 1,
        }
        query = FlightOfferSearchQuery(**data)
        assert query.originLocationCode == "CDG"
        assert query.adults == 1

    def test_flight_offer_search_query_invalid_adults(self):
        """Test FlightOfferSearchQuery with invalid adults (should fail if validated)."""
        data = {
            "originLocationCode": "CDG",
            "destinationLocationCode": "JFK",
            "departureDate": "2025-12-25",
            "adults": "not-an-int",
        }
        with pytest.raises(ValidationError):
            FlightOfferSearchQuery(**data)

    def test_flight_inspiration_search_query_valid(self):
        """Test FlightInspirationSearchQuery with valid data."""
        data = {
            "origin": "PAR",
            "departureDate": "2025-12-25",
            "maxPrice": 500,
        }
        query = FlightInspirationSearchQuery(**data)
        assert query.origin == "PAR"
        assert query.maxPrice == 500

    def test_hotel_list_search_query_valid(self):
        """Test HotelListSearchQuery with valid data."""
        data = {
            "cityCode": "PAR",
            "radius": 5,
            "radiusUnit": "KM",
        }
        query = HotelListSearchQuery(**data)
        assert query.cityCode == "PAR"
        assert query.radius == 5

    def test_flight_order_traveler_valid(self):
        """Test FlightOrderTraveler with valid data."""
        data = {
            "id": "1",
            "dateOfBirth": "1990-01-01",
            "name": {"firstName": "John", "lastName": "Doe"},
            "gender": "MALE",
            "contact": {
                "emailAddress": "john@example.com",
                "phones": [
                    {"countryCallingCode": "33", "number": "612345678"}
                ],
            },
        }
        traveler = FlightOrderTraveler(**data)
        assert traveler.name.firstName == "John"
        assert traveler.gender == "MALE"
