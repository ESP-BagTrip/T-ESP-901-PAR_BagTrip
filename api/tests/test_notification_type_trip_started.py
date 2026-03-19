"""Tests for M2 — NotificationType.TRIP_STARTED enum addition."""

from src.enums import NotificationType


def test_trip_started_exists():
    """TRIP_STARTED is a valid NotificationType value."""
    assert hasattr(NotificationType, "TRIP_STARTED")
    assert NotificationType.TRIP_STARTED == "TRIP_STARTED"


def test_notification_type_all_values():
    """Verify complete set of NotificationType values."""
    expected = {
        "DEPARTURE_REMINDER",
        "FLIGHT_H4",
        "FLIGHT_H1",
        "MORNING_SUMMARY",
        "ACTIVITY_H1",
        "TRIP_STARTED",
        "TRIP_ENDED",
        "BUDGET_ALERT",
        "TRIP_SHARED",
        "ADMIN",
    }
    actual = {e.value for e in NotificationType}
    assert actual == expected


def test_trip_started_is_str():
    """TRIP_STARTED behaves as a string (StrEnum)."""
    assert isinstance(NotificationType.TRIP_STARTED, str)
    assert f"type={NotificationType.TRIP_STARTED}" == "type=TRIP_STARTED"
