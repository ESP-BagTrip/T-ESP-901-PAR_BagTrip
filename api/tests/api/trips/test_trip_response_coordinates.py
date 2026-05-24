"""Tests for TripResponse destination coordinate resolution (SMP327-039)."""

from src.api.trips.schemas import TripResponse


def _trip(make_trip, **overrides):
    # Detached ORM instances don't get SQLAlchemy server_defaults, so the
    # non-nullable tracking columns must be provided explicitly.
    overrides.setdefault("flights_tracking", "TRACKED")
    overrides.setdefault("accommodations_tracking", "TRACKED")
    return make_trip(**overrides)


def test_known_iata_resolves_coordinates(make_trip):
    """A trip with a known destination IATA exposes its coordinates."""
    trip = _trip(make_trip, destination_iata="CDG", destination_name="Paris")

    resp = TripResponse.model_validate(trip)

    assert resp.destinationLatitude is not None
    assert resp.destinationLongitude is not None
    # Charles de Gaulle is near Paris (~49.0 N, ~2.5 E).
    assert 48.0 < resp.destinationLatitude < 50.0
    assert 1.5 < resp.destinationLongitude < 3.5


def test_missing_iata_yields_none(make_trip):
    """No destination IATA -> no coordinates (map falls back)."""
    trip = _trip(make_trip, destination_iata=None)

    resp = TripResponse.model_validate(trip)

    assert resp.destinationLatitude is None
    assert resp.destinationLongitude is None


def test_unknown_iata_yields_none(make_trip):
    """An unknown IATA code resolves to no coordinates."""
    trip = _trip(make_trip, destination_iata="ZZZ")

    resp = TripResponse.model_validate(trip)

    assert resp.destinationLatitude is None
    assert resp.destinationLongitude is None
