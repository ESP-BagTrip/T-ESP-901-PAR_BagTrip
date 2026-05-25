"""Tests for the content-addressed cover image store (SMP-330)."""

import hashlib
from unittest.mock import AsyncMock, patch

import httpx
import pytest

from src.services.cover_image.local_store import LocalCoverStore


@pytest.fixture
def store(tmp_path):
    return LocalCoverStore(
        storage_dir=str(tmp_path),
        public_base_url="https://example.test/covers",
    )


@pytest.fixture
def mock_http():
    mock_client = AsyncMock()
    with patch(
        "src.services.cover_image.local_store.get_http_client",
        return_value=mock_client,
    ):
        yield mock_client


def _resp(content: bytes, content_type: str = "image/jpeg") -> httpx.Response:
    return httpx.Response(
        200,
        content=content,
        headers={"content-type": content_type},
        request=httpx.Request("GET", "https://x/y.jpg"),
    )


@pytest.mark.asyncio
async def test_fetch_and_store_writes_sha256_named_file(store, mock_http, tmp_path):
    payload = b"\xff\xd8\xff\xe0fakejpeg"
    mock_http.get.return_value = _resp(payload, "image/jpeg")

    public_url = await store.fetch_and_store("https://x/y.jpg")

    expected = hashlib.sha256(payload).hexdigest() + ".jpg"
    assert public_url == f"https://example.test/covers/{expected}"
    assert (tmp_path / expected).read_bytes() == payload


@pytest.mark.asyncio
async def test_fetch_and_store_is_idempotent(store, mock_http):
    """Re-storing the same bytes should not write twice."""
    payload = b"same-bytes"
    mock_http.get.return_value = _resp(payload, "image/png")

    url1 = await store.fetch_and_store("https://x/a.png")
    url2 = await store.fetch_and_store("https://x/b.png")
    assert url1 == url2  # same hash → same file name


@pytest.mark.asyncio
async def test_fetch_and_store_picks_png_from_content_type(store, mock_http, tmp_path):
    payload = b"pngbytes"
    mock_http.get.return_value = _resp(payload, "image/png")

    url = await store.fetch_and_store("https://x/no-extension")
    assert url.endswith(".png")


@pytest.mark.asyncio
async def test_fetch_and_store_drops_oversized_payload(store, mock_http):
    payload = b"x" * (9 * 1024 * 1024)  # > 8 MB cap
    mock_http.get.return_value = _resp(payload)
    assert await store.fetch_and_store("https://x/big.jpg") is None


@pytest.mark.asyncio
async def test_fetch_and_store_handles_http_error(store, mock_http):
    mock_http.get.return_value = httpx.Response(
        404, request=httpx.Request("GET", "https://x/missing.jpg")
    )
    assert await store.fetch_and_store("https://x/missing.jpg") is None


@pytest.mark.asyncio
async def test_fetch_and_store_handles_network_failure(store, mock_http):
    mock_http.get.side_effect = httpx.ConnectError("boom")
    assert await store.fetch_and_store("https://x/y.jpg") is None


@pytest.mark.asyncio
async def test_fetch_and_store_empty_url_short_circuits(store, mock_http):
    assert await store.fetch_and_store("") is None
    mock_http.get.assert_not_called()
