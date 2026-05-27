"""Unit tests for HomeService (SMP327-021)."""

import contextlib
import uuid
from datetime import UTC, date, datetime, time
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.services.home_service import HomeService


def _user():
    return SimpleNamespace(
        id=uuid.uuid4(),
        email="u@example.com",
        full_name="U",
        phone=None,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
        email_verified=True,
        plan="FREE",
        plan_expires_at=None,
    )


@contextlib.contextmanager
def _patch_user_enrichment():
    """Stub the /auth/me-equivalent enrichment used by HomeService."""
    with (
        patch(
            "src.services.profile_service.ProfileService.check_completion",
            return_value=(True, []),
        ),
        patch(
            "src.services.plan_service.PlanService.get_plan_info",
            new=AsyncMock(return_value={"ai_generations_remaining": 3}),
        ),
    ):
        yield


def _trip(status: str, activities=None):
    return SimpleNamespace(
        id=uuid.uuid4(),
        status=status,
        destination_name="Barcelona",
        start_date=date(2027, 12, 1),
        end_date=date(2027, 12, 10),
        activities=activities or [],
    )


def _activity(d, t):
    return SimpleNamespace(id=uuid.uuid4(), date=d, start_time=t)


def _db_returning(rows):
    """A MagicMock db whose query(...).union_all(...).order_by(...).all() == rows."""
    db = MagicMock()
    chain = MagicMock()
    chain.options.return_value = chain
    chain.filter.return_value = chain
    chain.join.return_value = chain
    chain.union_all.return_value = chain
    chain.order_by.return_value = chain
    chain.all.return_value = rows
    db.query.return_value = chain
    return db


@pytest.mark.asyncio
async def test_get_home_groups_and_active_trip():
    """Active trip (first ongoing) drives activities + weather; groups split by status."""
    act_late = _activity(date(2027, 12, 2), time(9, 0))
    act_early = _activity(date(2027, 12, 1), time(8, 0))
    ongoing = _trip("ONGOING", activities=[act_late, act_early])
    planned = _trip("PLANNED")
    completed = _trip("COMPLETED")

    rows = [(ongoing, "OWNER"), (planned, "OWNER"), (completed, "VIEWER")]
    db = _db_returning(rows)
    user = _user()

    with (
        _patch_user_enrichment(),
        patch(
            "src.services.weather_service.WeatherService.get_trip_weather",
            new=AsyncMock(return_value={"avg_temp_c": 18.0}),
        ) as mock_w,
    ):
        result = await HomeService.get_home(db, user)

    assert [t.status for t, _ in result["ongoing"]] == ["ONGOING"]
    assert [t.status for t, _ in result["planned"]] == ["PLANNED"]
    assert [t.status for t, _ in result["completed"]] == ["COMPLETED"]
    assert result["active_trip"] is ongoing
    # activities sorted by (date, start_time) ascending
    assert result["active_trip_activities"] == [act_early, act_late]
    assert result["active_trip_weather"] == {"avg_temp_c": 18.0}
    assert result["user"].email == "u@example.com"
    assert result["user"].ai_generations_remaining == 3
    mock_w.assert_awaited_once_with(ongoing)


@pytest.mark.asyncio
async def test_get_home_picks_earliest_ongoing_by_start_date():
    """Active trip is the ongoing trip with the earliest start_date, not list order."""
    act_a = _activity(date(2027, 12, 1), time(8, 0))
    act_b = _activity(date(2027, 12, 5), time(9, 0))
    later_ongoing = _trip("ONGOING", activities=[act_b])
    later_ongoing.start_date = date(2027, 12, 5)
    earlier_ongoing = _trip("ONGOING", activities=[act_a])
    earlier_ongoing.start_date = date(2027, 12, 1)

    # List order puts the later trip first (e.g. created_at desc).
    rows = [(later_ongoing, "OWNER"), (earlier_ongoing, "VIEWER")]
    db = _db_returning(rows)
    user = _user()

    with (
        _patch_user_enrichment(),
        patch(
            "src.services.weather_service.WeatherService.get_trip_weather",
            new=AsyncMock(return_value={"avg_temp_c": 20.0}),
        ) as mock_w,
    ):
        result = await HomeService.get_home(db, user)

    assert result["active_trip"] is earlier_ongoing
    assert result["active_trip_activities"] == [act_a]
    mock_w.assert_awaited_once_with(earlier_ongoing)


@pytest.mark.asyncio
async def test_get_home_no_active_trip_skips_weather():
    """No ongoing trip → active_trip None, no activities, no weather call."""
    planned = _trip("PLANNED")
    db = _db_returning([(planned, "OWNER")])
    user = _user()

    with (
        _patch_user_enrichment(),
        patch("src.services.weather_service.WeatherService.get_trip_weather") as mock_w,
    ):
        result = await HomeService.get_home(db, user)

    assert result["ongoing"] == []
    assert result["active_trip"] is None
    assert result["active_trip_activities"] == []
    assert result["active_trip_weather"] is None
    mock_w.assert_not_called()


@pytest.mark.asyncio
async def test_get_home_caps_groups_at_limit():
    """Each group is capped to HOME_GROUP_LIMIT page-1 rows."""
    from src.services.home_service import HOME_GROUP_LIMIT

    rows = [(_trip("PLANNED"), "OWNER") for _ in range(HOME_GROUP_LIMIT + 3)]
    db = _db_returning(rows)
    user = _user()

    with _patch_user_enrichment():
        result = await HomeService.get_home(db, user)

    assert len(result["planned"]) == HOME_GROUP_LIMIT
