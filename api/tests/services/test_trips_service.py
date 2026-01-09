"""Unit tests for TripsService."""

import uuid
from unittest.mock import MagicMock

import pytest

from src.models.trip import Trip
from src.services.trips_service import TripsService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestTripsService:
    """Tests for TripsService."""

    def test_create_trip(self, mock_db_session):
        """Test creating a trip."""
        user_id = uuid.uuid4()
        
        trip = TripsService.create_trip(
            mock_db_session, user_id, "Title", "PAR", "NYC"
        )
        
        assert trip.title == "Title"
        assert trip.user_id == user_id
        mock_db_session.add.assert_called_once()
        mock_db_session.commit.assert_called_once()

    def test_get_trips_by_user(self, mock_db_session):
        """Test retrieving trips by user."""
        user_id = uuid.uuid4()
        mock_trips = [Trip(id=uuid.uuid4())]
        mock_db_session.query.return_value.filter.return_value.order_by.return_value.all.return_value = mock_trips
        
        result = TripsService.get_trips_by_user(mock_db_session, user_id)
        assert len(result) == 1

    def test_get_trip_by_id(self, mock_db_session):
        """Test retrieving trip by ID."""
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()
        mock_trip = Trip(id=trip_id)
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_trip
        
        result = TripsService.get_trip_by_id(mock_db_session, trip_id, user_id)
        assert result == mock_trip

    def test_update_trip_success(self, mock_db_session):
        """Test successful trip update."""
        trip = Trip(id=uuid.uuid4(), title="Old")
        mock_db_session.query.return_value.filter.return_value.first.return_value = trip
        
        result = TripsService.update_trip(
            mock_db_session, trip.id, uuid.uuid4(), title="New"
        )
        
        assert result.title == "New"
        mock_db_session.commit.assert_called_once()

    def test_update_trip_not_found(self, mock_db_session):
        """Test error when trip not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        with pytest.raises(AppError) as exc:
            TripsService.update_trip(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), title="New"
            )
        assert exc.value.code == "TRIP_NOT_FOUND"

    def test_delete_trip_success(self, mock_db_session):
        """Test successful trip deletion."""
        trip = Trip(id=uuid.uuid4())
        mock_db_session.query.return_value.filter.return_value.first.return_value = trip
        
        TripsService.delete_trip(mock_db_session, trip.id, uuid.uuid4())
        
        mock_db_session.delete.assert_called_once_with(trip)
        mock_db_session.commit.assert_called_once()

    def test_delete_trip_not_found(self, mock_db_session):
        """Test error when trip not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        with pytest.raises(AppError) as exc:
            TripsService.delete_trip(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "TRIP_NOT_FOUND"
