"""Unit tests for TravelersService."""

from unittest.mock import MagicMock, patch
from uuid import uuid4
from datetime import date

import pytest
from src.models.traveler import TripTraveler
from src.services.travelers_service import TravelersService
from src.utils.errors import AppError


@pytest.fixture
def mock_db():
    return MagicMock()

@pytest.fixture
def mock_trip():
    return MagicMock(id=uuid4(), user_id=uuid4())

@pytest.fixture
def mock_traveler(mock_trip):
    return TripTraveler(
        id=uuid4(),
        trip_id=mock_trip.id,
        first_name="John",
        last_name="Doe",
        traveler_type="ADULT",
        date_of_birth=date(1990, 1, 1),
        gender="MALE",
        contacts={"emailAddress": "john.doe@example.com", "phoneNumber": "0612345678"},
        documents=[],
        amadeus_traveler_ref="1"
    )

class TestTravelersService:

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_create_traveler_success(self, mock_get_trip, mock_db, mock_trip):
        mock_get_trip.return_value = mock_trip
        
        user_id = mock_trip.user_id
        trip_id = mock_trip.id
        
        traveler = TravelersService.create_traveler(
            db=mock_db,
            trip_id=trip_id,
            user_id=user_id,
            amadeus_traveler_ref="1",
            traveler_type="ADULT",
            first_name="John",
            last_name="Doe"
        )
        
        mock_get_trip.assert_called_once_with(mock_db, trip_id, user_id)
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()
        assert traveler.first_name == "John"
        assert traveler.last_name == "Doe"

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_create_traveler_trip_not_found(self, mock_get_trip, mock_db):
        mock_get_trip.return_value = None
        
        with pytest.raises(AppError) as exc:
            TravelersService.create_traveler(
                db=mock_db,
                trip_id=uuid4(),
                user_id=uuid4(),
                amadeus_traveler_ref="1",
                traveler_type="ADULT",
                first_name="John",
                last_name="Doe"
            )
        assert exc.value.status_code == 404
        assert exc.value.code == "TRIP_NOT_FOUND"

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_get_travelers_by_trip_success(self, mock_get_trip, mock_db, mock_trip):
        mock_get_trip.return_value = mock_trip
        mock_db.query.return_value.filter.return_value.all.return_value = ["traveler1", "traveler2"]
        
        result = TravelersService.get_travelers_by_trip(mock_db, mock_trip.id, mock_trip.user_id)
        
        assert len(result) == 2
        mock_get_trip.assert_called_once()

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_get_travelers_by_trip_not_found(self, mock_get_trip, mock_db):
        mock_get_trip.return_value = None
        
        with pytest.raises(AppError) as exc:
            TravelersService.get_travelers_by_trip(mock_db, uuid4(), uuid4())
        assert exc.value.code == "TRIP_NOT_FOUND"

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_get_traveler_by_id_success(self, mock_get_trip, mock_db, mock_trip, mock_traveler):
        mock_get_trip.return_value = mock_trip
        mock_db.query.return_value.filter.return_value.first.return_value = mock_traveler
        
        result = TravelersService.get_traveler_by_id(mock_db, mock_traveler.id, mock_trip.id, mock_trip.user_id)
        
        assert result == mock_traveler
        mock_get_trip.assert_called_once()

    @patch("src.services.travelers_service.TripsService.get_trip_by_id")
    def test_get_traveler_by_id_trip_not_found(self, mock_get_trip, mock_db):
        mock_get_trip.return_value = None
        
        with pytest.raises(AppError) as exc:
            TravelersService.get_traveler_by_id(mock_db, uuid4(), uuid4(), uuid4())
        assert exc.value.code == "TRIP_NOT_FOUND"

    @patch("src.services.travelers_service.TravelersService.get_traveler_by_id")
    def test_update_traveler_success(self, mock_get_traveler, mock_db, mock_traveler):
        mock_get_traveler.return_value = mock_traveler
        
        updated = TravelersService.update_traveler(
            db=mock_db,
            traveler_id=mock_traveler.id,
            trip_id=mock_traveler.trip_id,
            user_id=uuid4(),
            first_name="Jane"
        )
        
        assert updated.first_name == "Jane"
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()

    @patch("src.services.travelers_service.TravelersService.get_traveler_by_id")
    def test_update_traveler_not_found(self, mock_get_traveler, mock_db):
        mock_get_traveler.return_value = None
        
        with pytest.raises(AppError) as exc:
            TravelersService.update_traveler(mock_db, uuid4(), uuid4(), uuid4(), first_name="Jane")
        assert exc.value.code == "TRAVELER_NOT_FOUND"

    @patch("src.services.travelers_service.TravelersService.get_traveler_by_id")
    def test_delete_traveler_success(self, mock_get_traveler, mock_db, mock_traveler):
        mock_get_traveler.return_value = mock_traveler
        
        TravelersService.delete_traveler(mock_db, mock_traveler.id, mock_traveler.trip_id, uuid4())
        
        mock_db.delete.assert_called_once_with(mock_traveler)
        mock_db.commit.assert_called_once()

    @patch("src.services.travelers_service.TravelersService.get_traveler_by_id")
    def test_delete_traveler_not_found(self, mock_get_traveler, mock_db):
        mock_get_traveler.return_value = None
        
        with pytest.raises(AppError) as exc:
            TravelersService.delete_traveler(mock_db, uuid4(), uuid4(), uuid4())
        assert exc.value.code == "TRAVELER_NOT_FOUND"

    def test_traveler_to_amadeus_payload(self, mock_traveler):
        payload = TravelersService.traveler_to_amadeus_payload(mock_traveler)
        
        assert payload["name"]["firstName"] == "John"
        assert payload["name"]["lastName"] == "Doe"
        assert payload["contact"]["phones"][0]["countryCallingCode"] == "33"
        assert payload["contact"]["phones"][0]["number"] == "612345678"
        
        # Test international format
        mock_traveler.contacts["phoneNumber"] = "+15550199"
        payload = TravelersService.traveler_to_amadeus_payload(mock_traveler)
        assert payload["contact"]["phones"][0]["countryCallingCode"] == "1"
        assert payload["contact"]["phones"][0]["number"] == "5550199"
        
        # Test 00 format
        mock_traveler.contacts["phoneNumber"] = "00447700900000"
        payload = TravelersService.traveler_to_amadeus_payload(mock_traveler)
        assert payload["contact"]["phones"][0]["countryCallingCode"] == "44"
        assert payload["contact"]["phones"][0]["number"] == "7700900000"

