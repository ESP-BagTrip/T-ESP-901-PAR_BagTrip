"""End-to-end coverage of the budget flow (topic 09).

These tests exercise the full chain
``Trip create → BudgetItem add → get_budget_summary → redact_for_role``
through the actual service code (no FastAPI client / no DB —
service-level integration with mocks for the SQLAlchemy session). The
goal is to catch regressions that span topics: a fix in
``BudgetItemService`` that breaks the VIEWER masking, a contract change
that drops the currency conversion, etc.

Real DB-backed E2E (FT1 / FT3) live in ``bagtrip/integration_test/`` and
will get the multi-currency / viewer cases plugged in once the live
ECB fetcher is wired in (topic 04b phase 2).
"""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from src.api.auth.trip_access import TripRole
from src.api.common.redaction import redact_budget_summary_for_role
from src.enums import BudgetCategory
from src.services import currency_service
from src.services.budget_item_service import BudgetItemService


@pytest.fixture(autouse=True)
def _reset_currency_cache():
    currency_service.reset_cache()
    yield
    currency_service.reset_cache()


def _make_item(
    *,
    amount: float,
    currency: str = "EUR",
    category: str = "FOOD",
    source_type: str | None = None,
    is_planned: bool = True,
):
    item = MagicMock()
    item.amount = amount
    item.currency = currency
    item.category = category
    item.source_type = source_type
    item.is_planned = is_planned
    return item


def _make_trip(*, budget_target=1000, currency="EUR"):
    trip = MagicMock()
    trip.id = "trip-1"
    trip.budget_target = budget_target
    trip.budget_estimated = None
    trip.currency = currency
    return trip


def _make_db(items: list, activities: list | None = None) -> MagicMock:
    db = MagicMock()
    # `BudgetItemService.get_by_trip` calls db.query(BudgetItem)
    #   .filter(...).order_by(...).all() — chain returns `items`.
    items_chain = MagicMock()
    items_chain.filter.return_value = items_chain
    items_chain.order_by.return_value = items_chain
    items_chain.all.return_value = items

    # Activities lookup: db.query(Activity).filter(...).all() -> []
    activities_chain = MagicMock()
    activities_chain.filter.return_value = activities_chain
    activities_chain.all.return_value = activities or []

    # Different `db.query(...)` calls per model — distinguish by side effect.
    def query_dispatch(model, *_a, **_kw):
        from src.models.activity import Activity

        if model is Activity:
            return activities_chain
        return items_chain

    db.query.side_effect = query_dispatch
    return db


class TestBudgetSummaryFlow:
    def test_owner_sees_full_breakdown_with_target_alert(self):
        trip = _make_trip(budget_target=500)
        items = [
            _make_item(amount=300, source_type="manual"),
            _make_item(amount=150, source_type="activity"),
        ]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)

        assert summary["budget_target"] == 500.0
        assert summary["total_spent"] == pytest.approx(450.0)
        assert summary["remaining"] == pytest.approx(50.0)
        # 90% spent → WARNING (>= 80% threshold).
        assert summary["alert_level"] == "WARNING"

    def test_overbudget_path_sets_danger_alert(self):
        trip = _make_trip(budget_target=100)
        items = [_make_item(amount=120, source_type="manual")]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)

        assert summary["alert_level"] == "DANGER"
        assert "exceeded" in (summary["alert_message"] or "").lower()

    def test_b1_total_spent_authoritative_through_full_chain(self):
        """Topic 03 (B1) — the home stat and the panel total agree end-to-end."""
        trip = _make_trip(budget_target=1000)
        items = [
            _make_item(amount=120, category=BudgetCategory.FOOD),
            _make_item(amount=80, category=BudgetCategory.TRANSPORT),
        ]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)

        assert summary["total_spent"] == pytest.approx(200.0)
        # by_category aggregates by enum bucket
        assert summary["by_category"][BudgetCategory.FOOD] == pytest.approx(120.0)
        assert summary["by_category"][BudgetCategory.TRANSPORT] == pytest.approx(80.0)


class TestViewerRedactionFlow:
    def test_viewer_sees_only_target_and_status_after_redaction(self):
        """Topic 06 (B9) — the redaction step strips every reconstructible field."""
        trip = _make_trip(budget_target=1000)
        items = [_make_item(amount=850, source_type="manual")]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)
        redacted = redact_budget_summary_for_role(summary, TripRole.VIEWER)

        # Target shape kept
        assert redacted["budget_target"] == 1000.0
        # All reconstructible numbers zeroed / nulled
        assert redacted["total_spent"] == 0.0
        assert redacted["confirmed_total"] == 0.0
        assert redacted["forecasted_total"] == 0.0
        assert redacted["budget_estimated"] is None
        assert redacted["percent_consumed"] is None
        # Coarse status replaces the f-string alert
        assert redacted["budget_status"] == "tight"

    def test_owner_path_untouched_by_redaction(self):
        trip = _make_trip(budget_target=200)
        items = [_make_item(amount=50, source_type="manual")]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)
        redacted = redact_budget_summary_for_role(summary, TripRole.OWNER)

        # Same dict, no copy — owner sees the raw payload
        assert redacted is summary


class TestMultiCurrencyFlow:
    def test_b8_b11_amounts_aggregate_in_trip_currency(self):
        """Topic 04b — once the cache is warmed by ``refresh_rates_async``,
        aggregation picks up the conversion automatically (no call-site
        change)."""
        import time as _time

        # Manually warm the cache as ``refresh_rates_async`` would after
        # an ECB pull (pair `EUR → USD = 1.10` ⇔ `USD → EUR ≈ 0.909`).
        with currency_service._lock:
            currency_service._rate_cache[("EUR", "USD")] = (1.10, _time.monotonic())

        trip = _make_trip(budget_target=1000, currency="EUR")
        items = [
            _make_item(amount=100, currency="EUR", source_type="manual"),
            _make_item(amount=110, currency="USD", source_type="manual"),
        ]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)

        # 100 EUR + (110 USD ÷ 1.10) = 200 EUR (USD→EUR derived from
        # the inverse of the EUR→USD cached pair).
        assert summary["total_spent"] == pytest.approx(200.0)

    def test_phase1_stub_keeps_eur_only_trips_unchanged(self):
        trip = _make_trip(budget_target=500, currency="EUR")
        items = [_make_item(amount=200, currency="EUR", source_type="manual")]
        db = _make_db(items)

        summary = BudgetItemService.get_budget_summary(db, trip)

        assert summary["total_spent"] == pytest.approx(200.0)
