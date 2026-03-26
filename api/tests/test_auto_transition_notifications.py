"""Tests for auto_transition_statuses TRIP_STARTED notifications."""

from datetime import UTC, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4

from src.enums import NotificationType, TripStatus


def _make_trip(status, start_date=None, end_date=None, title="Test Trip"):
    """Create a mock Trip with the given attributes."""
    trip = MagicMock()
    trip.id = uuid4()
    trip.user_id = uuid4()
    trip.title = title
    trip.status = status
    trip.start_date = start_date
    trip.end_date = end_date
    return trip


def _setup_db(starting_trips=None, completing_trips=None):
    """Create a mock DB that returns the given trips for the two filter().all() calls."""
    starting_trips = starting_trips or []
    completing_trips = completing_trips or []

    db = MagicMock()

    # Each db.query(Trip) returns a new chain mock, but we need to
    # control the .filter().all() results in order.
    query_results = iter([starting_trips, completing_trips])

    def make_query_chain(*args, **kwargs):
        chain = MagicMock()
        chain.filter.return_value.all.return_value = next(query_results, [])
        return chain

    db.query.side_effect = make_query_chain
    db.execute.return_value.rowcount = 0

    return db


def test_trip_started_notification_sent_on_planned_to_ongoing():
    """TRIP_STARTED notification is sent when a trip transitions PLANNED→ONGOING."""
    today = datetime.now(UTC).date()
    trip = _make_trip(TripStatus.PLANNED, start_date=today)

    db = _setup_db(starting_trips=[trip], completing_trips=[])

    with patch("src.services.notification_service.NotificationService") as mock_notif:
        mock_notif._get_trip_recipients.return_value = [trip.user_id]

        from src.services.trips_service import TripsService
        TripsService.auto_transition_statuses(db)

        # Verify TRIP_STARTED was sent
        calls = mock_notif.create_and_send_bulk.call_args_list
        trip_started_calls = [
            c for c in calls
            if c.kwargs.get("notif_type") == NotificationType.TRIP_STARTED
        ]
        assert len(trip_started_calls) == 1
        assert trip_started_calls[0].kwargs["title"] == "Bon voyage !"


def test_trip_started_notification_includes_trip_title():
    """TRIP_STARTED notification body includes the trip title."""
    today = datetime.now(UTC).date()
    trip = _make_trip(TripStatus.PLANNED, start_date=today, title="Vacances à Rome")

    db = _setup_db(starting_trips=[trip], completing_trips=[])

    with patch("src.services.notification_service.NotificationService") as mock_notif:
        mock_notif._get_trip_recipients.return_value = [trip.user_id]

        from src.services.trips_service import TripsService
        TripsService.auto_transition_statuses(db)

        calls = mock_notif.create_and_send_bulk.call_args_list
        trip_started_calls = [
            c for c in calls
            if c.kwargs.get("notif_type") == NotificationType.TRIP_STARTED
        ]
        assert "Vacances à Rome" in trip_started_calls[0].kwargs["body"]


def test_no_trip_started_notification_when_no_transitions():
    """No TRIP_STARTED notification when no trips transition."""
    db = _setup_db(starting_trips=[], completing_trips=[])

    with patch("src.services.notification_service.NotificationService") as mock_notif:
        from src.services.trips_service import TripsService
        TripsService.auto_transition_statuses(db)

        # No notifications should be sent at all
        mock_notif.create_and_send_bulk.assert_not_called()
