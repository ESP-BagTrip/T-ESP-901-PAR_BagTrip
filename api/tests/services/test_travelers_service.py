"""Unit tests for TravelersService."""

import uuid
from datetime import date
from unittest.mock import MagicMock

import pytest

from src.models.traveler import TripTraveler
from src.services.travelers_service import TravelersService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestTravelersService:
    """Tests for TravelersService."""

    def test_create_traveler_success(self, mock_db_session):
        """Test successful traveler creation."""
        trip_id = uuid.uuid4()

        traveler = TravelersService.create_traveler(
            mock_db_session,
            trip_id,
            amadeus_traveler_ref="1",
            traveler_type="ADULT",
            first_name="John",
            last_name="Doe",
        )

        assert traveler.first_name == "John"
        mock_db_session.add.assert_called_once()
        mock_db_session.commit.assert_called_once()

    def test_get_travelers_by_trip(self, mock_db_session):
        """Test retrieving travelers by trip."""
        trip_id = uuid.uuid4()

        mock_travelers = [TripTraveler(id=uuid.uuid4())]
        mock_db_session.query.return_value.filter.return_value.all.return_value = mock_travelers

        result = TravelersService.get_travelers_by_trip(mock_db_session, trip_id)
        assert len(result) == 1

    def test_get_traveler_by_id(self, mock_db_session):
        """Test retrieving traveler by ID."""
        trip_id = uuid.uuid4()
        traveler_id = uuid.uuid4()

        mock_traveler = TripTraveler(id=traveler_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_traveler

        result = TravelersService.get_traveler_by_id(mock_db_session, traveler_id, trip_id)
        assert result == mock_traveler

    def test_update_traveler_success(self, mock_db_session):
        """Test successful traveler update."""
        mock_traveler = TripTraveler(id=uuid.uuid4(), first_name="Old")
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_traveler

        result = TravelersService.update_traveler(
            mock_db_session, mock_traveler.id, uuid.uuid4(), first_name="New"
        )

        assert result.first_name == "New"
        mock_db_session.commit.assert_called_once()

    def test_update_traveler_not_found(self, mock_db_session):
        """Test error when traveler not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            TravelersService.update_traveler(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "TRAVELER_NOT_FOUND"

    def test_delete_traveler_success(self, mock_db_session):
        """Test successful traveler deletion."""
        mock_traveler = TripTraveler(id=uuid.uuid4())
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_traveler

        TravelersService.delete_traveler(mock_db_session, mock_traveler.id, uuid.uuid4())

        mock_db_session.delete.assert_called_once_with(mock_traveler)
        mock_db_session.commit.assert_called_once()

    def test_delete_traveler_not_found(self, mock_db_session):
        """Test error when traveler not found during deletion."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            TravelersService.delete_traveler(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "TRAVELER_NOT_FOUND"

    def test_traveler_to_amadeus_payload(self):
        """Test payload conversion."""
        traveler = TripTraveler(
            id=uuid.uuid4(),
            amadeus_traveler_ref="1",
            first_name="John",
            last_name="Doe",
            date_of_birth=date(1990, 1, 1),
            gender="MALE",
            contacts={"phoneNumber": "+33612345678", "emailAddress": "test@test.com"},
            documents=[{"number": "123", "issuanceCountry": "FR"}],
        )

        payload = TravelersService.traveler_to_amadeus_payload(traveler)

        assert payload["id"] == "1"
        assert payload["name"]["firstName"] == "John"
        assert payload["contact"]["phones"][0]["countryCallingCode"] == "33"
        assert payload["contact"]["phones"][0]["number"] == "612345678"
        assert payload["documents"][0]["validityCountry"] == "FR"
