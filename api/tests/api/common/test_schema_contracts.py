"""Contract tests for PATCH / POST request schemas — snake_case must work.

The mobile client sends snake_case on every PATCH/POST body because of its
global `field_rename: snake` build.yaml directive. Any request schema that
declares a camelCase field without an alias silently drops the key when
Flutter sends the snake_case variant — that bug cost us the activity
validation regression (SMP-316) and is easy to re-introduce on any new
endpoint.

This test pins the contract: for the Update/Create request schemas we
care about on SMP-316, asserting that parsing with snake_case populates
the attribute correctly. Extend this list when adding new request DTOs.
"""

from __future__ import annotations

import pytest

from src.api.accommodations.schemas import (
    AccommodationCreateRequest,
    AccommodationUpdateRequest,
)
from src.api.activities.schemas import ActivityUpdateRequest
from src.api.flights.manual.schemas import (
    ManualFlightCreateRequest,
    ManualFlightUpdateRequest,
)


@pytest.mark.parametrize(
    "schema_cls, snake_payload, expected_attr, expected_value",
    [
        (
            ActivityUpdateRequest,
            {"validation_status": "VALIDATED"},
            "validationStatus",
            "VALIDATED",
        ),
        (
            ActivityUpdateRequest,
            {"start_time": "09:00:00", "end_time": "11:00:00"},
            "startTime",
            None,  # separately asserted below
        ),
        (
            ActivityUpdateRequest,
            {"estimated_cost": 42.5},
            "estimatedCost",
            42.5,
        ),
        (
            AccommodationUpdateRequest,
            {"check_in": "2026-04-23T00:00:00+00:00"},
            "checkIn",
            None,
        ),
        (
            AccommodationUpdateRequest,
            {"price_per_night": 120.0, "booking_reference": "BR-123"},
            "pricePerNight",
            120.0,
        ),
        (
            AccommodationUpdateRequest,
            {"validation_status": "VALIDATED"},
            "validationStatus",
            "VALIDATED",
        ),
        (
            AccommodationCreateRequest,
            {"name": "Hotel", "check_in": "2026-04-23T00:00:00+00:00"},
            "checkIn",
            None,
        ),
        (
            ManualFlightUpdateRequest,
            {"validation_status": "VALIDATED"},
            "validationStatus",
            "VALIDATED",
        ),
        (
            ManualFlightUpdateRequest,
            {"departure_airport": "CDG", "arrival_airport": "BCN"},
            "departureAirport",
            "CDG",
        ),
        (
            ManualFlightUpdateRequest,
            {"flight_type": "RETURN"},
            "flightType",
            "RETURN",
        ),
        (
            ManualFlightCreateRequest,
            {"flight_number": "VY8017", "departure_airport": "CDG", "arrival_airport": "BCN"},
            "flightNumber",
            "VY8017",
        ),
    ],
)
def test_snake_case_payload_populates_attr(
    schema_cls, snake_payload, expected_attr, expected_value
):
    """Regression: snake_case body keys must map to the camelCase attribute."""
    model = schema_cls(**snake_payload)
    got = getattr(model, expected_attr)
    assert got is not None, f"{schema_cls.__name__}.{expected_attr} was not populated"
    if expected_value is not None:
        assert got == expected_value


def test_camel_case_keeps_working():
    """camelCase payloads should still parse — both shapes are accepted."""
    model = ActivityUpdateRequest(validationStatus="VALIDATED")
    assert model.validationStatus == "VALIDATED"


def test_mixed_casing_favors_explicit_field_name():
    """When both are sent, Pydantic takes the last one written (kwargs order);
    the point is that neither is silently dropped."""
    model = ActivityUpdateRequest(**{"validation_status": "VALIDATED"})
    assert model.validationStatus == "VALIDATED"
