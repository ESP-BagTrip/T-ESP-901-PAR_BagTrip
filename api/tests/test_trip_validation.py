"""Tests for TripCreateRequest validation (A1)."""

from datetime import date, timedelta

import pytest
from pydantic import ValidationError

from src.api.trips.schemas import TripCreateRequest

TOMORROW = date.today() + timedelta(days=1)
NEXT_WEEK = date.today() + timedelta(days=7)
YESTERDAY = date.today() - timedelta(days=1)


def test_destination_name_only():
    """destinationName seul — OK."""
    req = TripCreateRequest(destinationName="Paris")
    assert req.destinationName == "Paris"


def test_destination_iata_only():
    """destinationIata seul — OK."""
    req = TripCreateRequest(destinationIata="CDG")
    assert req.destinationIata == "CDG"


def test_both_destinations():
    """Les deux — OK."""
    req = TripCreateRequest(destinationName="Paris", destinationIata="CDG")
    assert req.destinationName == "Paris"
    assert req.destinationIata == "CDG"


def test_no_destination_raises():
    """Aucun des deux — 422."""
    with pytest.raises(ValidationError, match="destinationName or destinationIata"):
        TripCreateRequest(title="Test")


def test_start_after_end_raises():
    """startDate > endDate — 422."""
    with pytest.raises(ValidationError, match="startDate must be before"):
        TripCreateRequest(
            destinationName="Paris",
            startDate=NEXT_WEEK,
            endDate=TOMORROW,
        )


def test_same_day_trip():
    """startDate == endDate — OK (trip d'un jour)."""
    req = TripCreateRequest(
        destinationName="Paris",
        startDate=TOMORROW,
        endDate=TOMORROW,
    )
    assert req.startDate == req.endDate


def test_past_start_date_raises():
    """startDate dans le passé — 422."""
    with pytest.raises(ValidationError, match="startDate must be today"):
        TripCreateRequest(
            destinationName="Paris",
            startDate=YESTERDAY,
            endDate=TOMORROW,
        )


def test_today_start_date():
    """startDate aujourd'hui — OK."""
    today = date.today()
    req = TripCreateRequest(
        destinationName="Paris",
        startDate=today,
        endDate=NEXT_WEEK,
    )
    assert req.startDate == today
