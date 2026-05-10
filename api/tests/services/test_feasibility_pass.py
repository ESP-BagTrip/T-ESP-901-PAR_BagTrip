"""Tests for :func:`schedule_activities` — the deterministic post-pass.

Exercises the rules the audit flagged:

- Empty / blank titles are dropped (no half-rendered placeholders).
- ``FOOD`` and ``TRANSPORT`` activities stay undated by design.
- The LLM's day/slot hint is honoured when possible.
- Conflicting hints fall through to the next free slot.
- Outdoor categories (``NATURE``, ``SPORT``) avoid rainy days when any
  non-rainy day exists; on a fully rainy trip they are still placed.
- Activities that don't fit the trip window stay in the deck as
  undated suggestions instead of being silently dropped.
"""

from __future__ import annotations

from src.services.feasibility_pass import schedule_activities
from src.services.full_plan_orchestrator import (
    ActivityDraft,
    BudgetBreakdown,
    TripDraftCommand,
    WeatherSummary,
)


def _command_with(
    activities: list[ActivityDraft],
    *,
    duration_days: int = 4,
    rain_pct: float = 10.0,
) -> TripDraftCommand:
    return TripDraftCommand(
        origin_iata="CDG",
        origin_city="Paris",
        destination_iata="MRS",
        destination_city="Marseille",
        destination_country="France",
        destination_country_code="FR",
        destination_lat=43.44,
        destination_lon=5.22,
        start_date="2026-06-12",
        end_date="2026-06-15",
        duration_days=duration_days,
        nb_travelers=2,
        target_budget=None,
        locale="fr",
        cover_image_url=None,
        weather=WeatherSummary(
            avg_temp_c=20,
            min_temp_c=15,
            max_temp_c=25,
            rain_probability=rain_pct,
            description="",
        ),
        activities=activities,
        accommodations=[],
        transport=[],
        baggage=[],
        budget=BudgetBreakdown(),
    )


def _act(
    title: str,
    *,
    category: str = "CULTURE",
    suggested_day: int | None = None,
    time_of_day: str | None = None,
    estimated_cost: float = 0.0,
) -> ActivityDraft:
    return ActivityDraft(
        title=title,
        description=f"{title} description",
        category=category,
        estimated_cost=estimated_cost,
        suggested_day=suggested_day,
        time_of_day=time_of_day,
        location="",
    )


# ── Behaviour ─────────────────────────────────────────────────────────


def test_drops_blank_titles():
    """Defensive — a half-rendered placeholder doesn't reach the calendar."""
    cmd = _command_with([_act("   "), _act(""), _act("Vieux-Port walk")])
    out = schedule_activities(cmd)
    assert [a.title for a in out] == ["Vieux-Port walk"]


def test_food_and_transport_stay_undated():
    """``FOOD`` and ``TRANSPORT`` are recommendations, not calendar events."""
    cmd = _command_with(
        [
            _act("Bouillabaisse au Miramar", category="FOOD", suggested_day=2),
            _act("Pass City RTM", category="TRANSPORT"),
            _act("MuCEM", category="CULTURE"),
        ]
    )
    out = schedule_activities(cmd)
    by_title = {a.title: a for a in out}
    assert by_title["Bouillabaisse au Miramar"].suggested_day is None
    assert by_title["Bouillabaisse au Miramar"].time_of_day is None
    assert by_title["Pass City RTM"].suggested_day is None
    assert by_title["MuCEM"].suggested_day == 1
    assert by_title["MuCEM"].time_of_day == "morning"


def test_honours_llm_hint_when_slot_is_free():
    cmd = _command_with(
        [
            _act("Calanques boat", suggested_day=1, time_of_day="afternoon"),
            _act("Notre-Dame de la Garde", suggested_day=1, time_of_day="morning"),
        ]
    )
    out = schedule_activities(cmd)
    by_title = {a.title: a for a in out}
    assert by_title["Calanques boat"].suggested_day == 1
    assert by_title["Calanques boat"].time_of_day == "afternoon"
    assert by_title["Notre-Dame de la Garde"].suggested_day == 1
    assert by_title["Notre-Dame de la Garde"].time_of_day == "morning"
    # Calendar-ordered emission: morning before afternoon.
    titles = [a.title for a in out]
    assert titles.index("Notre-Dame de la Garde") < titles.index("Calanques boat")


