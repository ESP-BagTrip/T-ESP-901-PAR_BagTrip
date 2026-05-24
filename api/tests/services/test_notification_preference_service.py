"""Unit tests for `NotificationPreferenceService`.

Covers the type->category gating matrix (`is_type_enabled`), the master
`push_enabled` switch, the ADMIN bypass, the default-when-no-row behaviour, and
`get_or_create` / `update`.
"""

from __future__ import annotations

import uuid
from unittest.mock import MagicMock

import pytest

from src.enums import NotificationType
from src.models.notification_preference import NotificationPreference
from src.services.notification_preference_service import NotificationPreferenceService


def _pref(**overrides) -> NotificationPreference:
    """Build a detached NotificationPreference with all flags on by default."""
    defaults: dict[str, object] = {
        "user_id": uuid.uuid4(),
        "push_enabled": True,
        "flight_reminders": True,
        "activity_reminders": True,
        "trip_updates": True,
        "budget_alerts": True,
        "social": True,
    }
    defaults.update(overrides)
    return NotificationPreference(**defaults)


def _db_with_pref(pref: NotificationPreference | None) -> MagicMock:
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = pref
    return db


# ---------------------------------------------------------------------------
# is_type_enabled — category mapping
# ---------------------------------------------------------------------------


class TestIsTypeEnabledMapping:
    @pytest.mark.parametrize(
        ("notif_type", "category"),
        [
            (NotificationType.DEPARTURE_REMINDER, "flight_reminders"),
            (NotificationType.FLIGHT_H4, "flight_reminders"),
            (NotificationType.FLIGHT_H1, "flight_reminders"),
            (NotificationType.ACTIVITY_H1, "activity_reminders"),
            (NotificationType.MORNING_SUMMARY, "trip_updates"),
            (NotificationType.TRIP_STARTED, "trip_updates"),
            (NotificationType.TRIP_ENDED, "trip_updates"),
            (NotificationType.BUDGET_ALERT, "budget_alerts"),
            (NotificationType.TRIP_SHARED, "social"),
        ],
    )
    def test_category_flag_off_disables_type(self, notif_type, category):
        pref = _pref(**{category: False})
        db = _db_with_pref(pref)
        assert NotificationPreferenceService.is_type_enabled(db, pref.user_id, notif_type) is False

    @pytest.mark.parametrize(
        ("notif_type", "category"),
        [
            (NotificationType.DEPARTURE_REMINDER, "flight_reminders"),
            (NotificationType.ACTIVITY_H1, "activity_reminders"),
            (NotificationType.MORNING_SUMMARY, "trip_updates"),
            (NotificationType.BUDGET_ALERT, "budget_alerts"),
            (NotificationType.TRIP_SHARED, "social"),
        ],
    )
    def test_category_flag_on_enables_type(self, notif_type, category):
        pref = _pref(**{category: True})
        db = _db_with_pref(pref)
        assert NotificationPreferenceService.is_type_enabled(db, pref.user_id, notif_type) is True

    def test_other_category_flag_does_not_affect_type(self):
        """Disabling social must not disable a flight reminder."""
        pref = _pref(social=False)
        db = _db_with_pref(pref)
        assert NotificationPreferenceService.is_type_enabled(
            db, pref.user_id, NotificationType.FLIGHT_H1
        )


class TestIsTypeEnabledAdminBypass:
    def test_admin_always_enabled_even_when_push_disabled(self):
        pref = _pref(push_enabled=False)
        db = _db_with_pref(pref)
        # ADMIN is not mapped to any category -> never blocked, and the query
        # should not even need to run.
        assert NotificationPreferenceService.is_type_enabled(
            db, pref.user_id, NotificationType.ADMIN
        )

    def test_unknown_type_always_enabled(self):
        db = _db_with_pref(_pref(push_enabled=False))
        assert NotificationPreferenceService.is_type_enabled(db, uuid.uuid4(), "GENERIC")


class TestIsTypeEnabledMasterSwitch:
    def test_push_disabled_blocks_every_category(self):
        pref = _pref(push_enabled=False)
        db = _db_with_pref(pref)
        for notif_type in (
            NotificationType.DEPARTURE_REMINDER,
            NotificationType.ACTIVITY_H1,
            NotificationType.MORNING_SUMMARY,
            NotificationType.BUDGET_ALERT,
            NotificationType.TRIP_SHARED,
        ):
            assert (
                NotificationPreferenceService.is_type_enabled(db, pref.user_id, notif_type) is False
            )


class TestIsTypeEnabledDefaults:
    def test_no_row_defaults_to_enabled(self):
        db = _db_with_pref(None)
        assert NotificationPreferenceService.is_type_enabled(
            db, uuid.uuid4(), NotificationType.FLIGHT_H4
        )


# ---------------------------------------------------------------------------
# get_or_create
# ---------------------------------------------------------------------------


class TestGetOrCreate:
    def test_returns_existing_without_insert(self):
        pref = _pref()
        db = _db_with_pref(pref)
        result = NotificationPreferenceService.get_or_create(db, pref.user_id)
        assert result is pref
        db.add.assert_not_called()

    def test_creates_default_row_when_absent(self):
        db = _db_with_pref(None)
        user_id = uuid.uuid4()
        result = NotificationPreferenceService.get_or_create(db, user_id)
        db.add.assert_called_once()
        assert db.commit.called
        assert isinstance(result, NotificationPreference)
        assert result.user_id == user_id


# ---------------------------------------------------------------------------
# update
# ---------------------------------------------------------------------------


class TestUpdate:
    def test_applies_provided_fields_only(self):
        pref = _pref()
        db = _db_with_pref(pref)
        result = NotificationPreferenceService.update(
            db, pref.user_id, push_enabled=False, social=False
        )
        assert result.push_enabled is False
        assert result.social is False
        # Untouched fields keep their value.
        assert result.flight_reminders is True
        assert db.commit.called

    def test_none_values_are_ignored(self):
        pref = _pref(flight_reminders=True)
        db = _db_with_pref(pref)
        result = NotificationPreferenceService.update(
            db, pref.user_id, flight_reminders=None, budget_alerts=False
        )
        assert result.flight_reminders is True
        assert result.budget_alerts is False

    def test_creates_row_when_absent(self):
        db = _db_with_pref(None)
        user_id = uuid.uuid4()
        result = NotificationPreferenceService.update(db, user_id, trip_updates=False)
        db.add.assert_called_once()
        assert result.trip_updates is False
