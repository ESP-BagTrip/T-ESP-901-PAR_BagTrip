"""Tests for the central currency conversion helper (topic 04b, B8/B11).

Two surfaces under test:

- :func:`convert` is sync, total, and reads from the in-process cache.
  Cold-cache pairs degrade to identity (1.0) so a budget summary
  always renders.
- :func:`refresh_rates_async` is async and populates the cache from
  the ECB daily reference XML. Failures are swallowed by design.

Tests do NOT hit the live ECB endpoint — every async call goes through
a mocked ``httpx.AsyncClient.get`` exposed via ``get_http_client``.
"""

from __future__ import annotations

import time
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.services import currency_service


@pytest.fixture(autouse=True)
def _reset_cache():
    currency_service.reset_cache()
    yield
    currency_service.reset_cache()


_SAMPLE_ECB_XML = """<?xml version="1.0" encoding="UTF-8"?>
<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01"
                 xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
  <Cube>
    <Cube time="2026-05-02">
      <Cube currency="USD" rate="1.10"/>
      <Cube currency="GBP" rate="0.85"/>
      <Cube currency="JPY" rate="160.00"/>
    </Cube>
  </Cube>
</gesmes:Envelope>
"""


class TestNormalise:
    def test_uppercases(self):
        assert currency_service._normalise("usd") == "USD"

    def test_strips_whitespace(self):
        assert currency_service._normalise(" eur ") == "EUR"

    def test_falls_back_to_eur(self):
        assert currency_service._normalise(None) == "EUR"
        assert currency_service._normalise("") == "EUR"


class TestConvertSync:
    def test_same_currency_is_passthrough(self):
        assert currency_service.convert(100.0, from_="EUR", to="EUR") == 100.0

    def test_normalises_codes_before_compare(self):
        assert currency_service.convert(100.0, from_=" eur ", to="EUR") == 100.0

    def test_missing_codes_default_to_eur_passthrough(self):
        assert currency_service.convert(100.0, from_=None, to=None) == 100.0

    def test_cold_cache_falls_back_to_identity(self):
        # No refresh has run, so the cache has no EUR→USD pair. Conversion
        # must still return *something* — degraded, but not zero, so the
        # budget summary renders.
        assert currency_service.convert(100.0, from_="EUR", to="USD") == 100.0

    def test_warm_cache_uses_real_rate(self):
        # Manually warm the cache as ``refresh_rates_async`` would.
        with currency_service._lock:
            currency_service._rate_cache[("EUR", "USD")] = (1.10, time.monotonic())

        assert currency_service.convert(100.0, from_="EUR", to="USD") == pytest.approx(110.0)


class TestCacheDerivation:
    def test_inverse_pair_reuses_cached_rate(self):
        with currency_service._lock:
            currency_service._rate_cache[("EUR", "USD")] = (2.0, time.monotonic())

        assert currency_service.convert(100.0, from_="USD", to="EUR") == pytest.approx(50.0)

    def test_cross_rate_composes_via_eur(self):
        """USD → GBP = USD→EUR ∘ EUR→GBP, both EUR-base ECB pairs."""
        with currency_service._lock:
            now = time.monotonic()
            currency_service._rate_cache[("EUR", "USD")] = (1.10, now)
            currency_service._rate_cache[("EUR", "GBP")] = (0.85, now)

        # 100 USD → EUR → GBP
        # 100 USD = 100 / 1.10 EUR = 90.909... EUR
        # 90.909 EUR × 0.85 = 77.27 GBP
        result = currency_service.convert(100.0, from_="USD", to="GBP")
        assert result == pytest.approx(0.85 / 1.10 * 100, rel=1e-6)

    def test_expired_pair_falls_back_to_identity(self, monkeypatch):
        """Past the TTL, the cached rate is ignored."""
        # Pin "now" to make the rate look stale.
        with currency_service._lock:
            currency_service._rate_cache[("EUR", "USD")] = (
                1.10,
                time.monotonic() - currency_service._RATE_TTL_SECONDS - 10,
            )

        assert currency_service.convert(100.0, from_="EUR", to="USD") == 100.0