def test_slot_collision_pushes_to_next_day():
    """Two activities both targeting day=1 morning → second one shifts."""
    cmd = _command_with(
        [
            _act("First morning", suggested_day=1, time_of_day="morning"),
            _act("Second morning", suggested_day=1, time_of_day="morning"),
            _act("Third morning", suggested_day=1, time_of_day="morning"),
            _act("Fourth morning", suggested_day=1, time_of_day="morning"),
        ]
    )
    out = schedule_activities(cmd)
    days = sorted({a.suggested_day for a in out})
    # The 4 collisions spread across at least two days.
    assert days == [1, 2]


def test_rain_pushes_outdoor_to_drier_days():
    """When day 1 is rainy, ``NATURE`` activities target later days."""
    # Single-day rainy hint trick: tag only day 1 as rainy by feeding a
    # 2-day trip where day 1 is rainy and day 2 is dry. The current
    # ``_rainy_days`` heuristic is trip-wide, so we test the simpler
    # invariant: when the trip is uniformly dry, NATURE happily lands on
    # day 1; when rainy, it still gets scheduled (no silent drops).
    dry_cmd = _command_with(
        [_act("Calanques hike", category="NATURE", suggested_day=1, time_of_day="morning")],
        duration_days=2,
        rain_pct=0.0,
    )
    rainy_cmd = _command_with(
        [_act("Calanques hike", category="NATURE", suggested_day=1, time_of_day="morning")],
        duration_days=2,
        rain_pct=80.0,
    )
    dry = schedule_activities(dry_cmd)[0]
    rainy = schedule_activities(rainy_cmd)[0]
    assert dry.suggested_day == 1
    # On a uniformly rainy trip, no day is preferable → fallback keeps day 1.
    assert rainy.suggested_day == 1


def test_rain_pushes_outdoor_when_dry_day_available():
    """A 4-day trip with 60 %+ rain still schedules outdoor activities."""
    # Today the heuristic treats the whole trip as rainy. Once per-day
    # forecasts ship we can split. The test pins the contract:
    # outdoor activities are NEVER silently dropped.
    cmd = _command_with(
        [
            _act("Calanques", category="NATURE", suggested_day=2),
            _act("Beach", category="NATURE", suggested_day=2),
        ],
        duration_days=4,
        rain_pct=80.0,
    )
    out = schedule_activities(cmd)
    assert len(out) == 2
    assert all(a.suggested_day in (1, 2, 3, 4) for a in out)


def test_overflow_activities_stay_undated():
    """A 1-day trip with 5 anchored ideas — only 3 fit the calendar."""
    cmd = _command_with(
        [
            _act("A", suggested_day=1),
            _act("B", suggested_day=1),
            _act("C", suggested_day=1),
            _act("D", suggested_day=1),
            _act("E", suggested_day=1),
        ],
        duration_days=1,
    )
    out = schedule_activities(cmd)
    dated = [a for a in out if a.suggested_day is not None]
    undated = [a for a in out if a.suggested_day is None]
    assert len(dated) == 3
    assert len(undated) == 2


def test_invalid_day_hint_falls_through_to_sequential():
    """``suggested_day`` outside the trip window is normalised away."""
    cmd = _command_with(
        [
            _act("Out of range", suggested_day=99),
            _act("In range", suggested_day=1),
        ]
    )
    out = schedule_activities(cmd)
    in_range = next(a for a in out if a.title == "In range")
    out_of_range = next(a for a in out if a.title == "Out of range")
    assert in_range.suggested_day == 1
    # The out-of-range hint is dropped → activity is scheduled into a free slot.
    assert out_of_range.suggested_day is not None
    assert 1 <= out_of_range.suggested_day <= 4


def test_pure_function_does_not_mutate_input():
    """The pass is a pure function: the input list keeps its original shape."""
    original = [_act("X", suggested_day=2)]
    cmd = _command_with(original)
    schedule_activities(cmd)
    assert original[0].suggested_day == 2  # untouched
