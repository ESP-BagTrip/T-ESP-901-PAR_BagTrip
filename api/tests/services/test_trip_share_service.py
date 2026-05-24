"""Unit tests for TripShareService — focused on the invite-email side-effect.

SMP327-038: creating a pending invite (invitee not yet registered) must fire a
best-effort trip-invite email so the recipient can act on the share. The send
is dispatched via TripShareService._send_invite_email and must never block or
break invite creation.
"""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.enums import ShareRole, TripStatus
from src.models.pending_invite import PendingInvite
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.services.trip_share_service import TripShareService


def _make_owner(**kw) -> MagicMock:
    owner = MagicMock(spec=User)
    owner.id = kw.get("id", uuid.uuid4())
    owner.email = kw.get("email", "owner@example.com")
    owner.full_name = kw.get("full_name", "Alice Owner")
    return owner


def _make_trip(**kw) -> MagicMock:
    trip = MagicMock(spec=Trip)
    trip.id = kw.get("id", uuid.uuid4())
    trip.title = kw.get("title", "Trip to Rome")
    trip.status = kw.get("status", TripStatus.PLANNED)
    return trip


def _build_db(*, trip, owner) -> MagicMock:
    """A db mock that dispatches db.query(Model) by model class.

    Pending-invite path query sequence:
      Trip   -> trip (completed check, post-commit lookup)
      User   -> first() None (invitee lookup), owner otherwise
      PendingInvite / TripShare -> empty (no existing, no quota hit)
    """
    db = MagicMock(name="Session")

    user_first_results = iter([None, owner, owner])  # invitee lookup, then owner lookups

    def _query(model):
        q = MagicMock()
        if model is Trip:
            q.filter.return_value.first.return_value = trip
        elif model is User:
            q.filter.return_value.first.side_effect = lambda: next(user_first_results, owner)
        elif model is PendingInvite:
            q.filter.return_value.first.return_value = None
            q.filter.return_value.count.return_value = 0
        elif model is TripShare:
            q.filter.return_value.count.return_value = 0
            q.filter.return_value.first.return_value = None
        else:  # pragma: no cover - defensive
            q.filter.return_value.first.return_value = None
            q.filter.return_value.count.return_value = 0
        return q

    db.query.side_effect = _query
    return db


@patch("src.services.plan_service.PlanService.get_share_limit", return_value=10)
@patch("src.services.device_token_service.DeviceTokenService.get_locale_for_user")
@patch("src.services.mailer_service.MailerService.send_trip_invite")
def test_pending_invite_triggers_invite_email(mock_send, mock_locale, _mock_limit):
    """Inviting a not-yet-registered email creates a PendingInvite AND emails it."""
    mock_locale.return_value = "fr"
    trip = _make_trip(title="Trip to Rome")
    owner = _make_owner(id=uuid.uuid4(), email="owner@example.com")
    db = _build_db(trip=trip, owner=owner)

    result = TripShareService.create_share(
        db=db,
        trip_id=trip.id,
        owner_user_id=owner.id,
        email="newperson@example.com",
        message=None,
        role=ShareRole.VIEWER,
    )

    assert result["status"] == "pending"
    mock_send.assert_called_once()
    kwargs = mock_send.call_args.kwargs
    assert kwargs["to_email"] == "newperson@example.com"
    assert kwargs["trip_title"] == "Trip to Rome"
    assert kwargs["inviter_name"] == "Alice Owner"
    assert kwargs["invite_token"] == result["invite_token"]
    assert kwargs["locale"] == "fr"


@patch("src.services.plan_service.PlanService.get_share_limit", return_value=10)
@patch("src.services.device_token_service.DeviceTokenService.get_locale_for_user")
@patch(
    "src.services.mailer_service.MailerService.send_trip_invite",
    side_effect=RuntimeError("mailer exploded"),
)
def test_invite_creation_survives_mailer_failure(mock_send, mock_locale, _mock_limit):
    """A mailer failure must never break invite creation."""
    mock_locale.return_value = "en"
    trip = _make_trip()
    owner = _make_owner()
    db = _build_db(trip=trip, owner=owner)

    # Should not raise even though send_trip_invite raises.
    result = TripShareService.create_share(
        db=db,
        trip_id=trip.id,
        owner_user_id=owner.id,
        email="newperson@example.com",
        role=ShareRole.VIEWER,
    )

    assert result["status"] == "pending"
    mock_send.assert_called_once()


@pytest.mark.asyncio
async def test_run_best_effort_schedules_on_running_loop():
    """With a running loop the coroutine is scheduled and completes."""
    ran = {"done": False}

    async def _coro():
        ran["done"] = True

    TripShareService._run_best_effort(_coro())
    # Yield control so the scheduled task runs.
    import asyncio

    await asyncio.sleep(0)
    assert ran["done"] is True


def test_run_best_effort_runs_inline_without_loop():
    """With no running loop the coroutine runs to completion synchronously."""
    ran = {"done": False}

    async def _coro():
        ran["done"] = True

    TripShareService._run_best_effort(_coro())
    assert ran["done"] is True


def _registered_user(**kw) -> MagicMock:
    user = MagicMock(spec=User)
    user.id = kw.get("id", uuid.uuid4())
    user.email = kw.get("email", "existing@example.com")
    user.full_name = kw.get("full_name", "Bob Existing")
    return user


@patch("src.services.plan_service.PlanService.get_share_limit", return_value=10)
@patch("src.services.device_token_service.DeviceTokenService.get_locale_for_user")
@patch("src.services.notification_service.NotificationService.send_localized")
@patch("src.services.mailer_service.MailerService.send_trip_invite")
def test_registered_user_share_does_not_email(mock_send, _mock_notif, mock_locale, _mock_limit):
    """Existing users get a push notification, not an invite email."""
    mock_locale.return_value = "en"
    trip = _make_trip()
    owner = _make_owner()
    invitee = _registered_user()

    db = MagicMock(name="Session")

    def _query(model):
        q = MagicMock()
        if model is Trip:
            q.filter.return_value.first.return_value = trip
        elif model is User:
            # invitee lookup returns a registered user; owner lookup returns owner
            results = iter([invitee, owner])
            q.filter.return_value.first.side_effect = lambda: next(results, owner)
        elif model is TripShare:
            q.filter.return_value.first.return_value = None
            q.filter.return_value.count.return_value = 0
        else:  # pragma: no cover
            q.filter.return_value.first.return_value = None
            q.filter.return_value.count.return_value = 0
        return q

    db.query.side_effect = _query

    result = TripShareService.create_share(
        db=db,
        trip_id=trip.id,
        owner_user_id=owner.id,
        email=invitee.email,
        role=ShareRole.VIEWER,
    )

    assert result["status"] == "active"
    mock_send.assert_not_called()
