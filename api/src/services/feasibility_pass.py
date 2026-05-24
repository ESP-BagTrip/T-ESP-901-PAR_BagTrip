"""Deterministic feasibility pass over a brainstormed activity list.

The LLM produces ideas, this module turns them into something the user
can actually live with on a calendar:

- Drop activities with empty / blank titles (defensive — LLMs sometimes
  emit half-rendered placeholders).
- Move outdoor categories (NATURE, SPORT) off rainy days when the
  weather forecast says so.
- Schedule undated activities into ``morning / afternoon / evening``
  slots, one per day, in chronological order.
- Demote duplicates that target the same slot to the next free one.
- Cap at three dated activities per day; the rest stay undated and the
  client renders them as side recommendations (``FOOD`` and
  ``TRANSPORT`` categories are intentionally never scheduled — they
  are restaurant tips and transit passes, not calendar events).

The pass is a pure function on ``TripDraftCommand``: it returns a new
list of :class:`ActivityDraft` objects without mutating the input.
"""

from __future__ import annotations

from src.services.full_plan_orchestrator import (
    ActivityDraft,
    TripDraftCommand,
    WeatherSummary,
)

# ── Tunables ───────────────────────────────────────────────────────────

#: Probability threshold (%) above which the day is treated as "rainy"
#: and outdoor activities are pushed to a different day if possible.
RAIN_PROBABILITY_RAINY_DAY = 60.0

#: Categories the wizard never anchors to a slot — they remain in the
#: deck as side recommendations.
_UNDATED_CATEGORIES = frozenset({"FOOD", "TRANSPORT"})

#: Categories that are rain-sensitive.
_OUTDOOR_CATEGORIES = frozenset({"NATURE", "SPORT"})

_TIME_SLOTS: tuple[str, str, str] = ("morning", "afternoon", "evening")


# ── Public API ─────────────────────────────────────────────────────────


def schedule_activities(cmd: TripDraftCommand) -> list[ActivityDraft]:
    """Apply the deterministic scheduler to ``cmd.activities``.

    Returns a new list; the caller is expected to do
    ``cmd.activities = schedule_activities(cmd)`` before persistence.
    """
    activities = [a for a in cmd.activities if (a.title or "").strip()]
    if not activities:
        return []

    duration_days = max(cmd.duration_days, 1)
    weather = cmd.weather

    # Step 1 — split between activities the planner anchors and the
    # ones that stay undated by design.
    anchored: list[ActivityDraft] = []
    undated: list[ActivityDraft] = []
    for act in activities:
        if act.category in _UNDATED_CATEGORIES:
            undated.append(_clone(act, suggested_day=None, time_of_day=None))
        else:
            anchored.append(act)

    # Step 2 — slot assignment. We walk the calendar day by day and
    # fill ``morning / afternoon / evening`` from the LLM's hint when
    # possible, otherwise sequentially.
    schedule: dict[tuple[int, str], ActivityDraft] = {}
    leftover: list[ActivityDraft] = []
    rainy_days = _rainy_days(duration_days, weather)

    for act in anchored:
        candidate = _candidate_slot(act, schedule, duration_days, rainy_days)
        if candidate is None:
            leftover.append(_clone(act, suggested_day=None, time_of_day=None))
            continue
        day_idx, time_of_day = candidate
        schedule[(day_idx, time_of_day)] = _clone(
            act, suggested_day=day_idx, time_of_day=time_of_day
        )

    # Step 3 — emit in calendar order so the SSE stream + UI render the
    # final list in the right sequence.
    ordered: list[ActivityDraft] = []
    for day in range(1, duration_days + 1):
        for slot in _TIME_SLOTS:
            scheduled = schedule.get((day, slot))
            if scheduled is not None:
                ordered.append(scheduled)
    ordered.extend(leftover)
    ordered.extend(undated)
    return ordered


# ── Internal helpers ──────────────────────────────────────────────────


def _candidate_slot(
    act: ActivityDraft,
    schedule: dict[tuple[int, str], ActivityDraft],
    duration_days: int,
    rainy_days: set[int],
) -> tuple[int, str] | None:
    """Return ``(day_idx, time_of_day)`` for ``act`` or ``None`` if no
    slot is reachable inside the trip window."""
    hinted_day = _normalise_day(act.suggested_day, duration_days)
    hinted_slot = act.time_of_day if act.time_of_day in _TIME_SLOTS else None
    is_rain_sensitive = act.category in _OUTDOOR_CATEGORIES

    # Pass 1 — honour the LLM's hint when it doesn't conflict with rain
    # avoidance and the slot is free.
    if hinted_day is not None and not (is_rain_sensitive and hinted_day in rainy_days):
        for slot in _slots_starting_at(hinted_slot):
            if (hinted_day, slot) not in schedule:
                return hinted_day, slot

    # Pass 2 — sequential search. Skip rainy days for outdoor activities
    # while at least one non-rainy day exists; otherwise allow rainy
    # days as a last resort.
    days_to_try = list(range(1, duration_days + 1))
    if is_rain_sensitive and len(rainy_days) < duration_days:
        days_to_try = [d for d in days_to_try if d not in rainy_days]
    for day in days_to_try:
        for slot in _TIME_SLOTS:
            if (day, slot) not in schedule:
                return day, slot

    # Final fallback — any free slot in the window, including rainy days.
    for day in range(1, duration_days + 1):
        for slot in _TIME_SLOTS:
            if (day, slot) not in schedule:
                return day, slot
    return None


def _slots_starting_at(preferred: str | None) -> list[str]:
    """Iterate slots starting with ``preferred`` (when set) and rolling.

    Keeps the LLM's "morning" hint as a soft preference; if it's already
    taken we try afternoon then evening before bouncing to another day.
    """
    if preferred is None or preferred not in _TIME_SLOTS:
        return list(_TIME_SLOTS)
    start = _TIME_SLOTS.index(preferred)
    return [_TIME_SLOTS[(start + i) % len(_TIME_SLOTS)] for i in range(len(_TIME_SLOTS))]


def _normalise_day(value: int | None, duration_days: int) -> int | None:
    if value is None or duration_days <= 0:
        return None
    if value < 1 or value > duration_days:
        return None
    return value


def _rainy_days(duration_days: int, weather: WeatherSummary | None) -> set[int]:
    """Identify which trip days should be treated as rainy.

    The current Open-Meteo summary is a single trip-wide forecast, so
    the heuristic is binary: the WHOLE trip is rainy or not. When
    finer-grained forecasts land we can pivot this to per-day data
    without changing the public API.
    """
    if weather is None:
        return set()
    if weather.rain_probability >= RAIN_PROBABILITY_RAINY_DAY:
        return set(range(1, duration_days + 1))
    return set()


def _clone(
    act: ActivityDraft,
    *,
    suggested_day: int | None,
    time_of_day: str | None,
) -> ActivityDraft:
    return ActivityDraft(
        title=act.title,
        description=act.description,
        category=act.category,
        estimated_cost=act.estimated_cost,
        suggested_day=suggested_day,
        time_of_day=time_of_day,
        location=act.location,
    )


__all__ = ["schedule_activities", "RAIN_PROBABILITY_RAINY_DAY"]
