"""Tests for the central currency conversion helper (topic 04b, B8/B11).

Phase 1 ships a stub fetcher that returns 1.0 for every pair, so the
contract under test is essentially:

- Same-currency conversion is a no-op (no fetch, no rate division).
- Different-currency conversion goes through the cache and returns
  ``amount × rate`` (rate = 1.0 today, not 1.0 once ECB plugs in).
- Empty / missing currency codes default to ``EUR``.
- The inverse cache halves upstream calls.
"""

from __future__ import annotations

import pytest

from src.services import currency_service


@pytest.fixture(autouse=True)
def _reset_cache():
    currency_service.reset_cache()
    yield
    currency_service.reset_cache()


class TestNormalise:
    def test_uppercases(self):
        assert currency_service._normalise("usd") == "USD"

    def test_strips_whitespace(self):
        assert currency_service._normalise(" eur ") == "EUR"

    def test_falls_back_to_eur(self):
        assert currency_service._normalise(None) == "EUR"
        assert currency_service._normalise("") == "EUR"


class TestConvert:
    def test_same_currency_is_passthrough(self):
        assert currency_service.convert(100.0, from_="EUR", to="EUR") == 100.0

    def test_normalises_codes_before_compare(self):
        assert currency_service.convert(100.0, from_=" eur ", to="EUR") == 100.0

    def test_missing_codes_default_to_eur_passthrough(self):
        assert currency_service.convert(100.0, from_=None, to=None) == 100.0

    def test_returns_float(self):
        result = currency_service.convert(100, from_="EUR", to="USD")
        assert isinstance(result, float)


class TestRateCache:
    def test_fetcher_called_once_per_pair(self, monkeypatch):
        """Topic 04b — once a rate is cached, subsequent converts hit the cache."""
        calls = {"n": 0}

        def fake_fetch(from_: str, to: str) -> float:
            calls["n"] += 1
            return 1.5

        monkeypatch.setattr(currency_service, "_fetch_rate", fake_fetch)

        a = currency_service.convert(100.0, from_="EUR", to="USD")
        b = currency_service.convert(200.0, from_="EUR", to="USD")

        assert a == 150.0
        assert b == 300.0
        assert calls["n"] == 1

    def test_inverse_pair_reuses_cached_rate(self, monkeypatch):
        """USD→EUR derives from EUR→USD without paying a second fetch."""
        calls = {"n": 0}

        def fake_fetch(from_: str, to: str) -> float:
            calls["n"] += 1
            assert (from_, to) == ("EUR", "USD")
            return 2.0

        monkeypatch.setattr(currency_service, "_fetch_rate", fake_fetch)

        # First call populates EUR→USD rate.
        currency_service.convert(100.0, from_="EUR", to="USD")
        # Second call, opposite direction — must NOT call _fetch_rate again.
        result = currency_service.convert(100.0, from_="USD", to="EUR")

        assert result == pytest.approx(50.0)
        assert calls["n"] == 1

    def test_stub_returns_one_to_one(self):
        """Default fetcher (phase 1) returns 1.0 — multi-currency safe to deploy."""
        assert currency_service.convert(123.45, from_="EUR", to="USD") == pytest.approx(
            123.45
        )
