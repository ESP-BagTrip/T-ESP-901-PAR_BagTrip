"""Tests for `src.utils.locale.normalize_locale`."""

from __future__ import annotations

import pytest

from src.utils.locale import DEFAULT_LOCALE, normalize_locale


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("fr", "fr"),
        ("en", "en"),
        ("FR", "fr"),
        ("fr-FR", "fr"),
        ("fr_FR", "fr"),
        ("en-US", "en"),
        # Accept-Language with q-values: only the primary tag matters.
        ("fr-FR,en;q=0.8", "fr"),
        ("en-GB,fr;q=0.9", "en"),
    ],
)
def test_normalize_locale_supported(value: str, expected: str) -> None:
    assert normalize_locale(value) == expected


@pytest.mark.parametrize("value", [None, "", "  "])
def test_normalize_locale_empty_returns_default(value: str | None) -> None:
    assert normalize_locale(value) == DEFAULT_LOCALE


@pytest.mark.parametrize("value", ["es", "de-DE", "zz", "klingon"])
def test_normalize_locale_unsupported_returns_default(value: str) -> None:
    assert normalize_locale(value) == DEFAULT_LOCALE


def test_normalize_locale_custom_default() -> None:
    assert normalize_locale("es", default="fr") == "fr"
    assert normalize_locale(None, default="fr") == "fr"
