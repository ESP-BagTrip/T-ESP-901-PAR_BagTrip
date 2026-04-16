"""Tests for latitude-aware weather fallback."""

from src.agent.tools import _fallback_weather

# ---------------------------------------------------------------------------
# Subarctic (55°+)
# ---------------------------------------------------------------------------


def test_subarctic_summer():
    result = _fallback_weather("2025-07-15", latitude=60)
    assert result["avg_temp_c"] == 18


def test_subarctic_winter():
    result = _fallback_weather("2025-12-15", latitude=60)
    assert result["avg_temp_c"] == -5


# ---------------------------------------------------------------------------
# Temperate (35-55°)
# ---------------------------------------------------------------------------


def test_temperate_summer():
    result = _fallback_weather("2025-07-15", latitude=45)
    assert result["avg_temp_c"] == 25


def test_temperate_winter():
    result = _fallback_weather("2025-01-15", latitude=45)
    assert result["avg_temp_c"] == 8


# ---------------------------------------------------------------------------
# Subtropical (23-35°)
# ---------------------------------------------------------------------------


def test_subtropical_summer():
    result = _fallback_weather("2025-07-15", latitude=30)
    assert result["avg_temp_c"] == 30


# ---------------------------------------------------------------------------
# Tropical (<23°)
# ---------------------------------------------------------------------------


def test_tropical_stable():
    result = _fallback_weather("2025-07-15", latitude=10)
    assert result["avg_temp_c"] == 28


def test_tropical_winter():
    result = _fallback_weather("2025-01-15", latitude=10)
    assert result["avg_temp_c"] == 28


# ---------------------------------------------------------------------------
# Southern hemisphere (season flip)
# ---------------------------------------------------------------------------


def test_southern_hemisphere_flip():
    """July at -35° = winter in southern hemisphere → temperate winter."""
    result = _fallback_weather("2025-07-15", latitude=-35)
    assert result["avg_temp_c"] == 8


def test_southern_hemisphere_summer():
    """January at -35° = summer in southern hemisphere → temperate summer."""
    result = _fallback_weather("2025-01-15", latitude=-35)
    assert result["avg_temp_c"] == 25


# ---------------------------------------------------------------------------
# No latitude (legacy fallback)
# ---------------------------------------------------------------------------


def test_no_latitude_month_fallback():
    """No latitude → original month-based estimate."""
    result = _fallback_weather("2025-07-15", latitude=None)
    assert result["avg_temp_c"] == 25


def test_no_latitude_default():
    """No latitude, no args → same as old behavior."""
    result = _fallback_weather("2025-07-15")
    assert result["avg_temp_c"] == 25


# ---------------------------------------------------------------------------
# Source field
# ---------------------------------------------------------------------------


def test_source_climate_zone():
    result = _fallback_weather("2025-07-15", latitude=45)
    assert result["source"] == "estimated_climate_zone"


def test_source_estimated():
    result = _fallback_weather("2025-07-15", latitude=None)
    assert result["source"] == "estimated"
