"""Tests for TRIP_SHARED notification on share creation."""

from unittest.mock import MagicMock, patch
from uuid import uuid4

from src.enums import NotificationType, TripStatus
from src.models.trip import Trip
from src.models.user import User


def _make_user(email="invited@example.com", full_name="Invited User"):
    user = MagicMock(spec=User)
    user.id = uuid4()
    user.email = email
    user.full_name = full_name
    return user


def _make_owner(email="owner@example.com", full_name="Trip Owner"):
    return _make_user(email=email, full_name=full_name)


def _make_trip(user_id, title="Vacances à Rome", status=TripStatus.PLANNED):
    trip = MagicMock(spec=Trip)
    trip.id = uuid4()
    trip.user_id = user_id
    trip.title = title
    trip.status = status
    return trip


def _setup_db(owner, invited_user, trip):
    """Build a mock DB session that satisfies TripShareService.create_share queries.

    Call order in create_share:
      1. db.query(Trip).filter(...).first()   → trip  (_check_trip_not_completed)
      2. db.query(User).filter(...).first()   → invited_user  (email lookup)
      3. db.query(TripShare).filter(...).first() → None  (already shared check)
      4. db.query(User).filter(...).first()   → owner  (quota owner lookup)
      5. db.query(TripShare).filter(...).count() → 0  (quota count)
      6. db.query(Trip).filter(...).first()   → trip  (notification trip lookup)
    """
    db = MagicMock()

    # Build sequential query chain results
    call_index = {"i": 0}
    # Each entry: (first_return, count_return)
    responses = [
        (trip, None),  # 1. _check_trip_not_completed → Trip
        (invited_user, None),  # 2. email lookup → User
        (None, None),  # 3. already shared check → None
        (owner, None),  # 4. owner lookup for quota
        (None, 0),  # 5. share count for quota
        (trip, None),  # 6. trip lookup for notification
    ]

    def query_side_effect(model):
        chain = MagicMock()

        def filter_side_effect(*args, **kwargs):
            idx = call_index["i"]
            call_index["i"] += 1
            filter_chain = MagicMock()
            if idx < len(responses):
                first_val, count_val = responses[idx]
                filter_chain.first.return_value = first_val
                if count_val is not None:
                    filter_chain.count.return_value = count_val
            return filter_chain

        chain.filter.side_effect = filter_side_effect
        return chain

    db.query.side_effect = query_side_effect
    return db


PATCH_CREATE_AND_SEND = "src.services.notification_service.NotificationService.create_and_send"
PATCH_SHARE_LIMIT = "src.services.plan_service.PlanService.get_share_limit"


@patch(PATCH_CREATE_AND_SEND)
@patch(PATCH_SHARE_LIMIT, return_value=10)
def test_trip_shared_notification_sent_on_share_creation(mock_plan, mock_create_and_send):
    """create_and_send is called with TRIP_SHARED when a share is created."""
    owner = _make_owner()
    invited = _make_user()
    trip = _make_trip(owner.id)
    db = _setup_db(owner, invited, trip)

    from src.services.trip_share_service import TripShareService

    TripShareService.create_share(db, trip.id, owner.id, invited.email)

    mock_create_and_send.assert_called_once()
    call_kwargs = mock_create_and_send.call_args.kwargs
    assert call_kwargs["notif_type"] == NotificationType.TRIP_SHARED


@patch(PATCH_CREATE_AND_SEND)
@patch(PATCH_SHARE_LIMIT, return_value=10)
def test_trip_shared_notification_includes_owner_name(mock_plan, mock_create_and_send):
    """Notification body contains the owner's name."""
    owner = _make_owner(full_name="Alice Dupont")
    invited = _make_user()
    trip = _make_trip(owner.id)
    db = _setup_db(owner, invited, trip)

    from src.services.trip_share_service import TripShareService

    TripShareService.create_share(db, trip.id, owner.id, invited.email)

    call_kwargs = mock_create_and_send.call_args.kwargs
    assert "Alice Dupont" in call_kwargs["body"]


@patch(PATCH_CREATE_AND_SEND)
@patch(PATCH_SHARE_LIMIT, return_value=10)
def test_trip_shared_notification_includes_trip_title(mock_plan, mock_create_and_send):
    """Notification body contains the trip title."""
    owner = _make_owner()
    invited = _make_user()
    trip = _make_trip(owner.id, title="Weekend à Barcelone")
    db = _setup_db(owner, invited, trip)

    from src.services.trip_share_service import TripShareService

    TripShareService.create_share(db, trip.id, owner.id, invited.email)

    call_kwargs = mock_create_and_send.call_args.kwargs
    assert "Weekend à Barcelone" in call_kwargs["body"]


