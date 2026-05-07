"""Unit tests for ``integrations.amadeus.sentiments.search_hotel_sentiments``."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.integrations.amadeus.sentiments import search_hotel_sentiments
from src.integrations.amadeus.types import HotelSentimentSearchQuery
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _stub_amadeus_token():
    with patch(
        "src.integrations.amadeus.sentiments.fetch_token",
        new=AsyncMock(return_value="fake-token"),
    ):
        yield


def _build_response(status_code: int, payload: dict) -> MagicMock:
    response = MagicMock()
    response.status_code = status_code
    response.json.return_value = payload
    response.text = str(payload)
    return response


@pytest.mark.asyncio
async def test_search_hotel_sentiments_returns_parsed_list_on_200():
    payload = {
        "data": [
            {
                "type": "hotelSentiment",
                "hotelId": "RTPAR001",
                "overallRating": 87,
                "numberOfReviews": 1240,
                "numberOfRatings": 980,
                "sentiments": {
                    "sleep": 91,
                    "location": 95,
                    "service": 80,
                    "value": 70,
                },
            }
        ]
    }
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, payload))

    with patch(
        "src.integrations.amadeus.sentiments.get_http_client",
        return_value=fake_client,
    ):
        query = HotelSentimentSearchQuery(hotelIds=["RTPAR001"])
        results = await search_hotel_sentiments(query)

    assert len(results) == 1
    sentiment = results[0]
    assert sentiment.hotelId == "RTPAR001"
    assert sentiment.overallRating == 87
    assert sentiment.sentiments is not None
    assert sentiment.sentiments.location == 95
    assert sentiment.sentiments.value == 70


@pytest.mark.asyncio
async def test_search_hotel_sentiments_passes_comma_separated_ids():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, {"data": []}))

    with patch(
        "src.integrations.amadeus.sentiments.get_http_client",
        return_value=fake_client,
    ):
        query = HotelSentimentSearchQuery(hotelIds=["A1", "B2", "C3"])
        await search_hotel_sentiments(query)

    sent_params = fake_client.get.call_args.kwargs["params"]
    assert sent_params["hotelIds"] == "A1,B2,C3"


def test_query_rejects_more_than_three_ids():
    with pytest.raises(ValueError):
        HotelSentimentSearchQuery(hotelIds=["A", "B", "C", "D"])


def test_query_rejects_empty_list():
    with pytest.raises(ValueError):
        HotelSentimentSearchQuery(hotelIds=[])


@pytest.mark.asyncio
async def test_search_hotel_sentiments_rate_limit_raises():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(
        return_value=_build_response(429, {"errors": [{"detail": "limit"}]})
    )

    with patch(
        "src.integrations.amadeus.sentiments.get_http_client",
        return_value=fake_client,
    ):
        query = HotelSentimentSearchQuery(hotelIds=["RTPAR001"])
        with pytest.raises(AppError) as exc:
            await search_hotel_sentiments(query)
    assert exc.value.code == "RATE_LIMITED"
