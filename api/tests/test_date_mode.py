"""Tests for M3 — DateMode enum and Trip.date_mode field."""

from unittest.mock import MagicMock
from uuid import uuid4

from src.enums import DateMode
from src.models.trip import Trip


def test_date_mode_enum_values():
    """DateMode has exactly 3 values: EXACT, MONTH, FLEXIBLE."""
    expected = {"EXACT", "MONTH", "FLEXIBLE"}
    actual = {e.value for e in DateMode}
    assert actual == expected


def test_date_mode_default_exact():
    """DateMode default is EXACT."""
    assert DateMode.EXACT == "EXACT"


def test_date_mode_is_str():
    """DateMode members are strings (StrEnum)."""
    for mode in DateMode:
        assert isinstance(mode, str)


def test_trip_model_has_date_mode():
    """Trip model has date_mode column."""
    assert hasattr(Trip, "date_mode")
    col = Trip.__table__.columns["date_mode"]
    assert col.server_default.arg == "EXACT"
    assert col.nullable is False


def test_trip_create_with_date_mode():
    """TripCreateRequest accepts dateMode field."""
    from src.api.trips.schemas import TripCreateRequest

    req = TripCreateRequest(destinationName="Paris", dateMode="MONTH")
    assert req.dateMode == "MONTH"


def test_trip_create_default_date_mode():
    """TripCreateRequest defaults dateMode to EXACT."""
    from src.api.trips.schemas import TripCreateRequest

    req = TripCreateRequest(destinationName="Paris")
    assert req.dateMode == DateMode.EXACT


def test_trip_update_with_date_mode():
    """TripUpdateRequest accepts dateMode field."""
    from src.api.trips.schemas import TripUpdateRequest

    req = TripUpdateRequest(dateMode="FLEXIBLE")
    assert req.dateMode == "FLEXIBLE"


def test_trip_update_date_mode_optional():
    """TripUpdateRequest dateMode is optional (None by default)."""
    from src.api.trips.schemas import TripUpdateRequest

    req = TripUpdateRequest()
    assert req.dateMode is None


def test_trip_response_includes_date_mode():
    """TripResponse includes dateMode field with alias date_mode."""
    from datetime import UTC, datetime

    from src.api.trips.schemas import TripResponse

    data = {
        "id": uuid4(),
        "date_mode": "MONTH",
        "created_at": datetime.now(UTC),
        "updated_at": datetime.now(UTC),
    }
    resp = TripResponse.model_validate(data)
    assert resp.dateMode == "MONTH"


def test_trip_response_default_date_mode():
    """TripResponse defaults dateMode to EXACT when not provided."""
    from datetime import UTC, datetime

    from src.api.trips.schemas import TripResponse

    data = {
        "id": uuid4(),
        "created_at": datetime.now(UTC),
        "updated_at": datetime.now(UTC),
    }
    resp = TripResponse.model_validate(data)
    assert resp.dateMode == "EXACT"


def test_service_create_trip_passes_date_mode():
    """TripsService.create_trip passes date_mode to Trip constructor."""
    from src.services.trips_service import TripsService

    user = MagicMock()
    user.id = uuid4()
    user.full_name = "Test User"

    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = user

    captured_trips = []

    def capture_add(obj):
        captured_trips.append(obj)

    db.add.side_effect = capture_add

    TripsService.create_trip(
        db,
        user.id,
        "Test",
        None,
        None,
        destination_name="Paris",
        date_mode="FLEXIBLE",
    )

    trip = captured_trips[0]
    assert isinstance(trip, Trip)
    assert trip.date_mode == "FLEXIBLE"


def test_service_create_trip_default_date_mode():
    """TripsService.create_trip defaults date_mode to EXACT."""
    from src.services.trips_service import TripsService

    user = MagicMock()
    user.id = uuid4()
    user.full_name = "Test User"

    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = user

    captured_trips = []

    def capture_add(obj):
        captured_trips.append(obj)

    db.add.side_effect = capture_add

    TripsService.create_trip(
        db,
        user.id,
        "Test",
        None,
        None,
        destination_name="Paris",
    )

    trip = captured_trips[0]
    assert isinstance(trip, Trip)
    assert trip.date_mode == DateMode.EXACT
