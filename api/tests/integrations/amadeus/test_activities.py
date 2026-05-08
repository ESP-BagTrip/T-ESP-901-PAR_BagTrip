"""Unit tests for ``integrations.amadeus.activities.search_activities``."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.integrations.amadeus.activities import search_activities
from src.integrations.amadeus.types import ActivitySearchQuery
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _stub_amadeus_token():
    with patch(
        "src.integrations.amadeus.activities.fetch_token",
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
async def test_search_activities_returns_parsed_list_on_200():
    payload = {
        "data": [
            {
                "id": "8506",
                "name": "Marina Bay Sands SkyPark",
                "shortDescription": "Iconic observation deck and infinity pool",
                "geoCode": {"latitude": 1.2839, "longitude": 103.8607},
                "rating": "4.5",
                "price": {"amount": "23.00", "currencyCode": "USD"},
                "pictures": ["https://example.test/pic.jpg"],
                "bookingLink": "https://amadeus.test/book/8506",
                "minimumDuration": "PT2H",
            }
        ]
    }
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, payload))

    with patch(
        "src.integrations.amadeus.activities.get_http_client",
        return_value=fake_client,
    ):
        query = ActivitySearchQuery(latitude=1.28, longitude=103.85, radius=5)
        results = await search_activities(query)

    assert len(results) == 1
    activity = results[0]
    assert activity.name == "Marina Bay Sands SkyPark"
    assert activity.price is not None
    assert activity.price.amount == "23.00"
    assert activity.minimumDuration == "PT2H"


@pytest.mark.asyncio
async def test_search_activities_empty_data_yields_empty_list():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, {"data": []}))

    with patch(
        "src.integrations.amadeus.activities.get_http_client",
        return_value=fake_client,
    ):
        query = ActivitySearchQuery(latitude=0, longitude=0, radius=1)
        results = await search_activities(query)

    assert results == []


@pytest.mark.asyncio
async def test_search_activities_propagates_query_params():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, {"data": []}))

    with patch(
        "src.integrations.amadeus.activities.get_http_client",
        return_value=fake_client,
    ):
        query = ActivitySearchQuery(latitude=1.28, longitude=103.85, radius=3)
        await search_activities(query)

    sent_params = fake_client.get.call_args.kwargs["params"]
    assert sent_params["latitude"] == 1.28
    assert sent_params["longitude"] == 103.85
    assert sent_params["radius"] == 3


@pytest.mark.asyncio
async def test_search_activities_non_200_raises_app_error():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(
        return_value=_build_response(500, {"errors": [{"detail": "server error"}]})
    )

    with patch(
        "src.integrations.amadeus.activities.get_http_client",
        return_value=fake_client,
    ):
        query = ActivitySearchQuery(latitude=0, longitude=0, radius=1)
        with pytest.raises(AppError) as exc:
            await search_activities(query)
    assert exc.value.code == "UPSTREAM_ERROR"
