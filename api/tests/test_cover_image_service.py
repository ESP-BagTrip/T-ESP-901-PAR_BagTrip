"""Tests for the cover image orchestration service (SMP-330)."""

from unittest.mock import AsyncMock, patch

import pytest

from src.integrations.cover_image.types import CoverCandidate
from src.services.cover_image.service import CoverImageService


@pytest.fixture(autouse=True)
def _clear_cache():
    CoverImageService._cache.clear()
    yield
    CoverImageService._cache.clear()


def _candidate(url: str, source: str = "wikipedia") -> CoverCandidate:
    return CoverCandidate(url=url, source=source, title=f"title for {url}")


@pytest.fixture
def fake_store():
    """A LocalCoverStore stand-in that returns predictable rehosted URLs."""
    store = AsyncMock()

    async def _fake(url: str) -> str | None:
        if not url or url == "fail":
            return None
        return f"https://local/covers/{url.rsplit('/', 1)[-1]}"

    store.fetch_and_store.side_effect = _fake
    return store


@pytest.mark.asyncio
async def test_pick_cover_returns_none_when_no_candidates(fake_store):
    service = CoverImageService(store=fake_store)

    with (
        patch(
            "src.services.cover_image.service.wikipedia_cover_client.fetch_candidates",
            AsyncMock(return_value=([], None)),
        ),
        patch(
            "src.services.cover_image.service.wikidata_cover_client.fetch_candidates",
            AsyncMock(return_value=([], None)),
        ),
        patch(
            "src.services.cover_image.service.commons_geo_cover_client.fetch_candidates",
            AsyncMock(return_value=[]),
        ),
        patch(
            "src.services.cover_image.service.rank_candidates",
            AsyncMock(side_effect=lambda d, c: c),
        ),
    ):
        result = await service.pick_cover("Nowhereville")

    assert result is None
    fake_store.fetch_and_store.assert_not_called()


@pytest.mark.asyncio
async def test_pick_cover_merges_and_dedupes_sources(fake_store):
    service = CoverImageService(store=fake_store)

    wiki = [_candidate("https://w/tokyo.jpg", "wikipedia")]
    wd = [_candidate("https://w/tokyo.jpg", "wikidata")]  # same URL → dedupe
    commons = [_candidate(f"https://c/{i}.jpg", "commons_geo") for i in range(3)]

    with (
        patch(
            "src.services.cover_image.service.wikipedia_cover_client.fetch_candidates",
            AsyncMock(return_value=(wiki, (35.69, 139.69))),
        ),
        patch(
            "src.services.cover_image.service.wikidata_cover_client.fetch_candidates",
            AsyncMock(return_value=(wd, None)),
        ),
        patch(
            "src.services.cover_image.service.commons_geo_cover_client.fetch_candidates",
            AsyncMock(return_value=commons),
        ),
        patch(
            "src.services.cover_image.service.rank_candidates",
            AsyncMock(side_effect=lambda d, c: c),
        ),
    ):
        result = await service.pick_cover("Tokyo")

    assert result is not None
    # 1 wiki + 0 wd (dup) + 3 commons = 4 unique, all rehosted
    assert len(result.candidates) == 4
    assert result.primary_url == "https://local/covers/tokyo.jpg"
    assert result.primary_source == "wikipedia"


@pytest.mark.asyncio
async def test_pick_cover_skips_commons_when_no_coords(fake_store):
    service = CoverImageService(store=fake_store)

    wiki = [_candidate("https://w/x.jpg", "wikipedia")]
    commons_mock = AsyncMock(return_value=[])

    with (
        patch(
            "src.services.cover_image.service.wikipedia_cover_client.fetch_candidates",
            AsyncMock(return_value=(wiki, None)),
        ),
        patch(
            "src.services.cover_image.service.wikidata_cover_client.fetch_candidates",
            AsyncMock(return_value=([], None)),
        ),
        patch(
            "src.services.cover_image.service.commons_geo_cover_client.fetch_candidates",
            commons_mock,
        ),
        patch(
            "src.services.cover_image.service.rank_candidates",
            AsyncMock(side_effect=lambda d, c: c),
        ),
    ):
        await service.pick_cover("Nowhere")

    commons_mock.assert_not_called()


@pytest.mark.asyncio
async def test_pick_cover_uses_cache_on_second_call(fake_store):
    service = CoverImageService(store=fake_store)

    wiki = [_candidate("https://w/x.jpg", "wikipedia")]
    wiki_mock = AsyncMock(return_value=(wiki, None))

    with (
        patch(
            "src.services.cover_image.service.wikipedia_cover_client.fetch_candidates",
            wiki_mock,
        ),
        patch(
            "src.services.cover_image.service.wikidata_cover_client.fetch_candidates",
            AsyncMock(return_value=([], None)),
        ),
        patch(
            "src.services.cover_image.service.commons_geo_cover_client.fetch_candidates",
            AsyncMock(return_value=[]),
        ),
        patch(
            "src.services.cover_image.service.rank_candidates",
            AsyncMock(side_effect=lambda d, c: c),
        ),
    ):
        first = await service.pick_cover("Tokyo")
        second = await service.pick_cover("Tokyo")

    assert first is not None and second is not None
    assert first.primary_url == second.primary_url
    # Wiki provider hit only once; the second call came from the Redis/memory cache.
    assert wiki_mock.call_count == 1


@pytest.mark.asyncio
async def test_refresh_cover_skips_excluded_urls(fake_store):
    service = CoverImageService(store=fake_store)

    raw = [_candidate("https://w/keep.jpg", "wikipedia")]
    excluded = [_candidate("https://w/skip.jpg", "wikipedia")]

    with (
        patch(
            "src.services.cover_image.service.wikipedia_cover_client.fetch_candidates",
            AsyncMock(return_value=(raw + excluded, None)),
        ),
        patch(
            "src.services.cover_image.service.wikidata_cover_client.fetch_candidates",
            AsyncMock(return_value=([], None)),
        ),
        patch(
            "src.services.cover_image.service.commons_geo_cover_client.fetch_candidates",
            AsyncMock(return_value=[]),
        ),
        patch(
            "src.services.cover_image.service.rank_candidates",
            AsyncMock(side_effect=lambda d, c: c),
        ),
    ):
        result = await service.refresh_cover(
            "Tokyo", exclude_urls={"https://w/skip.jpg"}
        )

    assert result is not None
    urls = {c.url for c in result.candidates}
    # Excluded URL must not appear under its original form (and not under
    # its rehosted form either, since rehost happens AFTER exclusion).
    assert all("skip.jpg" not in u for u in urls)
