"""Tests for the deterministic budget node.

Focus on the breakdown shape — every line must map onto a review-able
item the persistence layer can later create as a BudgetItem.
SMP-324 removed the per-diem table that fabricated unreviewable
food/transport averages; this test suite locks the new behaviour in.
"""

from __future__ import annotations

from unittest.mock import patch

import pytest

from src.agent.nodes.budget import (
    _build_estimation,
    _partition_activity_costs,
    budget_node,
)


# ---------------------------------------------------------------------------
# _partition_activity_costs — pure helper, no I/O
# ---------------------------------------------------------------------------


class TestPartitionActivityCosts:
    def test_empty_input_returns_zeros(self):
        food, transport, other = _partition_activity_costs([])
        assert food == 0.0
        assert transport == 0.0
        assert other == 0.0

    def test_food_activities_sum_into_food_bucket(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "FOOD", "estimated_cost": 35},
                {"category": "FOOD", "estimated_cost": 50},
            ]
        )
        assert food == 85.0
        assert transport == 0.0
        assert other == 0.0

    def test_transport_activities_sum_into_transport_bucket(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "TRANSPORT", "estimated_cost": 90},
                {"category": "TRANSPORT", "estimated_cost": 25},
            ]
        )
        assert transport == 115.0
        assert food == 0.0
        assert other == 0.0

    def test_other_categories_collapse_into_activity_bucket(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "CULTURE", "estimated_cost": 25},
                {"category": "NATURE", "estimated_cost": 10},
                {"category": "SPORT", "estimated_cost": 60},
                {"category": "OTHER", "estimated_cost": 15},
            ]
        )
        assert other == 110.0
        assert food == 0.0
        assert transport == 0.0

    def test_mixed_categories_partition_correctly(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "CULTURE", "estimated_cost": 25},
                {"category": "FOOD", "estimated_cost": 35},
                {"category": "TRANSPORT", "estimated_cost": 90},
                {"category": "NATURE", "estimated_cost": 10},
                {"category": "FOOD", "estimated_cost": 50},
            ]
        )
        assert food == 85.0
        assert transport == 90.0
        assert other == 35.0

    def test_zero_and_missing_costs_are_skipped(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "CULTURE", "estimated_cost": 0},
                {"category": "FOOD"},  # missing
                {"category": "FOOD", "estimated_cost": None},
                {"category": "TRANSPORT", "estimated_cost": "invalid"},
                {"category": "CULTURE", "estimated_cost": 25},
            ]
        )
        assert other == 25.0
        assert food == 0.0
        assert transport == 0.0

    def test_lowercase_category_normalises(self):
        food, transport, other = _partition_activity_costs(
            [
                {"category": "food", "estimated_cost": 35},
                {"category": "transport", "estimated_cost": 25},
            ]
        )
        assert food == 35.0
        assert transport == 25.0

    def test_missing_category_lands_in_activity_bucket(self):
        food, transport, other = _partition_activity_costs(
            [{"estimated_cost": 30}],
        )
        assert other == 30.0


# ---------------------------------------------------------------------------
# _build_estimation — deterministic SSE payload shape
# ---------------------------------------------------------------------------


class TestBuildEstimation:
    def test_zero_input_produces_zero_total(self):
        est = _build_estimation(
            flight_total=0,
            accommodation_total=0,
            food_total=0,
            transport_total=0,
            activity_total=0,
            flight_source="estimated",
            accommodation_source="deferred",
        )
        assert est["flight"]["amount"] == 0
        assert est["accommodation"]["amount"] == 0
        assert est["food"]["amount"] == 0
        assert est["transport"]["amount"] == 0
        assert est["activity"]["amount"] == 0
        assert est["total_min"] == 0
        assert est["total_max"] == 0

    def test_total_min_max_band_covers_15_percent(self):
        est = _build_estimation(
            flight_total=1000,
            accommodation_total=500,
            food_total=200,
            transport_total=100,
            activity_total=200,
            flight_source="amadeus",
            accommodation_source="amadeus",
        )
        # total = 2000 → ±15%
        assert est["total_min"] == 1700
        assert est["total_max"] == 2300

    def test_amounts_are_rounded_to_two_decimals(self):
        est = _build_estimation(
            flight_total=123.456,
            accommodation_total=99.999,
            food_total=10.014,
            transport_total=0,
            activity_total=0,
            flight_source="amadeus",
            accommodation_source="amadeus",
        )
        assert est["flight"]["amount"] == 123.46
        assert est["accommodation"]["amount"] == 100.0
        assert est["food"]["amount"] == 10.01

    def test_food_source_is_gathered_when_positive(self):
        est = _build_estimation(
            flight_total=0,
            accommodation_total=0,
            food_total=42,
            transport_total=0,
            activity_total=0,
            flight_source="estimated",
            accommodation_source="deferred",
        )
        assert est["food"]["source"] == "gathered_data"

    def test_food_source_is_estimated_when_zero(self):
        est = _build_estimation(
            flight_total=0,
            accommodation_total=0,
            food_total=0,
            transport_total=0,
            activity_total=0,
            flight_source="estimated",
            accommodation_source="deferred",
        )
        assert est["food"]["source"] == "estimated"

    def test_no_per_diem_metadata_leaks_into_payload(self):
        """SMP-324 — the food/transport lines used to ship a
        ``per_day_per_person`` field that the front-end could surface
        as a tooltip. Those lines no longer come from a per-diem table,
        so the metadata must be gone."""
        est = _build_estimation(
            flight_total=0,
            accommodation_total=0,
            food_total=85,
            transport_total=90,
            activity_total=0,
            flight_source="estimated",
            accommodation_source="deferred",
        )
        assert "per_day_per_person" not in est["food"]
        assert "per_day_per_person" not in est["transport"]