@patch(PATCH_CREATE_AND_SEND)
@patch(PATCH_SHARE_LIMIT, return_value=10)
def test_trip_shared_notification_targets_invited_user(mock_plan, mock_create_and_send):
    """Notification user_id is the invited user, not the owner."""
    owner = _make_owner()
    invited = _make_user()
    trip = _make_trip(owner.id)
    db = _setup_db(owner, invited, trip)

    from src.services.trip_share_service import TripShareService

    TripShareService.create_share(db, trip.id, owner.id, invited.email)

    call_kwargs = mock_create_and_send.call_args.kwargs
    assert call_kwargs["user_id"] == invited.id
    assert call_kwargs["user_id"] != owner.id


@patch(PATCH_CREATE_AND_SEND, side_effect=Exception("FCM down"))
@patch(PATCH_SHARE_LIMIT, return_value=10)
def test_share_still_works_if_notification_fails(mock_plan, mock_create_and_send):
    """Share is created even if the notification raises an exception."""
    owner = _make_owner()
    invited = _make_user()
    trip = _make_trip(owner.id)
    db = _setup_db(owner, invited, trip)

    from src.services.trip_share_service import TripShareService

    result = TripShareService.create_share(db, trip.id, owner.id, invited.email)

    # Share was still created and returned
    assert result["user_id"] == invited.id
    assert result["trip_id"] == trip.id


# ── delete_share -> TRIP_UNSHARED (SMP327-128) ──────────────────────────────

PATCH_SEND_LOCALIZED = "src.services.notification_service.NotificationService.send_localized"
PATCH_GET_LOCALE = "src.services.device_token_service.DeviceTokenService.get_locale_for_user"


def _setup_delete_db(trip, share):
    """Mock session for delete_share: trip (not-completed check), share lookup,
    then trip again for the notification body."""
    db = MagicMock()
    firsts = [trip, share, trip]
    idx = {"i": 0}

    def query_side_effect(model):
        chain = MagicMock()

        def filter_side_effect(*args, **kwargs):
            i = idx["i"]
            idx["i"] += 1
            fc = MagicMock()
            fc.first.return_value = firsts[i] if i < len(firsts) else None
            return fc

        chain.filter.side_effect = filter_side_effect
        return chain

    db.query.side_effect = query_side_effect
    return db


def _make_share(user_id):
    share = MagicMock()
    share.id = uuid4()
    share.user_id = user_id
    return share


@patch(PATCH_GET_LOCALE, return_value="en")
@patch(PATCH_SEND_LOCALIZED)
def test_delete_share_notifies_revoked_user(mock_send, _mock_locale):
    """Revoking a share pushes a TRIP_UNSHARED notification to the ex-collaborator."""
    owner = _make_owner()
    revoked_user = _make_user()
    trip = _make_trip(owner.id, title="Rome")
    share = _make_share(revoked_user.id)
    db = _setup_delete_db(trip, share)

    from src.services.trip_share_service import TripShareService

    TripShareService.delete_share(db, share.id, trip.id)

    db.delete.assert_called_once_with(share)
    mock_send.assert_called_once()
    kwargs = mock_send.call_args.kwargs
    assert kwargs["notif_type"] == NotificationType.TRIP_UNSHARED
    assert kwargs["user_id"] == revoked_user.id
    assert kwargs["context"]["trip_title"] == "Rome"


@patch(PATCH_GET_LOCALE, return_value="en")
@patch(PATCH_SEND_LOCALIZED, side_effect=Exception("FCM down"))
def test_delete_share_succeeds_even_if_notification_fails(mock_send, _mock_locale):
    """The revoke still commits even if the notification dispatch raises."""
    owner = _make_owner()
    revoked_user = _make_user()
    trip = _make_trip(owner.id)
    share = _make_share(revoked_user.id)
    db = _setup_delete_db(trip, share)

    from src.services.trip_share_service import TripShareService

    TripShareService.delete_share(db, share.id, trip.id)

    db.delete.assert_called_once_with(share)
    db.commit.assert_called()
