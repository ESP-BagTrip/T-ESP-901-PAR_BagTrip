"""Unit tests for AdminService."""

import uuid
from datetime import datetime, timezone
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
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )

        # Configure mock query
        mock_query = mock_db_session.query.return_value
        mock_query.order_by.return_value.count.return_value = 1
        mock_query.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [user]

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
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [(trip, user_email)]

        items, total, total_pages = AdminService.get_all_trips(mock_db_session)

        assert len(items) == 1
        assert items[0]["user_email"] == "test@example.com"
        assert items[0]["title"] == "Paris Trip"

    def test_get_all_travelers(self, mock_db_session):
        """Test retrieving all travelers."""
        traveler = TripTraveler(
            id=uuid.uuid4(),
            trip_id=uuid.uuid4(),
            first_name="John",
            last_name="Doe",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        trip_title = "Paris Trip"
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [(traveler, trip_title, user_email)]

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
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        trip_title = "Paris Trip"
        user_email = "test@example.com"

        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [(order, trip_title, user_email)]

        items, total, total_pages = AdminService.get_all_flight_bookings(mock_db_session)

        assert len(items) == 1
        assert items[0]["status"] == "CONFIRMED"
        assert items[0]["user_email"] == "test@example.com"

    def test_get_dashboard_metrics(self, mock_db_session):
        """Test retrieving dashboard metrics."""
        mock_db_session.query.return_value.scalar.return_value = 10  # total users
        mock_db_session.query.return_value.filter.return_value.scalar.return_value = 5  # active users
        # For multiple calls, we should use side_effect if we want specific values, 
        # but here the scalar() is called multiple times on different queries.
        mock_db_session.query.return_value.scalar.side_effect = [10, 5, 20, 100.0, 30]
        mock_db_session.query.return_value.scalar.return_value = 10 # fallback

        metrics = AdminService.get_dashboard_metrics(mock_db_session)
        assert "totalUsers" in metrics
        assert "totalTrips" in metrics
        assert "totalRevenue" in metrics

    def test_update_user_plan(self, mock_db_session):
        """Test updating a user's plan."""
        user = User(id=uuid.uuid4(), email="test@example.com", plan="FREE")
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        AdminService.update_user_plan(mock_db_session, user.id, "PREMIUM")

        assert user.plan == "PREMIUM"
        assert mock_db_session.commit.called

    def test_update_user_plan_invalid(self, mock_db_session):
        """Test updating a user's plan with invalid value."""
        user = User(id=uuid.uuid4(), email="test@example.com", plan="FREE")
        mock_db_session.query.return_value.filter.return_value.first.return_value = user

        with pytest.raises(AppError) as exc:
            AdminService.update_user_plan(mock_db_session, user.id, "INVALID")
        assert exc.value.code == "INVALID_PLAN"

    def test_export_users_csv(self, mock_db_session):
        """Test exporting users to CSV."""
        user = User(
            id=uuid.uuid4(),
            email="test@example.com",
            plan="FREE",
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        mock_db_session.query.return_value.order_by.return_value.all.return_value = [user]

        csv_content = AdminService.export_users_csv(mock_db_session)
        assert "test@example.com" in csv_content
        assert "FREE" in csv_content

    def test_get_all_accommodations(self, mock_db_session):
        """Test retrieving all accommodations."""
        from src.models.accommodation import Accommodation
        acc = Accommodation(id=uuid.uuid4(), trip_id=uuid.uuid4(), name="Hotel")
        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [(acc, "Trip", "user@example.com")]
        items, _, _ = AdminService.get_all_accommodations(mock_db_session)
        assert len(items) == 1
        assert items[0]["name"] == "Hotel"

    def test_get_all_activities(self, mock_db_session):
        """Test retrieving all activities."""
        from src.models.activity import Activity
        act = Activity(id=uuid.uuid4(), trip_id=uuid.uuid4(), title="Visit")
        mock_query = mock_db_session.query.return_value
        mock_query.join.return_value.join.return_value.order_by.return_value.count.return_value = 1
        mock_query.join.return_value.join.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [(act, "Trip", "user@example.com")]
        items, _, _ = AdminService.get_all_activities(mock_db_session)
        assert len(items) == 1
        assert items[0]["title"] == "Visit"
