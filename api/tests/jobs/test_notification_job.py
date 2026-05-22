"""Tests for the notification scheduler job — timezone-aware morning summary."""

from __future__ import annotations

from datetime import UTC, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4
from zoneinfo import ZoneInfo

from src.jobs.notification_job import _check_morning_summary, _safe_zone


class TestSafeZone:
    def test_valid_iana_zone(self):
        assert _safe_zone("Europe/Paris") == ZoneInfo("Europe/Paris")

    def test_none_returns_utc(self):
        assert _safe_zone(None) is UTC

    def test_garbage_returns_utc(self):
        assert _safe_zone("Not/AZone") is UTC


def _trip(tz_name: str | None) -> MagicMock:
    trip = MagicMock()
    trip.id = uuid4()
    trip.user_id = uuid4()
    trip.title = "Rome"
    trip.destination_timezone = tz_name
    trip.shares = []
    return trip


def _db(trips: list, activities: list) -> MagicMock:
    """Mock session: first query() is the trips scan, the rest are activities."""
    db = MagicMock()
    trip_chain = MagicMock()
    trip_chain.options.return_value.filter.return_value.all.return_value = trips
    act_chain = MagicMock()
    act_chain.filter.return_value.all.return_value = activities

    state = {"n": 0}

    def _query(*_args, **_kwargs):
        state["n"] += 1
        return trip_chain if state["n"] == 1 else act_chain

    db.query.side_effect = _query
    return db


class TestMorningSummary:
    def test_sends_during_destination_morning(self):
        # 07:00 UTC → 09:00 in Europe/Paris (summer) → inside the 07-10 window.
        trip = _trip("Europe/Paris")
        db = _db([trip], [MagicMock(title="Colisée")])
        fixed = datetime(2026, 7, 1, 7, 0, tzinfo=UTC)

        with (
            patch("src.jobs.notification_job.datetime") as mock_dt,
            patch("src.jobs.notification_job.NotificationService") as mock_notif,
            patch("src.jobs.notification_job.DeviceTokenService"),
        ):
            mock_dt.now.return_value = fixed
            mock_notif._get_trip_recipients.return_value = [trip.user_id]
            mock_notif._already_sent.return_value = False
            count = _check_morning_summary(db)

        assert count == 1
        assert mock_notif.send_localized.called

    def test_skips_outside_destination_morning(self):
        # 07:00 UTC → 16:00 in Asia/Tokyo → outside the morning window.
        trip = _trip("Asia/Tokyo")
        db = _db([trip], [MagicMock(title="Colisée")])
        fixed = datetime(2026, 7, 1, 7, 0, tzinfo=UTC)

        with (
            patch("src.jobs.notification_job.datetime") as mock_dt,
            patch("src.jobs.notification_job.NotificationService") as mock_notif,
            patch("src.jobs.notification_job.DeviceTokenService"),
        ):
            mock_dt.now.return_value = fixed
            mock_notif._get_trip_recipients.return_value = [trip.user_id]
            mock_notif._already_sent.return_value = False
            count = _check_morning_summary(db)

        assert count == 0
        mock_notif.send_localized.assert_not_called()

    def test_skips_when_no_activities_today(self):
        trip = _trip("Europe/Paris")
        db = _db([trip], [])  # no activities
        fixed = datetime(2026, 7, 1, 7, 0, tzinfo=UTC)

        with (
            patch("src.jobs.notification_job.datetime") as mock_dt,
            patch("src.jobs.notification_job.NotificationService") as mock_notif,
            patch("src.jobs.notification_job.DeviceTokenService"),
        ):
            mock_dt.now.return_value = fixed
            mock_notif._get_trip_recipients.return_value = [trip.user_id]
            mock_notif._already_sent.return_value = False
            count = _check_morning_summary(db)

        assert count == 0
        mock_notif.send_localized.assert_not_called()
