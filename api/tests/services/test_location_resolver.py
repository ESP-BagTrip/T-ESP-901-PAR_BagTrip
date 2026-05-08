"""Tests for :class:`LocationResolver` — the cascade resolver.

Covers:

- IATA pass-through (``"CDG"`` returns the airport directly).
- English-name match via the offline catalogue.
- Country-aware disambiguation when several airports share a name.
- Multilingual fallback through Open-Meteo geocoding (FR ``"Singapour"``).
- Open-Meteo HTTP failure → ``None`` (no silent garbage IATA).
- Cache round-trip (subsequent identical query hits the cache, not the
  network).
"""

from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest

from src.services.location_resolver import (
    LocationResolver,
    ResolvedLocation,
)
from src.utils.idempotency import idempotency_cache


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    # The idempotency cache is a process-level singleton; tests in this
    # module poison its state if we don't drop it between runs.
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]
    yield
    idempotency_cache._memory_cache.clear()  # type: ignore[attr-defined]


def _stub_open_meteo_geocoding_response(
    monkeypatch, response_payload: dict[str, Any] | None, status_code: int = 200
) -> None:
    """Patch the shared httpx client used by the resolver."""
    fake_response = MagicMock(spec=httpx.Response)
    fake_response.status_code = status_code
    fake_response.json = MagicMock(return_value=response_payload or {})
    fake_client = MagicMock()
    fake_client.get = AsyncMock(return_value=fake_response)
    monkeypatch.setattr("src.services.location_resolver.get_http_client", lambda: fake_client)
    return fake_client


# ── Resolver behaviour ────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_iata_passthrough(monkeypatch):
    """A 3-letter IATA code resolves directly via airportsdata."""
    fake_client = _stub_open_meteo_geocoding_response(monkeypatch, None)
    result = await LocationResolver.resolve("CDG")
    assert result is not None
    assert result.iata == "CDG"
    assert result.country_code == "FR"
    assert result.source == "airportsdata"
    fake_client.get.assert_not_awaited()


@pytest.mark.asyncio
async def test_english_keyword_match(monkeypatch):
    """A plain English city name is resolved offline (no network)."""
    fake_client = _stub_open_meteo_geocoding_response(monkeypatch, None)
    result = await LocationResolver.resolve("Paris")
    assert result is not None
    assert result.iata in {"CDG", "ORY", "PAR"}
    assert result.country_code == "FR"
    assert result.source == "airportsdata"
    fake_client.get.assert_not_awaited()


@pytest.mark.asyncio
async def test_country_disambiguates_namesakes(monkeypatch):
    """Manchester (UK) vs Manchester (US) — country hint pins the right one."""
    fake_client = _stub_open_meteo_geocoding_response(monkeypatch, None)
    result = await LocationResolver.resolve("Manchester", country_hint="United Kingdom")
    assert result is not None
    assert result.iata == "MAN"
    fake_client.get.assert_not_awaited()


@pytest.mark.asyncio
async def test_french_query_falls_back_to_open_meteo(monkeypatch):
    """'Singapour' is unknown to airportsdata → Open-Meteo geocoding kicks in."""
    fake_client = _stub_open_meteo_geocoding_response(
        monkeypatch,
        {
            "results": [
                {
                    "name": "Singapour",
                    "latitude": 1.28967,
                    "longitude": 103.85007,
                    "country": "Singapour",
                    "country_code": "SG",
                    "feature_code": "PPLC",
                    "population": 5_638_700,
                }
            ]
        },
    )
    result = await LocationResolver.resolve("Singapour", locale="fr")
    assert result is not None
    assert result.iata == "SIN"  # Singapore Changi
    assert result.country_code == "SG"
    assert result.source == "open-meteo+nearest"
    fake_client.get.assert_awaited()


@pytest.mark.asyncio
async def test_open_meteo_miss_returns_none(monkeypatch):
    """If Open-Meteo also misses, the resolver explicitly returns None.

    Silent fallbacks to garbage IATA codes were the worst quality issue
    in the audit (C5/C6); the resolver must never invent a result.
    """
    _stub_open_meteo_geocoding_response(monkeypatch, {"results": []})
    result = await LocationResolver.resolve("Zzqx-not-a-city", locale="fr")
    assert result is None


@pytest.mark.asyncio
async def test_open_meteo_http_error_returns_none(monkeypatch):
    """A 503 from Open-Meteo doesn't crash and doesn't fabricate a result."""
    _stub_open_meteo_geocoding_response(monkeypatch, None, status_code=503)
    result = await LocationResolver.resolve("Inconnueville", locale="fr")
    assert result is None


@pytest.mark.asyncio
async def test_cache_round_trip(monkeypatch):
    """A second identical resolve hits the cache and skips the network."""
    fake_client = _stub_open_meteo_geocoding_response(
        monkeypatch,
        {
            "results": [
                {
                    "name": "Singapour",
                    "latitude": 1.28967,
                    "longitude": 103.85007,
                    "country": "Singapour",
                    "country_code": "SG",
                    "feature_code": "PPLC",
                    "population": 5_000_000,
                }
            ]
        },
    )
    first = await LocationResolver.resolve("Singapour", locale="fr")
    second = await LocationResolver.resolve("Singapour", locale="fr")
    assert first is not None
    assert second is not None
    assert second.iata == first.iata
    assert second.source == "cache"
    # Geocoding endpoint hit only once (the cached path skips the network).
    assert fake_client.get.await_count == 1


@pytest.mark.asyncio
async def test_blank_input_returns_none(monkeypatch):
    _stub_open_meteo_geocoding_response(monkeypatch, None)
    assert await LocationResolver.resolve("") is None
    assert await LocationResolver.resolve("   ") is None


# ── Dataclass surface ─────────────────────────────────────────────────


def test_resolved_location_to_dict_round_trip():
    """The cache serialiser must preserve every field."""
    original = ResolvedLocation(
        iata="CDG",
        city="Paris",
        country="France",
        country_code="FR",
        lat=49.0,
        lon=2.55,
        source="airportsdata",
        raw_query="Paris",
        raw_locale="en",
    )
    payload = original.__dict__.copy()
    assert payload["iata"] == "CDG"
    assert payload["country_code"] == "FR"
