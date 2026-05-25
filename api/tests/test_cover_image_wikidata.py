"""Tests for the Wikidata cover provider (SMP-330)."""

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from src.integrations.cover_image.wikidata import WikidataCoverClient


@pytest.fixture
def mock_http():
    mock_client = AsyncMock()
    with patch(
        "src.integrations.cover_image.wikidata.get_http_client",
        return_value=mock_client,
    ):
        yield mock_client


def _resp(status: int, body: dict) -> httpx.Response:
    return httpx.Response(
        status,
        json=body,
        request=httpx.Request("GET", "https://www.wikidata.org/w/api.php"),
    )


@pytest.mark.asyncio
async def test_search_entity_returns_top_qid(mock_http):
    mock_http.get.return_value = _resp(
        200, {"search": [{"id": "Q1490"}, {"id": "Q123"}]}
    )
    assert await WikidataCoverClient.search_entity("Tokyo") == "Q1490"


@pytest.mark.asyncio
async def test_search_entity_no_match(mock_http):
    mock_http.get.return_value = _resp(200, {"search": []})
    assert await WikidataCoverClient.search_entity("xyz") is None


@pytest.mark.asyncio
async def test_search_entity_blank_query(mock_http):
    assert await WikidataCoverClient.search_entity("  ") is None
    mock_http.get.assert_not_called()


@pytest.mark.asyncio
async def test_search_entity_network_failure(mock_http):
    mock_http.get.side_effect = httpx.ConnectError("boom")
    assert await WikidataCoverClient.search_entity("Tokyo") is None


def _entity(p18: str | None = "Tokyo Tower.jpg", coords=(35.69, 139.69)) -> dict:
    claims: dict = {}
    if p18:
        claims["P18"] = [{"mainsnak": {"datavalue": {"value": p18}}}]
    if coords:
        claims["P625"] = [
            {
                "mainsnak": {
                    "datavalue": {"value": {"latitude": coords[0], "longitude": coords[1]}}
                }
            }
        ]
    return {"claims": claims, "labels": {"en": {"value": "Tokyo"}}}


def test_extract_p18_first_claim_only():
    assert WikidataCoverClient._extract_p18(_entity("first.jpg")) == "first.jpg"
    assert WikidataCoverClient._extract_p18(_entity(p18=None)) is None


def test_extract_coords():
    assert WikidataCoverClient._extract_coords(_entity()) == (35.69, 139.69)
    assert WikidataCoverClient._extract_coords({"claims": {}}) is None


def test_extract_label_prefers_locale():
    entity = {"labels": {"fr": {"value": "Tokyo (FR)"}, "en": {"value": "Tokyo"}}}
    assert WikidataCoverClient._extract_label(entity, "fr") == "Tokyo (FR)"
    assert WikidataCoverClient._extract_label(entity, "es") == "Tokyo"


@pytest.mark.asyncio
async def test_fetch_candidates_end_to_end(mock_http):
    # 1st call: wbsearchentities → QID
    # 2nd call: EntityData → P18 + coords
    mock_http.get.side_effect = [
        _resp(200, {"search": [{"id": "Q1490"}]}),
        _resp(200, {"entities": {"Q1490": _entity("Tokyo Tower.jpg")}}),
    ]
    candidates, coords = await WikidataCoverClient.fetch_candidates("Tokyo", locale="en")
    assert len(candidates) == 1
    assert candidates[0].source == "wikidata"
    assert "Tokyo Tower.jpg" in candidates[0].extra["file"]
    assert "Special:FilePath" in candidates[0].url
    assert coords == (35.69, 139.69)


@pytest.mark.asyncio
async def test_fetch_candidates_no_p18_still_returns_coords(mock_http):
    mock_http.get.side_effect = [
        _resp(200, {"search": [{"id": "Q1490"}]}),
        _resp(200, {"entities": {"Q1490": _entity(p18=None)}}),
    ]
    candidates, coords = await WikidataCoverClient.fetch_candidates("Tokyo")
    assert candidates == []
    assert coords == (35.69, 139.69)
