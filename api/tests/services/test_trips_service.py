"""Unit tests for TripsService."""

import uuid
from unittest.mock import MagicMock

import pytest

from src.enums import TripStatus
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
        """Test creating a trip — adds Trip + TripTraveler (owner auto-added)."""
        user_id = uuid.uuid4()

        # Mock the user query used to get the owner's name
        mock_user = MagicMock()
        mock_user.full_name = "John Doe"
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_user

        trip = TripsService.create_trip(mock_db_session, user_id, "Title", "PAR", "NYC")

        assert trip.title == "Title"
        assert trip.user_id == user_id
        # Service calls db.add twice: once for Trip, once for the owner TripTraveler
        assert mock_db_session.add.call_count == 2
        mock_db_session.commit.assert_called_once()

    def test_get_trips_by_user(self, mock_db_session):
        """Test retrieving trips by user — uses union_all."""
        user_id = uuid.uuid4()
        mock_trips = [(Trip(id=uuid.uuid4()), "OWNER")]

        # get_trips_by_user uses union_all then order_by then all
        mock_db_session.query.return_value.filter.return_value.union_all.return_value.order_by.return_value.all.return_value = mock_trips

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
        """Test successful trip update — accepts Trip object directly."""
        trip = Trip(id=uuid.uuid4(), title="Old")

        result = TripsService.update_trip(mock_db_session, trip, title="New")

        assert result.title == "New"
        mock_db_session.commit.assert_called_once()

    def test_update_trip_completed_raises(self, mock_db_session):
        """Test error when trying to modify a completed trip."""
        trip = Trip(id=uuid.uuid4(), title="Old")
        trip.status = TripStatus.COMPLETED

        with pytest.raises(AppError) as exc:
            TripsService.update_trip(mock_db_session, trip, title="New")
        assert exc.value.code == "TRIP_COMPLETED"

    def test_delete_trip_success(self, mock_db_session):
        """Test successful trip deletion — accepts Trip object directly."""
        trip = Trip(id=uuid.uuid4())
        trip.status = TripStatus.DRAFT

        # Mock the confirmed-flight query to return None
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        # Mock the subquery / bulk-update calls used for StripeEvent nullification
        mock_db_session.query.return_value.filter.return_value.subquery.return_value = MagicMock()
        mock_db_session.query.return_value.filter.return_value.update.return_value = 0
        mock_db_session.query.return_value.filter.return_value.delete.return_value = 0

        TripsService.delete_trip(mock_db_session, trip)

        mock_db_session.delete.assert_called_once_with(trip)
        mock_db_session.commit.assert_called_once()

    def test_delete_trip_not_draft_raises(self, mock_db_session):
        """Test error when trip is not in DRAFT status."""
        trip = Trip(id=uuid.uuid4())
        trip.status = TripStatus.PLANNED

        with pytest.raises(AppError) as exc:
            TripsService.delete_trip(mock_db_session, trip)
        assert exc.value.code == "TRIP_NOT_DRAFT"
