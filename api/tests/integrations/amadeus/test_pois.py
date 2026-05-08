"""Unit tests for ``integrations.amadeus.pois.search_pois``."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.integrations.amadeus.pois import search_pois
from src.integrations.amadeus.types import PoiSearchQuery
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _stub_amadeus_token():
    with patch(
        "src.integrations.amadeus.pois.fetch_token",
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
async def test_search_pois_returns_parsed_list_on_200():
    payload = {
        "data": [
            {
                "id": "9CB40CB5D0",
                "name": "Marina Bay Sands",
                "geoCode": {"latitude": 1.2839, "longitude": 103.8607},
                "category": "SIGHTS",
                "rank": 5,
                "tags": ["resort", "casino", "shopping"],
            },
            {
                "id": "ABCDEF",
                "name": "Gardens by the Bay",
                "geoCode": {"latitude": 1.282, "longitude": 103.864},
                "category": "BEACH_PARK",
                "tags": ["nature", "garden"],
            },
        ]
    }
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, payload))

    with patch("src.integrations.amadeus.pois.get_http_client", return_value=fake_client):
        query = PoiSearchQuery(latitude=1.28, longitude=103.85, radius=5, lang="en", page_limit=10)
        results = await search_pois(query)

    assert len(results) == 2
    assert results[0].name == "Marina Bay Sands"
    assert results[0].tags == ["resort", "casino", "shopping"]
    assert results[1].category == "BEACH_PARK"


@pytest.mark.asyncio
async def test_search_pois_empty_data_yields_empty_list():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, {"data": []}))

    with patch("src.integrations.amadeus.pois.get_http_client", return_value=fake_client):
        query = PoiSearchQuery(latitude=0, longitude=0, radius=1)
        results = await search_pois(query)

    assert results == []


@pytest.mark.asyncio
async def test_search_pois_propagates_lang_param():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=_build_response(200, {"data": []}))

    with patch("src.integrations.amadeus.pois.get_http_client", return_value=fake_client):
        query = PoiSearchQuery(latitude=1.28, longitude=103.85, radius=2, lang="fr", page_limit=5)
        await search_pois(query)

    sent_params = fake_client.get.call_args.kwargs["params"]
    assert sent_params["latitude"] == 1.28
    assert sent_params["longitude"] == 103.85
    assert sent_params["radius"] == 2
    assert sent_params["lang"] == "fr"
    assert sent_params["page[limit]"] == 5
    # `categories` was not provided → exclude_none drops it.
    assert "categories" not in sent_params


@pytest.mark.asyncio
async def test_search_pois_non_200_raises():
    fake_client = MagicMock()
    fake_client.get = AsyncMock(
        return_value=_build_response(429, {"errors": [{"detail": "rate limit"}]})
    )

    with patch("src.integrations.amadeus.pois.get_http_client", return_value=fake_client):
        query = PoiSearchQuery(latitude=0, longitude=0, radius=1)
        with pytest.raises(AppError) as exc:
            await search_pois(query)
    assert exc.value.code == "RATE_LIMITED"
