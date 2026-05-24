"""Tests for auto-add creator as traveler (A4)."""

from unittest.mock import MagicMock
from uuid import uuid4

from src.services.trips_service import TripsService


def _make_user(full_name=None):
    """Create a mock User."""
    user = MagicMock()
    user.full_name = full_name
    user.id = uuid4()
    return user


def _make_mock_db(user):
    """Create a mock DB session that returns the given user."""
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = user

    # Make Trip constructor generate an id
    trip_id = uuid4()
    added_objects = []

    def capture_add(obj):
        if not hasattr(obj, "id"):
            return
        if hasattr(obj, "user_id"):
            obj.id = trip_id
        added_objects.append(obj)

    db.add.side_effect = capture_add
    db.refresh = MagicMock()
    db._added = added_objects
    db._trip_id = trip_id
    return db


def _get_traveler(db):
    """Extract the TripTraveler from mock db.add calls."""
    from src.models.traveler import TripTraveler

    for call in db.add.call_args_list:
        obj = call[0][0]
        if isinstance(obj, TripTraveler):
            return obj
    return None


def test_full_name_two_parts():
    """full_name = 'Jean Dupont' → first=Jean, last=Dupont."""
    user = _make_user("Jean Dupont")
    db = _make_mock_db(user)
    TripsService.create_trip(db, user.id, "Test", None, None, destination_name="Paris")
    traveler = _get_traveler(db)
    assert traveler is not None
    assert traveler.first_name == "Jean"
    assert traveler.last_name == "Dupont"


def test_full_name_single_word():
    """full_name = 'Jean' → first=Jean, last=Jean."""
    user = _make_user("Jean")
    db = _make_mock_db(user)
    TripsService.create_trip(db, user.id, "Test", None, None, destination_name="Paris")
    traveler = _get_traveler(db)
    assert traveler is not None
    assert traveler.first_name == "Jean"
    assert traveler.last_name == "Jean"


def test_full_name_none():
    """full_name = None → first=Voyageur, last=Principal."""
    user = _make_user(None)
    db = _make_mock_db(user)
    TripsService.create_trip(db, user.id, "Test", None, None, destination_name="Paris")
    traveler = _get_traveler(db)
    assert traveler is not None
    assert traveler.first_name == "Voyageur"
    assert traveler.last_name == "Principal"


def test_full_name_three_parts():
    """full_name = 'Jean Pierre Dupont' → first=Jean, last=Pierre Dupont."""
    user = _make_user("Jean Pierre Dupont")
    db = _make_mock_db(user)
    TripsService.create_trip(db, user.id, "Test", None, None, destination_name="Paris")
    traveler = _get_traveler(db)
    assert traveler is not None
    assert traveler.first_name == "Jean"
    assert traveler.last_name == "Pierre Dupont"


def test_traveler_type_and_trip_id():
    """Verify traveler_type == 'ADULT' and trip_id is correct."""
    user = _make_user("Test User")
    db = _make_mock_db(user)
    trip = TripsService.create_trip(db, user.id, "Test", None, None, destination_name="Paris")
    traveler = _get_traveler(db)
    assert traveler is not None
    assert traveler.traveler_type == "ADULT"
    assert traveler.trip_id == trip.id
