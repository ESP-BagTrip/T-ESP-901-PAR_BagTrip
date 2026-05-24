"""Tests for the Amadeus-less flight fallback in ``budget_node``.

Covers the synthesize helper directly — the full ``budget_node`` path
exercises LangGraph + node interactions which are out of scope for unit
tests. The intent of this suite is to pin the fallback shape so the
Flutter ``_tripPlanFromSseData`` keeps getting populated offers even
when Amadeus is down (SMP-316 Barcelone reproduction, SMP-324 Tokyo
sandbox 500 follow-up).
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch

from src.agent.nodes.budget import (
    _estimate_flight_duration_hours,
    _estimate_flight_price_eur,
    _haversine_km,
    _synthesize_flight_offer,
)


def _aviation_loc(lat: float, lon: float) -> MagicMock:
    geo = MagicMock(latitude=lat, longitude=lon)
    return MagicMock(geoCode=geo)


# ---------------------------------------------------------------------------
# Pure helpers
# ---------------------------------------------------------------------------


def test_haversine_paris_tokyo_within_known_range():
    # Paris CDG ≈ (49.01, 2.55), Tokyo HND ≈ (35.55, 139.78). Real great
    # circle is ~9700 km — accept any answer in the 9500-9900 band so the
    # test stays stable across IATA dataset minor lat/lon revisions.
    distance = _haversine_km(49.01, 2.55, 35.55, 139.78)
    assert 9500 < distance < 9900


def test_haversine_short_haul_is_short():
    # Paris CDG → Barcelona BCN ≈ 850 km
    distance = _haversine_km(49.01, 2.55, 41.30, 2.08)
    assert 800 < distance < 900


def test_duration_long_haul_is_double_digit_hours():
    # ~9700 km / 800 kmh + 1 h ground ≈ 13.1 h
    duration = _estimate_flight_duration_hours(9700)
    assert 12.5 < duration < 14.0


def test_duration_short_haul_at_least_two_hours():
    duration = _estimate_flight_duration_hours(800)
    # 800 / 800 + 1 = 2.0
    assert duration == 2.0


def test_price_long_haul_round_trip_two_pax_realistic():
    # Paris → Tokyo round-trip for 2 adults: clearly above 1500 € (the
    # bug rendered 315 €). Realistic high-season fare can run up to
    # ~5000 € for two seats, so we accept the whole plausible band.
    price = _estimate_flight_price_eur(9700, adults=2, round_trip=True)
    assert price > 1500
    assert price < 5000


def test_price_short_haul_one_way_solo():
    # Paris → Barcelona one-way: a couple of hundred euros.
    price = _estimate_flight_price_eur(850, adults=1, round_trip=False)
    assert 130 < price < 250


# ---------------------------------------------------------------------------
# _synthesize_flight_offer
# ---------------------------------------------------------------------------


def test_returns_empty_when_departure_date_invalid():
    assert (
        _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="not-a-date",
            return_date=None,
            nb_travelers=1,
        )
        == []
    )


def test_outbound_only_when_no_return_date():
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: {
            "CDG": _aviation_loc(49.01, 2.55),
            "BCN": _aviation_loc(41.30, 2.08),
        }.get(code),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="2026-04-23",
            return_date=None,
            nb_travelers=1,
        )
    assert len(offers) == 1
    offer = offers[0]
    assert offer["origin_iata"] == "CDG"
    assert offer["destination_iata"] == "BCN"
    assert offer["source"] == "estimated"
    # Distance-based price must be above the 80 € fixed overhead and below
    # the long-haul band — exact value is just sanity-checked here.
    assert 130 < offer["price"] < 250
    # ~2-hour short-haul → "PT2H" or "PT2H..M" depending on the airport
    # latitudes; we just want to assert short-haul, not a sub-minute spec.
    assert offer["duration"].startswith("PT2H")
    assert offer["departure"].startswith("2026-04-23T10:00")
    assert "return_departure" not in offer
    assert "return_arrival" not in offer


def test_long_haul_round_trip_for_two_realistic():
    """The Paris-Tokyo regression: must surface a long flight time and a
    plausible round-trip price for 2 adults."""
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: {
            "CDG": _aviation_loc(49.01, 2.55),
            "HND": _aviation_loc(35.55, 139.78),
        }.get(code),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="HND",
            departure_date="2026-08-15",
            return_date="2026-08-22",
            nb_travelers=2,
        )
    assert len(offers) == 1
    offer = offers[0]
    # Duration should be > 12 hours (string starts with PT12H or PT13H, …).
    assert offer["duration"].startswith("PT1")  # PT12H, PT13H, PT14H…
    # Round-trip × 2 adults → at least 1 500 € (much higher than the
    # legacy 315 € heuristic that triggered this fix).
    assert offer["price"] > 1500
    assert offer["return_departure"].startswith("2026-08-22T18:00")


def test_round_trip_return_leg_uses_estimated_duration():
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: {
            "CDG": _aviation_loc(49.01, 2.55),
            "BCN": _aviation_loc(41.30, 2.08),
        }.get(code),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="2026-04-23",
            return_date="2026-04-30",
            nb_travelers=2,
        )
    offer = offers[0]
    # Outbound and return have the same estimated duration shape.
    assert offer["duration"] == offer["return_duration"]
    assert offer["return_departure"].startswith("2026-04-30T18:00")


def test_estimated_source_is_explicit():
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: {
            "CDG": _aviation_loc(49.01, 2.55),
            "BCN": _aviation_loc(41.30, 2.08),
        }.get(code),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="2026-04-23",
            return_date="2026-04-30",
            nb_travelers=1,
        )
    assert offers[0]["source"] == "estimated"
    assert offers[0]["airline_name"] == "Estimated"


def test_flight_number_is_empty_string_not_null():
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: _aviation_loc(0, 0),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="2026-04-23",
            return_date=None,
            nb_travelers=1,
        )
    assert offers[0]["flight_number"] == ""


def test_return_date_invalid_keeps_outbound_only():
    with patch(
        "src.agent.nodes.budget.aviation_data_service.get_by_id",
        side_effect=lambda code: _aviation_loc(0, 0),
    ):
        offers = _synthesize_flight_offer(
            origin_iata="CDG",
            dest_iata="BCN",
            departure_date="2026-04-23",
            return_date="bogus",
            nb_travelers=1,
        )
    assert len(offers) == 1
    assert "return_departure" not in offers[0]
