"""Tests for the role-aware budget redaction helper (topic 06, B9)."""

from __future__ import annotations

import pytest

from src.api.auth.trip_access import TripRole
from src.api.common.redaction import (
    _semantic_status,
    redact_budget_summary_for_role,
)


_FULL_SUMMARY = {
    "total_budget": 1000.0,
    "budget_target": 1000.0,
    "budget_estimated": 950.0,
    "budget_actual": 600.0,
    "total_spent": 600.0,
    "remaining": 400.0,
    "by_category": {"FOOD": 300.0, "TRANSPORT": 300.0},
    "percent_consumed": 60.0,
    "alert_level": "WARNING",
    "alert_message": "60% of your budget has been used",
    "confirmed_total": 500.0,
    "forecasted_total": 100.0,
}


class TestSemanticStatus:
    @pytest.mark.parametrize(
        "spent, expected",
        [
            (0.0, "onTrack"),
            (799.0, "onTrack"),
            (800.0, "tight"),
            (999.0, "tight"),
            (1000.0, "overBudget"),
            (1500.0, "overBudget"),
        ],
    )
    def test_buckets(self, spent: float, expected: str):
        assert _semantic_status(target=1000.0, spent=spent) == expected

    def test_no_target_returns_none(self):
        assert _semantic_status(target=0, spent=500) is None


class TestRedactBudgetSummary:
    def test_owner_payload_is_untouched(self):
        result = redact_budget_summary_for_role(_FULL_SUMMARY, TripRole.OWNER)
        assert result is _FULL_SUMMARY  # same dict, no copy

    def test_editor_payload_is_untouched(self):
        result = redact_budget_summary_for_role(_FULL_SUMMARY, TripRole.EDITOR)
        assert result is _FULL_SUMMARY

    def test_viewer_keeps_target_drops_spent_and_breakdown(self):
        result = redact_budget_summary_for_role(_FULL_SUMMARY, TripRole.VIEWER)
        # Target shape kept so the panel can render its layout
        assert result["total_budget"] == 1000.0
        assert result["budget_target"] == 1000.0
        # Reconstructible monetary fields zeroed / removed
        assert result["total_spent"] == 0.0
        assert result["remaining"] == 0.0
        assert result["by_category"] == {}
        assert result["budget_actual"] == 0.0
        assert result["confirmed_total"] == 0.0
        assert result["forecasted_total"] == 0.0
        assert result["budget_estimated"] is None
        # Ratio leaks (B9) plugged
        assert result["percent_consumed"] is None
        assert result["alert_level"] is None
        assert result["alert_message"] is None
        # Coarse-grained semantic bucket replaces the f-string message
        assert result["budget_status"] == "onTrack"

    def test_viewer_overbudget_status_does_not_leak_amount(self):
        over = dict(_FULL_SUMMARY, total_spent=2500.0)
        result = redact_budget_summary_for_role(over, TripRole.VIEWER)
        assert result["budget_status"] == "overBudget"
        # The actual figure (2500) must not surface anywhere.
        assert 2500.0 not in result.values()

    def test_viewer_no_target_yields_no_status(self):
        empty = dict(_FULL_SUMMARY, budget_target=0, total_budget=0)
        result = redact_budget_summary_for_role(empty, TripRole.VIEWER)
        assert result["budget_status"] is None
