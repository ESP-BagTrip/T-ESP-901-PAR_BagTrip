"""Unit tests for ``agent.nodes.accommodation``."""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from src.agent.nodes.accommodation import (
    _synthesize_accommodation_placeholder,
    accommodation_node,
)


@pytest.mark.asyncio
async def test_returns_amadeus_hotels_when_available():
    real_hotels = [
        {
            "name": "Park Hyatt Tokyo",
            "hotel_id": "TOKHYT",
            "price_total": 1400,
            "price_per_night": 200,
            "nights": 7,
            "currency": "EUR",
            "source": "amadeus",
        }
    ]

    state = {
        "selected_destination": {"iata": "HND", "city": "Tokyo"},
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "nb_travelers": 2,
        "duration_days": 7,
        "budget_preset": "premium",
    }

    with patch(
        "src.agent.nodes.accommodation.search_real_hotels",
        new=AsyncMock(return_value={"hotels": real_hotels, "source": "amadeus"}),
    ):
        result = await accommodation_node(state)

    assert result["accommodations"] == real_hotels
    assert result["events"][0]["event"] == "accommodations"
    assert result["events"][0]["data"]["source"] == "amadeus"


@pytest.mark.asyncio
async def test_returns_deferred_marker_when_amadeus_returns_no_hotels():
    """No hotel data → emit a marker that lets the front render an
    unambiguous 'Hôtel à choisir' tile instead of inventing a name and
    a per-night price."""
    state = {
        "selected_destination": {"iata": "HND", "city": "Tokyo"},
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "nb_travelers": 2,
        "duration_days": 7,
        "budget_preset": "premium",
    }

    with patch(
        "src.agent.nodes.accommodation.search_real_hotels",
        new=AsyncMock(return_value={"hotels": [], "source": "amadeus"}),
    ):
        result = await accommodation_node(state)

    assert len(result["accommodations"]) == 1
    placeholder = result["accommodations"][0]
    assert placeholder["source"] == "deferred"
    assert placeholder["name"] == ""  # no fabricated hotel name
    assert placeholder["price_total"] is None
    assert placeholder["price_per_night"] is None
    assert placeholder["nights"] == 7
    assert placeholder["check_in"] == "2026-08-15"
    assert placeholder["check_out"] == "2026-08-22"
    assert result["events"][0]["data"]["source"] == "estimated"


@pytest.mark.asyncio
async def test_returns_deferred_marker_when_amadeus_raises():
    state = {
        "selected_destination": {"iata": "HND", "city": "Tokyo"},
        "departure_date": "2026-08-15",
        "return_date": "2026-08-22",
        "nb_travelers": 1,
        "duration_days": 5,
        "budget_preset": "mid",
    }

    with patch(
        "src.agent.nodes.accommodation.search_real_hotels",
        new=AsyncMock(side_effect=RuntimeError("Amadeus 500")),
    ):
        result = await accommodation_node(state)

    assert len(result["accommodations"]) == 1
    placeholder = result["accommodations"][0]
    assert placeholder["source"] == "deferred"
    assert placeholder["name"] == ""
    assert placeholder["price_total"] is None
    assert placeholder["price_per_night"] is None


@pytest.mark.asyncio
async def test_skips_search_when_dates_missing():
    state = {
        "selected_destination": {"iata": "HND", "city": "Tokyo"},
        "departure_date": "",
        "return_date": "",
        "nb_travelers": 2,
    }
    boom = AsyncMock(side_effect=AssertionError("should not be called"))

    with patch("src.agent.nodes.accommodation.search_real_hotels", new=boom):
        result = await accommodation_node(state)

    boom.assert_not_called()
    # No dates → no placeholder either; downstream knows to render
    # "Hôtel à choisir" without a tile.
    assert result["accommodations"] == []


def test_placeholder_returns_none_without_dates():
    placeholder = _synthesize_accommodation_placeholder(
        {"departure_date": "", "return_date": ""},
        {"city": "Tokyo"},
    )
    assert placeholder is None


def test_placeholder_carries_trip_dates_and_pax():
    placeholder = _synthesize_accommodation_placeholder(
        {
            "departure_date": "2026-08-15",
            "return_date": "2026-08-20",
            "duration_days": 5,
            "budget_preset": "absurd",
            "nb_travelers": 3,
        },
        {"city": "Lyon"},
    )
    assert placeholder is not None
    # No fabricated price field — the front must not display a number
    # we don't have ground truth for.
    assert placeholder["price_per_night"] is None
    assert placeholder["price_total"] is None
    # Trip context is preserved so the front can render
    # "Hôtel à choisir · 5 nuits · 3 voyageurs" without re-deriving.
    assert placeholder["nights"] == 5
    assert placeholder["adults"] == 3
    assert placeholder["check_in"] == "2026-08-15"
    assert placeholder["source"] == "deferred"
