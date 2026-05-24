"""Tests for the Wikimedia Commons geosearch cover provider (SMP-330)."""

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from src.integrations.cover_image.commons import CommonsGeoCoverClient


@pytest.fixture
def mock_http():
    mock_client = AsyncMock()
    with patch(
        "src.integrations.cover_image.commons.get_http_client",
        return_value=mock_client,
    ):
        yield mock_client


def _resp(body: dict) -> httpx.Response:
    return httpx.Response(
        200,
        json=body,
        request=httpx.Request("GET", "https://commons.wikimedia.org/w/api.php"),
    )


@pytest.mark.asyncio
async def test_geosearch_filters_small_and_portrait_images(mock_http):
    # geosearch result list
    geo = {
        "query": {
            "geosearch": [
                {"title": "File:Shibuya.jpg"},
                {"title": "File:Mt_Fuji.jpg"},
                {"title": "File:Portrait_Shrine.jpg"},
                {"title": "File:Tiny.jpg"},
            ]
        }
    }
    info = {
        "query": {
            "pages": [
                {
                    "title": "File:Shibuya.jpg",
                    "imageinfo": [
                        {
                            "thumburl": "https://x/shibuya_1280.jpg",
                            "thumbwidth": 1280,
                            "thumbheight": 720,
                            "extmetadata": {
                                "Artist": {"value": "Alice"},
                                "LicenseShortName": {"value": "CC-BY-SA 4.0"},
                            },
                        }
                    ],
                },
                {
                    "title": "File:Mt_Fuji.jpg",
                    "imageinfo": [
                        {
                            "thumburl": "https://x/fuji_1280.jpg",
                            "thumbwidth": 1280,
                            "thumbheight": 853,
                            "extmetadata": {},
                        }
                    ],
                },
                {
                    "title": "File:Portrait_Shrine.jpg",
                    "imageinfo": [
                        {
                            "thumburl": "https://x/portrait.jpg",
                            "thumbwidth": 600,  # portrait (h > w) → skip
                            "thumbheight": 900,
                            "extmetadata": {},
                        }
                    ],
                },
                {
                    "title": "File:Tiny.jpg",
                    "imageinfo": [
                        {
                            "thumburl": "https://x/tiny.jpg",
                            "thumbwidth": 320,  # too small → skip
                            "thumbheight": 240,
                            "extmetadata": {},
                        }
                    ],
                },
            ]
        }
    }
    mock_http.get.side_effect = [_resp(geo), _resp(info)]

    candidates = await CommonsGeoCoverClient.fetch_candidates(35.69, 139.69, limit=5)

    assert len(candidates) == 2
    titles = [c.title for c in candidates]
    assert any("Shibuya" in t for t in titles)
    assert any("Fuji" in t for t in titles)
    shibuya = next(c for c in candidates if "Shibuya" in (c.title or ""))
    assert "Alice" in (shibuya.attribution or "")
    assert "CC-BY-SA" in (shibuya.attribution or "")


@pytest.mark.asyncio
async def test_geosearch_invalid_coords_returns_empty(mock_http):
    assert await CommonsGeoCoverClient.fetch_candidates(99.0, 0.0) == []
    assert await CommonsGeoCoverClient.fetch_candidates(0.0, 200.0) == []
    mock_http.get.assert_not_called()


@pytest.mark.asyncio
async def test_geosearch_empty_results(mock_http):
    mock_http.get.return_value = _resp({"query": {"geosearch": []}})
    assert await CommonsGeoCoverClient.fetch_candidates(35.69, 139.69) == []


@pytest.mark.asyncio
async def test_geosearch_network_failure(mock_http):
    mock_http.get.side_effect = httpx.ConnectError("boom")
    assert await CommonsGeoCoverClient.fetch_candidates(35.69, 139.69) == []
