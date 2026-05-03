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
async def test_synthesizes_placeholder_when_amadeus_returns_no_hotels():
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
    assert placeholder["source"] == "estimated"
    # Nightly rate for premium = 280 EUR; 7 nights -> 1960 EUR.
    assert placeholder["price_total"] == 280.0 * 7
    assert placeholder["price_per_night"] == 280.0
    assert placeholder["nights"] == 7
    assert "Tokyo" in placeholder["name"]
    assert result["events"][0]["data"]["source"] == "estimated"


@pytest.mark.asyncio
async def test_synthesizes_placeholder_when_amadeus_raises():
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
    assert placeholder["source"] == "estimated"
    # Mid band = 120 EUR/night × 5 = 600 EUR.
    assert placeholder["price_total"] == 600.0


@pytest.mark.asyncio
async def test_skips_search_when_dates_missing():
    state = {
        "selected_destination": {"iata": "HND", "city": "Tokyo"},
        "departure_date": "",
        "return_date": "",
        "nb_travelers": 2,
    }
    # The amadeus call must not even fire — patch it as an exploding mock.
    boom = AsyncMock(side_effect=AssertionError("should not be called"))

    with patch("src.agent.nodes.accommodation.search_real_hotels", new=boom):
        result = await accommodation_node(state)

    boom.assert_not_called()
    # No dates → no placeholder either; downstream knows to render
    # "À déterminer" without a tile.
    assert result["accommodations"] == []


def test_placeholder_returns_none_without_dates():
    placeholder = _synthesize_accommodation_placeholder(
        {"departure_date": "", "return_date": ""},
        {"city": "Tokyo"},
    )
    assert placeholder is None


def test_placeholder_falls_back_to_mid_for_unknown_preset():
    placeholder = _synthesize_accommodation_placeholder(
        {
            "departure_date": "2026-08-15",
            "return_date": "2026-08-20",
            "duration_days": 5,
            "budget_preset": "absurd",
            "nb_travelers": 2,
        },
        {"city": "Lyon"},
    )
    assert placeholder is not None
    # Falls back to 120 EUR mid-band.
    assert placeholder["price_per_night"] == 120.0