class TestEcbParser:
    def test_extracts_currency_to_rate_dict(self):
        rates = currency_service._parse_ecb_xml(_SAMPLE_ECB_XML)
        assert rates == {"USD": 1.10, "GBP": 0.85, "JPY": 160.00}

    def test_malformed_xml_returns_empty_dict(self):
        assert currency_service._parse_ecb_xml("<not xml>") == {}

    def test_skips_invalid_rate_strings(self):
        broken = """<?xml version="1.0" encoding="UTF-8"?>
<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01"
                 xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
  <Cube><Cube time="2026-05-02">
    <Cube currency="USD" rate="not-a-number"/>
    <Cube currency="GBP" rate="0.85"/>
  </Cube></Cube>
</gesmes:Envelope>"""
        rates = currency_service._parse_ecb_xml(broken)
        assert rates == {"GBP": 0.85}


class TestRefreshAsync:
    @pytest.mark.asyncio
    async def test_populates_cache_with_eur_base_pairs(self):
        client = MagicMock()
        response = MagicMock()
        response.text = _SAMPLE_ECB_XML
        response.raise_for_status = MagicMock()
        client.get = AsyncMock(return_value=response)

        with patch("src.services.currency_service.get_http_client", return_value=client):
            written = await currency_service.refresh_rates_async()

        assert written == 3
        # Now `convert` should use the real rate.
        assert currency_service.convert(100.0, from_="EUR", to="USD") == pytest.approx(110.0)
        assert currency_service.convert(100.0, from_="EUR", to="GBP") == pytest.approx(85.0)

    @pytest.mark.asyncio
    async def test_network_failure_does_not_raise(self):
        client = MagicMock()
        client.get = AsyncMock(side_effect=RuntimeError("ECB down"))

        with patch("src.services.currency_service.get_http_client", return_value=client):
            written = await currency_service.refresh_rates_async()

        assert written == 0
        # Cache stays empty -> identity fallback still works.
        assert currency_service.convert(100.0, from_="EUR", to="USD") == 100.0

    @pytest.mark.asyncio
    async def test_empty_payload_does_not_corrupt_cache(self):
        client = MagicMock()
        response = MagicMock()
        response.text = "<not xml>"
        response.raise_for_status = MagicMock()
        client.get = AsyncMock(return_value=response)

        # Pre-populate so we can assert the parse failure does NOT wipe.
        with currency_service._lock:
            currency_service._rate_cache[("EUR", "USD")] = (1.10, time.monotonic())

        with patch("src.services.currency_service.get_http_client", return_value=client):
            written = await currency_service.refresh_rates_async()

        assert written == 0
        # Pre-existing cached rate must still be honored.
        assert currency_service.convert(100.0, from_="EUR", to="USD") == pytest.approx(110.0)

    @pytest.mark.asyncio
    async def test_skips_non_positive_rates(self):
        broken = """<?xml version="1.0" encoding="UTF-8"?>
<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01"
                 xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
  <Cube><Cube time="2026-05-02">
    <Cube currency="USD" rate="0"/>
    <Cube currency="GBP" rate="0.85"/>
  </Cube></Cube>
</gesmes:Envelope>"""
        client = MagicMock()
        response = MagicMock()
        response.text = broken
        response.raise_for_status = MagicMock()
        client.get = AsyncMock(return_value=response)

        with patch("src.services.currency_service.get_http_client", return_value=client):
            await currency_service.refresh_rates_async()

        # USD pair must NOT have been written (rate was 0).
        with currency_service._lock:
            assert ("EUR", "USD") not in currency_service._rate_cache
            assert ("EUR", "GBP") in currency_service._rate_cache
