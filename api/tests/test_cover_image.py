"""Tests for Unsplash cover image integration."""

from unittest.mock import AsyncMock, patch

import httpx
import pytest

from src.integrations.unsplash.client import (
    _CACHE,
    UnsplashClient,
    _detect_continent,
)


@pytest.fixture(autouse=True)
def _clear_cache():
    """Clear the module-level cache between tests."""
    _CACHE.clear()
    yield
    _CACHE.clear()


@pytest.fixture
def mock_http_client():
    """Patch the shared http client singleton used by the Unsplash client.

    Prod code now pulls the AsyncClient from a process-wide singleton, so the
    tests patch the module symbol rather than constructing an AsyncClient per
    call.
    """
    mock_client = AsyncMock()
    with patch(
        "src.integrations.unsplash.client.get_http_client",
        return_value=mock_client,
    ):
        yield mock_client


# ---------------------------------------------------------------------------
# fetch_cover_image
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_fetch_success(mock_http_client):
    """Mock httpx → valid Unsplash response → URL extracted."""
    mock_response = httpx.Response(
        200,
        json={"results": [{"urls": {"regular": "https://images.unsplash.com/photo-abc?w=1080"}}]},
        request=httpx.Request("GET", "https://api.unsplash.com/search/photos"),
    )
    mock_http_client.get.return_value = mock_response

    with patch("src.integrations.unsplash.client.settings") as mock_settings:
        mock_settings.UNSPLASH_ACCESS_KEY = "test-key"
        result = await UnsplashClient.fetch_cover_image("Paris")

    assert result == "https://images.unsplash.com/photo-abc?w=1080"


@pytest.mark.asyncio
async def test_fetch_no_api_key():
    """UNSPLASH_ACCESS_KEY=None → returns None."""
    with patch("src.integrations.unsplash.client.settings") as mock_settings:
        mock_settings.UNSPLASH_ACCESS_KEY = None

        result = await UnsplashClient.fetch_cover_image("Paris")

    assert result is None


@pytest.mark.asyncio
async def test_fetch_api_error(mock_http_client):
    """Mock HTTP error → returns None."""
    mock_http_client.get.side_effect = httpx.HTTPStatusError(
        "500",
        request=httpx.Request("GET", "https://api.unsplash.com/search/photos"),
        response=httpx.Response(500),
    )
    with patch("src.integrations.unsplash.client.settings") as mock_settings:
        mock_settings.UNSPLASH_ACCESS_KEY = "test-key"
        result = await UnsplashClient.fetch_cover_image("Paris")

    assert result is None


@pytest.mark.asyncio
async def test_fetch_empty_results(mock_http_client):
    """Mock results: [] → returns None."""
    mock_http_client.get.return_value = httpx.Response(
        200,
        json={"results": []},
        request=httpx.Request("GET", "https://api.unsplash.com/search/photos"),
    )

    with patch("src.integrations.unsplash.client.settings") as mock_settings:
        mock_settings.UNSPLASH_ACCESS_KEY = "test-key"
        result = await UnsplashClient.fetch_cover_image("Nowhere")

    assert result is None


@pytest.mark.asyncio
async def test_cache_hit(mock_http_client):
    """Two calls with same destination → only 1 HTTP request."""
    mock_http_client.get.return_value = httpx.Response(
        200,
        json={
            "results": [{"urls": {"regular": "https://images.unsplash.com/photo-cached?w=1080"}}]
        },
        request=httpx.Request("GET", "https://api.unsplash.com/search/photos"),
    )

    with patch("src.integrations.unsplash.client.settings") as mock_settings:
        mock_settings.UNSPLASH_ACCESS_KEY = "test-key"
        result1 = await UnsplashClient.fetch_cover_image("Tokyo")
        result2 = await UnsplashClient.fetch_cover_image("Tokyo")

    assert result1 == result2
    assert mock_http_client.get.call_count == 1


# ---------------------------------------------------------------------------
# get_fallback_url
# ---------------------------------------------------------------------------


def test_fallback_known_continent():
    """Tokyo, Japan → Asia URL (non-empty)."""
    url = UnsplashClient.get_fallback_url("Tokyo, Japan")
    assert url
    assert "unsplash.com" in url


def test_fallback_unknown():
    """Unknown destination → default URL (non-empty)."""
    url = UnsplashClient.get_fallback_url("xyz")
    assert url
    assert "unsplash.com" in url


# ---------------------------------------------------------------------------
# _detect_continent
# ---------------------------------------------------------------------------


def test_detect_continent_asia():
    assert _detect_continent("Tokyo, Japan") == "asia"


def test_detect_continent_europe():
    assert _detect_continent("Paris, France") == "europe"


def test_detect_continent_default():
    assert _detect_continent("xyz123") == "default"
