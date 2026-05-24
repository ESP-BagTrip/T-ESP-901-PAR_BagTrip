"""Tests for the Wikipedia REST summary cover provider (SMP-330)."""

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from src.integrations.cover_image.wikipedia import WikipediaCoverClient


@pytest.fixture
def mock_http():
    """Patch the shared httpx client used by the Wikipedia provider."""
    mock_client = AsyncMock()
    with patch(
        "src.integrations.cover_image.wikipedia.get_http_client",
        return_value=mock_client,
    ):
        yield mock_client


def _response(status: int = 200, json_body: dict | None = None) -> httpx.Response:
    return httpx.Response(
        status,
        json=json_body or {},
        request=httpx.Request("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/x"),
    )


@pytest.mark.asyncio
async def test_fetch_summary_happy_path(mock_http):
    mock_http.get.return_value = _response(
        200,
        {
            "type": "standard",
            "title": "Tokyo",
            "displaytitle": "Tokyo",
            "originalimage": {
                "source": "https://upload.wikimedia.org/wikipedia/commons/x/tokyo.jpg",
                "width": 1500,
                "height": 1000,
            },
            "coordinates": {"lat": 35.69, "lon": 139.69},
        },
    )

    summary = await WikipediaCoverClient.fetch_summary("Tokyo", locale="en")

    assert summary is not None
    assert summary["title"] == "Tokyo"


@pytest.mark.asyncio
async def test_fetch_summary_404(mock_http):
    mock_http.get.return_value = _response(404, {})
    assert await WikipediaCoverClient.fetch_summary("NonExistent") is None


@pytest.mark.asyncio
async def test_fetch_summary_disambiguation_skipped(mock_http):
    mock_http.get.return_value = _response(
        200, {"type": "disambiguation", "title": "Paris"}
    )
    assert await WikipediaCoverClient.fetch_summary("Paris") is None


@pytest.mark.asyncio
async def test_fetch_summary_blank_query(mock_http):
    assert await WikipediaCoverClient.fetch_summary("   ") is None
    mock_http.get.assert_not_called()


@pytest.mark.asyncio
async def test_fetch_summary_network_failure(mock_http):
    mock_http.get.side_effect = httpx.ConnectError("boom")
    assert await WikipediaCoverClient.fetch_summary("Tokyo") is None


def test_candidate_from_summary_uses_original_image():
    summary = {
        "displaytitle": "Tokyo",
        "originalimage": {"source": "https://x/orig.jpg", "width": 1500, "height": 1000},
        "thumbnail": {"source": "https://x/thumb.jpg", "width": 320, "height": 240},
        "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Tokyo"}},
    }
    cand = WikipediaCoverClient.candidate_from_summary(summary)
    assert cand is not None
    assert cand.url == "https://x/orig.jpg"
    assert cand.source == "wikipedia"
    assert cand.width == 1500
    assert cand.extra["page_url"] == "https://en.wikipedia.org/wiki/Tokyo"


def test_candidate_from_summary_falls_back_to_thumbnail():
    summary = {
        "title": "Tokyo",
        "thumbnail": {"source": "https://x/thumb.jpg"},
    }
    cand = WikipediaCoverClient.candidate_from_summary(summary)
    assert cand is not None
    assert cand.url == "https://x/thumb.jpg"


def test_candidate_from_summary_no_image_returns_none():
    assert WikipediaCoverClient.candidate_from_summary({"title": "x"}) is None


def test_extract_coords():
    assert WikipediaCoverClient.extract_coords(
        {"coordinates": {"lat": 35.69, "lon": 139.69}}
    ) == (35.69, 139.69)
    assert WikipediaCoverClient.extract_coords({}) is None
    assert WikipediaCoverClient.extract_coords({"coordinates": {"lat": None}}) is None
    assert WikipediaCoverClient.extract_coords({"coordinates": {"lat": "abc"}}) is None


@pytest.mark.asyncio
async def test_fetch_candidates_falls_back_to_english(mock_http):
    """Locale-specific 404 should retry against English Wikipedia."""
    # First call (fr.wikipedia) → 404, second call (en.wikipedia) → 200.
    mock_http.get.side_effect = [
        _response(404, {}),
        _response(
            200,
            {
                "type": "standard",
                "title": "Tokyo",
                "originalimage": {"source": "https://x/tokyo.jpg"},
            },
        ),
    ]

    candidates, coords = await WikipediaCoverClient.fetch_candidates("Tokyo", locale="fr")
    assert len(candidates) == 1
    assert candidates[0].url == "https://x/tokyo.jpg"
    assert coords is None  # the EN response had no coords block
    assert mock_http.get.call_count == 2


@pytest.mark.asyncio
async def test_fetch_candidates_returns_coords(mock_http):
    mock_http.get.return_value = _response(
        200,
        {
            "type": "standard",
            "title": "Tokyo",
            "originalimage": {"source": "https://x/tokyo.jpg"},
            "coordinates": {"lat": 35.69, "lon": 139.69},
        },
    )
    candidates, coords = await WikipediaCoverClient.fetch_candidates("Tokyo")
    assert len(candidates) == 1
    assert coords == (35.69, 139.69)
