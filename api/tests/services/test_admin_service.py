"""Unit tests for AdminService."""

import uuid
from datetime import datetime
from unittest.mock import MagicMock

import pytest

from src.models.flight_order import FlightOrder
from src.models.traveler import TripTraveler
from src.models.trip import Trip
from src.models.user import User
from src.services.admin_service import AdminService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestAdminService:
    """Tests for AdminService."""

    def test_get_all_users(self, mock_db_session):
        """Test retrieving all users."""
        # Setup mock data
        user = User(
            id=uuid.uuid4(),
            email="test@example.com",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        # Configure mock query
        mock_query = mock_db_session.query.return_value
        mock_query.order_by.return_value.count.return_value = 1
        mock_query.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [
            user
        ]

        # Call service
        items, total, total_pages = AdminService.get_all_users(mock_db_session, page=1, limit=10)

        # Assertions
        assert len(items) == 1
        assert total == 1
        assert total_pages == 1
        assert items[0]["email"] == "test@example.com"

        # Verify pagination logic (limit=0 case)
        items, total, total_pages = AdminService.get_all_users(mock_db_session, limit=0)
        assert total_pages == 0

    def test_get_all_trips(self, mock_db_session):
        """Test retrieving all trips."""
        trip = Trip(
            id=uuid.uuid4(),
            user_id=uuid.uuid4(),
            title="Paris Trip",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [
            (trip, user_email)
        ]

        items, total, total_pages = AdminService.get_all_trips(mock_db_session)

        assert len(items) == 1
        assert items[0]["user_email"] == "test@example.com"
        assert items[0]["title"] == "Paris Trip"

    def test_archive_trip_sets_archived_at(self, mock_db_session):
        """archive_trip stamps archived_at without touching sub-entities."""
        trip = Trip(id=uuid.uuid4(), user_id=uuid.uuid4(), archived_at=None)
        mock_db_session.query.return_value.filter.return_value.first.return_value = trip

        AdminService.archive_trip(mock_db_session, trip.id)

        assert trip.archived_at is not None
        mock_db_session.commit.assert_called_once()
        # Soft-archive must never hard-delete the trip / sub-entities.
        mock_db_session.delete.assert_not_called()

    def test_archive_trip_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            AdminService.archive_trip(mock_db_session, uuid.uuid4())
        assert exc.value.status_code == 404

    def test_unarchive_trip_clears_archived_at(self, mock_db_session):
        """unarchive_trip reverses the archive by clearing archived_at."""
        trip = Trip(id=uuid.uuid4(), user_id=uuid.uuid4(), archived_at=datetime.utcnow())
        mock_db_session.query.return_value.filter.return_value.first.return_value = trip

        AdminService.unarchive_trip(mock_db_session, trip.id)

        assert trip.archived_at is None
        mock_db_session.commit.assert_called_once()
        mock_db_session.delete.assert_not_called()

    def test_unarchive_trip_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            AdminService.unarchive_trip(mock_db_session, uuid.uuid4())
        assert exc.value.status_code == 404

    def test_get_all_travelers(self, mock_db_session):
        """Test retrieving all travelers."""
        traveler = TripTraveler(
            id=uuid.uuid4(),
            trip_id=uuid.uuid4(),
            first_name="John",
            last_name="Doe",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        trip_title = "Paris Trip"
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [
            (traveler, trip_title, user_email)
        ]

        items, total, total_pages = AdminService.get_all_travelers(mock_db_session)

        assert len(items) == 1
        assert items[0]["first_name"] == "John"
        assert items[0]["trip_title"] == "Paris Trip"
        assert items[0]["user_email"] == "test@example.com"

    def test_get_all_flight_bookings(self, mock_db_session):
        """Test retrieving all flight bookings."""
        order = FlightOrder(
            id=uuid.uuid4(),
            trip_id=uuid.uuid4(),
            flight_offer_id=uuid.uuid4(),
            status="CONFIRMED",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        trip_title = "Paris Trip"
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [
            (order, trip_title, user_email)
        ]

        items, total, total_pages = AdminService.get_all_flight_bookings(mock_db_session)

        assert len(items) == 1
        assert items[0]["status"] == "CONFIRMED"
        assert items[0]["user_email"] == "test@example.com"
