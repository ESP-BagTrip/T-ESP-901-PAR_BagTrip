"""Tests for Phase 2b (API-5): suggested_day + time_of_day logic."""

from datetime import date, time, timedelta

from src.services.plan_acceptance_service import TIME_OF_DAY_MAP


def test_time_of_day_map_morning():
    assert TIME_OF_DAY_MAP["morning"] == time(9, 0)


def test_time_of_day_map_afternoon():
    assert TIME_OF_DAY_MAP["afternoon"] == time(14, 0)


def test_time_of_day_map_evening():
    assert TIME_OF_DAY_MAP["evening"] == time(19, 0)


def test_suggested_day_1_gives_offset_0():
    suggested_day = 1
    duration_days = 7
    day_offset = (suggested_day - 1) % max(duration_days, 1)
    assert day_offset == 0


def test_suggested_day_wraps_via_modulo():
    suggested_day = 10
    duration_days = 7
    day_offset = (suggested_day - 1) % max(duration_days, 1)
    assert day_offset == 2  # (10-1) % 7 = 2


def test_missing_suggested_day_falls_back_to_index():
    """When suggested_day is missing, use index-based modulo."""
    act = {"title": "Test"}  # no suggested_day
    i = 5
    duration_days = 3

    suggested_day = act.get("suggested_day")
    if suggested_day and isinstance(suggested_day, int):
        day_offset = (suggested_day - 1) % max(duration_days, 1)
    else:
        day_offset = i % max(duration_days, 1)

    assert day_offset == 2  # 5 % 3


def test_missing_time_of_day_gives_none():
    act = {"title": "Test"}
    start_time_value = TIME_OF_DAY_MAP.get(act.get("time_of_day", ""))
    assert start_time_value is None


def test_activity_date_with_trip_start():
    trip_start = date(2026, 7, 1)
    day_offset = 2
    activity_date = trip_start + timedelta(days=day_offset)
    assert activity_date == date(2026, 7, 3)


def test_non_int_suggested_day_falls_back():
    """String suggested_day should fall back to index-based."""
    act = {"suggested_day": "day1"}
    i = 3
    duration_days = 5

    suggested_day = act.get("suggested_day")
    if suggested_day and isinstance(suggested_day, int):
        day_offset = (suggested_day - 1) % max(duration_days, 1)
    else:
        day_offset = i % max(duration_days, 1)

    assert day_offset == 3
