"""Tests for the Amadeus-less flight fallback in budget_node.

Covers the synthesize helper directly — the full `budget_node` path
exercises LangGraph + LLM calls which are out of scope for unit tests.
The intent of this suite is to pin the fallback shape so the Flutter
`_tripPlanFromSseData` keeps getting populated offers even when Amadeus
is down (SMP-316 Barcelone reproduction).
"""

from __future__ import annotations

from src.agent.nodes.budget import _synthesize_flight_offer


def test_returns_empty_when_departure_date_invalid():
    assert (
        _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="not-a-date",
            return_date=None,
            flight_price=180,
        )
        == []
    )


def test_outbound_only_when_no_return_date():
    offers = _synthesize_flight_offer(
        origin_iata="CDG",
        dest_iata="BCN",
        departure_date="2026-04-23",
        return_date=None,
        flight_price=180,
    )
    assert len(offers) == 1
    offer = offers[0]
    assert offer["origin_iata"] == "CDG"
    assert offer["destination_iata"] == "BCN"
    assert offer["source"] == "estimated"
    assert offer["price"] == 180
    assert offer["duration"] == "PT2H"
    assert offer["departure"].startswith("2026-04-23T10:00")
    assert offer["arrival"].startswith("2026-04-23T12:00")
    assert "return_departure" not in offer
    assert "return_arrival" not in offer


def test_round_trip_fills_return_leg():
    offers = _synthesize_flight_offer(
        origin_iata="CDG",
        dest_iata="BCN",
        departure_date="2026-04-23",
        return_date="2026-04-30",
        flight_price=240,
    )
    assert len(offers) == 1
    offer = offers[0]
    assert offer["return_departure"].startswith("2026-04-30T18:00")
    assert offer["return_arrival"].startswith("2026-04-30T20:00")
    assert offer["return_duration"] == "PT2H"


def test_estimated_source_is_explicit():
    """Flutter displays a specific 'estimated' badge — the source field must
    never be 'amadeus' for synthesized offers."""
    offers = _synthesize_flight_offer(
        origin_iata="CDG",
        dest_iata="BCN",
        departure_date="2026-04-23",
        return_date="2026-04-30",
        flight_price=0,
    )
    assert offers[0]["source"] == "estimated"
    assert offers[0]["airline_name"] == "Estimated"


def test_flight_number_is_empty_string_not_null():
    """The Flutter parser treats `flight_number ?? ''` — emitting an empty
    string (not null) keeps the key present which makes JSON contract
    compatibility easier."""
    offers = _synthesize_flight_offer(
        origin_iata="CDG",
        dest_iata="BCN",
        departure_date="2026-04-23",
        return_date=None,
        flight_price=120,
    )
    assert offers[0]["flight_number"] == ""


def test_return_date_invalid_keeps_outbound_only():
    offers = _synthesize_flight_offer(
        origin_iata="CDG",
        dest_iata="BCN",
        departure_date="2026-04-23",
        return_date="bogus",
        flight_price=100,
    )
    assert len(offers) == 1
    assert "return_departure" not in offers[0]