# ---------------------------------------------------------------------------
# budget_node — full path with mocked Amadeus
# ---------------------------------------------------------------------------


def _make_state(**overrides) -> dict:
    base = {
        "selected_destination": {"city": "Tokyo", "country": "Japon", "iata": "HND"},
        "origin_iata": "CDG",
        "departure_date": "2026-06-01",
        "return_date": "2026-06-08",
        "duration_days": 7,
        "nb_travelers": 1,
        "accommodations": [],
        "activities": [],
        "budget_deadline_monotonic": None,
    }
    base.update(overrides)
    return base


@pytest.mark.asyncio
class TestBudgetNode:
    async def test_food_transport_lines_track_typed_activities_only(self):
        """Σ phase 1 == Σ phase 2: each breakdown line equals the sum
        of the items the persistence layer will materialise."""
        state = _make_state(
            origin_iata="",  # skip flight search
            activities=[
                {"category": "FOOD", "estimated_cost": 35},
                {"category": "FOOD", "estimated_cost": 50},
                {"category": "TRANSPORT", "estimated_cost": 90},
                {"category": "CULTURE", "estimated_cost": 25},
                {"category": "NATURE", "estimated_cost": 10},
            ],
        )
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["food"]["amount"] == 85
        assert est["transport"]["amount"] == 90
        assert est["activity"]["amount"] == 35

    async def test_no_costed_activities_means_zero_food_transport_activity(self):
        """The agent surfaces only undated recommendations without
        prices: the breakdown lines are 0, never a fabricated average."""
        state = _make_state(
            origin_iata="",  # skip flight search
            activities=[
                {"category": "FOOD", "title": "Sushi Saito"},  # no cost
                {"category": "TRANSPORT", "title": "Suica card"},
            ],
        )
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["food"]["amount"] == 0
        assert est["transport"]["amount"] == 0
        assert est["activity"]["amount"] == 0

    async def test_accommodation_deferred_when_no_amadeus_hit(self):
        state = _make_state(origin_iata="", accommodations=[])
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["accommodation"]["amount"] == 0
        assert est["accommodation"]["source"] == "estimated"  # no accommodations entry at all

    async def test_accommodation_uses_price_total_when_available(self):
        state = _make_state(
            origin_iata="",
            accommodations=[{"price_total": 840, "price_per_night": 120, "nights": 7}],
        )
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["accommodation"]["amount"] == 840
        assert est["accommodation"]["source"] == "amadeus"

    async def test_accommodation_falls_back_to_per_night_when_no_total(self):
        state = _make_state(
            origin_iata="",
            accommodations=[{"price_per_night": 120, "nights": 7}],
        )
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["accommodation"]["amount"] == 840

    async def test_accommodation_source_deferred_when_marker_only(self):
        state = _make_state(
            origin_iata="",
            accommodations=[{"name": ""}],  # deferred marker, no price
        )
        result = await budget_node(state)
        est = result["budget_estimation"]
        assert est["accommodation"]["amount"] == 0
        assert est["accommodation"]["source"] == "deferred"

    async def test_synthetic_flight_when_amadeus_returns_no_offers(self):
        """Bug SMP-316 (Barcelone empty card) regression: when Amadeus
        returns nothing the node must still ship a plausible flight
        line so the review screen renders."""
        state = _make_state(activities=[])

        async def _empty_search(**_kwargs):
            return {"flights": []}

        with patch("src.agent.tools.search_real_flights", new=_empty_search):
            result = await budget_node(state)

        offers = result["flight_offers"]
        assert len(offers) == 1
        assert offers[0]["source"] == "estimated"
        assert result["budget_estimation"]["flight"]["amount"] > 0

    async def test_amadeus_flight_total_aggregates_offers(self):
        state = _make_state(activities=[])

        async def _amadeus_search(**_kwargs):
            return {"flights": [{"price": 950}]}

        with patch("src.agent.tools.search_real_flights", new=_amadeus_search):
            result = await budget_node(state)

        assert result["budget_estimation"]["flight"]["amount"] == 950
        assert result["budget_estimation"]["flight"]["source"] == "amadeus"

    async def test_emits_budget_event(self):
        state = _make_state(origin_iata="", activities=[])
        result = await budget_node(state)
        assert any(e["event"] == "budget" for e in result["events"])
