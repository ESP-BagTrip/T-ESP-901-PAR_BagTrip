"""Tests for enum migration mapping (A2+A3)."""

from src.enums import ActivityCategory, BaggageCategory


def test_activity_category_values():
    """Verify ActivityCategory enum has all expected values.

    SMP-324 added ``TRANSPORT`` so the AI ``activity_planner`` can emit
    transport recommendations (JR Pass, transfer aéroport, ...) as
    Activity rows, sharing the BudgetItem aggregation path with the
    dated itinerary instead of becoming orphan budget breakdown lines.
    """
    expected = {
        "CULTURE",
        "NATURE",
        "FOOD",
        "SPORT",
        "SHOPPING",
        "NIGHTLIFE",
        "RELAXATION",
        "TRANSPORT",
        "OTHER",
    }
    actual = {e.value for e in ActivityCategory}
    assert actual == expected


def test_activity_old_values_removed():
    """Verify legacy ActivityCategory values are gone.

    ``TRANSPORT`` was originally on this list because it had been
    removed in the A2/A3 migration; SMP-324 reintroduces it for AI
    transport recommendations, so it is excluded here.
    """
    values = {e.value for e in ActivityCategory}
    for old in ("VISIT", "RESTAURANT", "LEISURE"):
        assert old not in values, f"{old} should have been removed"


def test_baggage_category_values():
    """Verify new BaggageCategory enum has all expected values."""
    expected = {
        "DOCUMENTS",
        "CLOTHING",
        "ELECTRONICS",
        "TOILETRIES",
        "HEALTH",
        "ACCESSORIES",
        "OTHER",
    }
    actual = {e.value for e in BaggageCategory}
    assert actual == expected


def test_baggage_old_values_removed():
    """Verify old BaggageCategory values are gone."""
    values = {e.value for e in BaggageCategory}
    for old in ("CLOTHES", "HYGIENE"):
        assert old not in values, f"{old} should have been removed"


def test_activity_category_mapping():
    """Verify the expected renames map correctly."""
    assert ActivityCategory.CULTURE == "CULTURE"
    assert ActivityCategory.FOOD == "FOOD"
    assert ActivityCategory.RELAXATION == "RELAXATION"
    assert ActivityCategory.OTHER == "OTHER"


def test_baggage_category_mapping():
    """Verify the expected renames map correctly."""
    assert BaggageCategory.CLOTHING == "CLOTHING"
    assert BaggageCategory.TOILETRIES == "TOILETRIES"
    assert BaggageCategory.HEALTH == "HEALTH"
    assert BaggageCategory.ACCESSORIES == "ACCESSORIES"
