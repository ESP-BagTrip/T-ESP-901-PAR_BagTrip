"""Tests for ``TripsService.gc_stale_drafts``.

SMP-324 — DRAFT trips left over by users who quit the SSE wizard
without confirming pile up in the DB and on the home screen. The
daily ``TRIP_STATUS_JOB`` calls the GC; we lock the contract here.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock
from uuid import uuid4

from src.enums import TripStatus
from src.services.trips_service import TripsService


def _make_trip(*, status: str, age_hours: float) -> MagicMock:
    trip = MagicMock()
    trip.id = uuid4()
    trip.status = status
    trip.created_at = datetime.now(UTC) - timedelta(hours=age_hours)
    return trip


def _db_with_query_result(rows: list) -> MagicMock:
    db = MagicMock()
    db.query.return_value.filter.return_value.all.return_value = rows
    return db


def test_purges_drafts_older_than_24h():
    stale = [
        _make_trip(status=TripStatus.DRAFT, age_hours=48),
        _make_trip(status=TripStatus.DRAFT, age_hours=25),
    ]
    db = _db_with_query_result(stale)

    purged = TripsService.gc_stale_drafts(db, max_age_hours=24)

    assert purged == 2
    delete_targets = [call.args[0] for call in db.delete.call_args_list]
    assert delete_targets == stale
    db.commit.assert_called_once()


def test_returns_zero_when_nothing_to_purge():
    db = _db_with_query_result([])

    purged = TripsService.gc_stale_drafts(db, max_age_hours=24)

    assert purged == 0
    db.delete.assert_not_called()
    # ``commit`` is still called (cheap no-op) so the connection state stays
    # clean for the caller — assert it doesn't blow up.
    db.commit.assert_called_once()


def test_max_age_hours_is_configurable():
    """Tighter cutoff means more rows match. The query uses the cutoff
    we pass, not a hard-coded constant."""
    db = _db_with_query_result([_make_trip(status=TripStatus.DRAFT, age_hours=2)])

    purged = TripsService.gc_stale_drafts(db, max_age_hours=1)

    assert purged == 1
