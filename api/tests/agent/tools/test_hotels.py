"""Unit tests for the agent hotel tool.

Pinned by topic 04a (B23 — × nights inflation): the tool is the canonical
source of unit truth for the hotel cascade. It must always emit both
``price_total`` (whole-stay) and ``price_per_night`` so downstream
consumers can pick a unit explicitly.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.agent.tools.hotels import _compute_nights, search_real_hotels


class TestComputeNights:
    def test_returns_delta_in_days(self):
        assert _compute_nights("2026-04-23", "2026-04-30") == 7

    def test_returns_zero_on_inverted_dates(self):
        assert _compute_nights("2026-04-30", "2026-04-23") == 0

    def test_returns_zero_on_invalid_input(self):
        assert _compute_nights("not-a-date", "2026-04-30") == 0
        assert _compute_nights("", "") == 0


def _make_offer(*, total: str, currency: str = "EUR"):
    offer = MagicMock()
    offer.price = MagicMock()
    offer.price.total = total
    offer.price.currency = currency
    offer.checkInDate = "2026-04-23"
    offer.checkOutDate = "2026-04-30"
    return offer


def _make_hotel_item(*, name: str, hotel_id: str, total: str):
    item = MagicMock()
    item.hotel = {"name": name, "hotelId": hotel_id, "rating": 4}
    item.offers = [_make_offer(total=total)]
    return item


@pytest.mark.asyncio
async def test_search_real_hotels_exposes_per_night_and_stay_total():
    """Amadeus 7-night / 4-adult / 2000€ stay → per_night derived = 285.71."""
    list_item = MagicMock()
    list_item.hotelId = "HTLBCN001"
    hotel_list_response = MagicMock(data=[list_item])

    offers_response = MagicMock(
        data=[_make_hotel_item(name="Hotel Catalonia", hotel_id="HTLBCN001", total="2000")]
    )

    with patch("src.agent.tools.hotels.amadeus_client") as client, patch(
        "src.agent.tools.hotels.idempotency_cache"
    ) as cache:
        cache.get.return_value = None
        client.search_hotel_list = AsyncMock(return_value=hotel_list_response)
        client.search_hotel_offers = AsyncMock(return_value=offers_response)

        result = await search_real_hotels(
            city_code="BCN",
            check_in="2026-04-23",
            check_out="2026-04-30",
            adults=4,
        )

    assert result["source"] == "amadeus"
    assert len(result["hotels"]) == 1
    hotel = result["hotels"][0]
    assert hotel["price_total"] == 2000.0
    # 2000 / 7 nights, rounded to 2 decimals
    assert hotel["price_per_night"] == 285.71
    assert hotel["nights"] == 7
    assert hotel["adults"] == 4
    assert hotel["currency"] == "EUR"
    assert hotel["source"] == "amadeus"


@pytest.mark.asyncio
async def test_search_real_hotels_per_night_none_when_nights_zero():
    """Same-day check-in/out (or invalid dates) → per_night cannot be derived."""
    list_item = MagicMock()
    list_item.hotelId = "HTLPAR001"
    hotel_list_response = MagicMock(data=[list_item])

    offers_response = MagicMock(
        data=[_make_hotel_item(name="Hotel Paris", hotel_id="HTLPAR001", total="100")]
    )

    with patch("src.agent.tools.hotels.amadeus_client") as client, patch(
        "src.agent.tools.hotels.idempotency_cache"
    ) as cache:
        cache.get.return_value = None
        client.search_hotel_list = AsyncMock(return_value=hotel_list_response)
        client.search_hotel_offers = AsyncMock(return_value=offers_response)

        result = await search_real_hotels(
            city_code="PAR",
            check_in="2026-04-23",
            check_out="2026-04-23",
            adults=1,
        )

    hotel = result["hotels"][0]
    assert hotel["price_total"] == 100.0
    assert hotel["price_per_night"] is None
    assert hotel["nights"] == 0


@pytest.mark.asyncio
async def test_search_real_hotels_returns_empty_when_no_hotels_found():
    hotel_list_response = MagicMock(data=[])

    with patch("src.agent.tools.hotels.amadeus_client") as client, patch(
        "src.agent.tools.hotels.idempotency_cache"
    ) as cache:
        cache.get.return_value = None
        client.search_hotel_list = AsyncMock(return_value=hotel_list_response)

        result = await search_real_hotels(
            city_code="ZZZ",
            check_in="2026-04-23",
            check_out="2026-04-30",
        )

    assert result["hotels"] == []
    assert result["source"] == "amadeus"


@pytest.mark.asyncio
async def test_search_real_hotels_serves_from_cache():
    cached_payload = {"hotels": [{"name": "Cached"}], "source": "amadeus"}

    with patch("src.agent.tools.hotels.amadeus_client") as client, patch(
        "src.agent.tools.hotels.idempotency_cache"
    ) as cache:
        cache.get.return_value = cached_payload

        result = await search_real_hotels(
            city_code="BCN",
            check_in="2026-04-23",
            check_out="2026-04-30",
        )

    assert result is cached_payload
    client.search_hotel_list.assert_not_called() if hasattr(
        client.search_hotel_list, "assert_not_called"
    ) else None


@pytest.mark.asyncio
async def test_search_real_hotels_returns_error_payload_on_exception():
    with patch("src.agent.tools.hotels.amadeus_client") as client, patch(
        "src.agent.tools.hotels.idempotency_cache"
    ) as cache:
        cache.get.return_value = None
        client.search_hotel_list = AsyncMock(side_effect=RuntimeError("amadeus down"))

        result = await search_real_hotels(
            city_code="BCN",
            check_in="2026-04-23",
            check_out="2026-04-30",
        )

    assert result["hotels"] == []
    assert result["source"] == "error"
    assert "amadeus down" in result["error"]
