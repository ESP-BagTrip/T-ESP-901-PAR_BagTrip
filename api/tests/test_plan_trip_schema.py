"""Tests for Phase 1 (API-9): schema validation, enum, budget ranges."""

from src.api.ai.plan_trip_schemas import (
    BUDGET_PRESET_RANGES,
    AcceptPlanRequest,
    PlanTripRequest,
)
from src.enums import BudgetPreset


def test_budget_preset_enum_has_four_values():
    assert len(BudgetPreset) == 4
    assert set(BudgetPreset) == {"BACKPACKER", "COMFORTABLE", "PREMIUM", "NO_LIMIT"}


def test_budget_preset_ranges_covers_all_enum_values():
    for preset in BudgetPreset:
        assert preset.value in BUDGET_PRESET_RANGES, f"Missing range for {preset}"
        entry = BUDGET_PRESET_RANGES[preset.value]
        assert "min_per_day" in entry
        assert "max_per_day" in entry
        assert "label" in entry


def test_plan_trip_request_accepts_date_mode():
    req = PlanTripRequest(dateMode="EXACT")
    assert req.dateMode == "EXACT"


def test_plan_trip_request_accepts_budget_preset():
    req = PlanTripRequest(budgetPreset="COMFORTABLE")
    assert req.budgetPreset == "COMFORTABLE"


def test_plan_trip_request_accepts_mode():
    req = PlanTripRequest(mode="destinations_only")
    assert req.mode == "destinations_only"


def test_plan_trip_request_defaults_are_none():
    req = PlanTripRequest()
    assert req.dateMode is None
    assert req.budgetPreset is None
    assert req.mode is None


def test_accept_plan_request_selected_destination_index_default():
    req = AcceptPlanRequest(suggestion={})
    assert req.selectedDestinationIndex == 0


def test_accept_plan_request_selected_destination_index_custom():
    req = AcceptPlanRequest(suggestion={}, selectedDestinationIndex=2)
    assert req.selectedDestinationIndex == 2
