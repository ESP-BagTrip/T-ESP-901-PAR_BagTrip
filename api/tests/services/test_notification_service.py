"""Unit tests for `NotificationService`.

The service orchestrates three side effects: DB insert(s), FCM push via
`_send_fcm`, and a `sent_at` back-fill on successful delivery. We mock
`DeviceTokenService.get_tokens_for_users` and Firebase to keep tests hermetic.
"""

from __future__ import annotations

import uuid
from datetime import timedelta
from unittest.mock import MagicMock, patch

from src.enums import NotificationType
from src.models.notification import Notification
from src.services.notification_service import NotificationService

# ---------------------------------------------------------------------------
# create_and_send
# ---------------------------------------------------------------------------


class TestCreateAndSend:
    def test_inserts_notification_and_commits(self, mock_db_session):
        with patch(
            "src.services.device_token_service.DeviceTokenService.get_tokens_for_users",
            return_value={},
        ):
            result = NotificationService.create_and_send(
                db=mock_db_session,
                user_id=uuid.uuid4(),
                trip_id=uuid.uuid4(),
                notif_type="DEPARTURE_REMINDER",
                title="Départ demain",
                body="Prépare tes bagages",
            )

        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called
        assert isinstance(result, Notification)
        assert result.title == "Départ demain"

    def test_sends_fcm_when_tokens_exist(self, mock_db_session):
        user_id = uuid.uuid4()
        with (
            patch(
                "src.services.device_token_service.DeviceTokenService.get_tokens_for_users",
                return_value={user_id: ["tok1"]},
            ),
            patch(
                "src.services.notification_service.NotificationService._send_fcm",
                return_value=True,
            ) as mock_send,
        ):
            notif = NotificationService.create_and_send(
                db=mock_db_session,
                user_id=user_id,
                trip_id=None,
                notif_type="GENERIC",
                title="T",
                body="B",
            )
        mock_send.assert_called_once()
        assert notif.sent_at is not None

    def test_no_sent_at_when_fcm_fails(self, mock_db_session):
        user_id = uuid.uuid4()
        with (
            patch(
                "src.services.device_token_service.DeviceTokenService.get_tokens_for_users",
                return_value={user_id: ["tok1"]},
            ),
            patch(
                "src.services.notification_service.NotificationService._send_fcm",
                return_value=False,
            ),
        ):
            notif = NotificationService.create_and_send(
                db=mock_db_session,
                user_id=user_id,
                trip_id=None,
                notif_type="GENERIC",
                title="T",
                body="B",
            )
        assert notif.sent_at is None


# ---------------------------------------------------------------------------
# create_and_send_bulk
# ---------------------------------------------------------------------------


class TestCreateAndSendBulk:
    def test_bulk_insert_for_each_recipient(self, mock_db_session):
        user_ids = [uuid.uuid4(), uuid.uuid4(), uuid.uuid4()]
        with patch(
            "src.services.device_token_service.DeviceTokenService.get_tokens_for_users",
            return_value={},
        ):
            notifs = NotificationService.create_and_send_bulk(
                db=mock_db_session,
                user_ids=user_ids,
                trip_id=uuid.uuid4(),
                notif_type="TRIP_STARTED",
                title="Bon voyage",
                body="Profite bien",
            )
        assert len(notifs) == 3
        assert mock_db_session.add.call_count == 3
        assert mock_db_session.commit.called

    def test_bulk_fcm_dispatch_stamps_sent_at_on_all(self, mock_db_session):
        u1, u2 = uuid.uuid4(), uuid.uuid4()
        with (
            patch(
                "src.services.device_token_service.DeviceTokenService.get_tokens_for_users",
                return_value={u1: ["t1"], u2: ["t2", "t3"]},
            ),
            patch(
                "src.services.notification_service.NotificationService._send_fcm",
                return_value=True,
            ),
        ):
            notifs = NotificationService.create_and_send_bulk(
                db=mock_db_session,
                user_ids=[u1, u2],
                trip_id=None,
                notif_type="GENERIC",
                title="T",
                body="B",
            )
        assert all(n.sent_at is not None for n in notifs)


# ---------------------------------------------------------------------------
# get_for_user / get_unread_count
# ---------------------------------------------------------------------------


class TestGetForUser:
    def test_pagination_math(self, make_notification):
        """get_for_user issues two query chains; we stub them with a side_effect
        so each `db.query(Notification)` call returns its own pre-configured mock."""
        from unittest.mock import MagicMock

        notifs = [make_notification() for _ in range(3)]

        # Chain 1: items + total
        items_chain = MagicMock()
        items_chain.count.return_value = 50
        items_chain.offset.return_value.limit.return_value.all.return_value = notifs
        items_chain.filter.return_value = items_chain
        items_chain.order_by.return_value = items_chain

        # Chain 2: unread count
        unread_chain = MagicMock()
        unread_chain.filter.return_value = unread_chain
        unread_chain.count.return_value = 5

        db = MagicMock()
        db.query.side_effect = [items_chain, unread_chain]

        items, total, total_pages, unread = NotificationService.get_for_user(
            db, uuid.uuid4(), page=2, limit=20
        )
        assert items == notifs
        assert total == 50
        assert total_pages == 3
        assert unread == 5

    def test_get_unread_count_returns_filter_count(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.count.return_value = 7
        assert NotificationService.get_unread_count(mock_db_session, uuid.uuid4()) == 7


# ---------------------------------------------------------------------------
# mark_as_read / mark_all_as_read
# ---------------------------------------------------------------------------


class TestMarkAsRead:
    def test_mark_as_read_success(self, mock_db_session, make_notification):
        notif = make_notification(is_read=False)
        mock_db_session.query.return_value.filter.return_value.first.return_value = notif
        result = NotificationService.mark_as_read(mock_db_session, notif.id, notif.user_id)
        assert result is notif
        assert notif.is_read is True
        assert mock_db_session.commit.called

    def test_mark_as_read_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        result = NotificationService.mark_as_read(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert result is None
        assert not mock_db_session.commit.called

    def test_mark_all_as_read_returns_rowcount(self, mock_db_session):
        execute_result = MagicMock(rowcount=12)
        mock_db_session.execute.return_value = execute_result
        count = NotificationService.mark_all_as_read(mock_db_session, uuid.uuid4())
        assert count == 12
        assert mock_db_session.commit.called


# ---------------------------------------------------------------------------
# _get_trip_recipients
# ---------------------------------------------------------------------------


class TestTripRecipients:
    def test_owner_plus_viewers(self, mock_db_session, make_trip):
        trip = make_trip()
        viewer1, viewer2 = uuid.uuid4(), uuid.uuid4()
        mock_db_session.query.return_value.filter.return_value.all.return_value = [
            (viewer1,),
            (viewer2,),
        ]
        recipients = NotificationService._get_trip_recipients(mock_db_session, trip)
        assert trip.user_id in recipients
        assert viewer1 in recipients
        assert viewer2 in recipients
        assert len(recipients) == 3

    def test_owner_only_skips_viewers(self, mock_db_session, make_trip):
        trip = make_trip()
        recipients = NotificationService._get_trip_recipients(
            mock_db_session, trip, owner_only=True
        )
        assert recipients == [trip.user_id]
        # No filter query should have been issued for viewers
        assert mock_db_session.query.call_count == 0

    def test_duplicate_viewer_dedup(self, mock_db_session, make_trip):
        """If a viewer is also the owner, they only appear once."""
        trip = make_trip()
        mock_db_session.query.return_value.filter.return_value.all.return_value = [
            (trip.user_id,),  # duplicate
        ]
        recipients = NotificationService._get_trip_recipients(mock_db_session, trip)
        assert recipients == [trip.user_id]


# ---------------------------------------------------------------------------
# _already_sent
# ---------------------------------------------------------------------------


class TestAlreadySent:
    def test_returns_true_when_existing_notification_in_window(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = MagicMock()
        result = NotificationService._already_sent(
            mock_db_session,
            uuid.uuid4(),
            uuid.uuid4(),
            "DEPARTURE_REMINDER",
            timedelta(hours=20),
        )
        assert result is True

    def test_returns_false_when_nothing_in_window(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        result = NotificationService._already_sent(
            mock_db_session, uuid.uuid4(), None, "TYPE", timedelta(hours=1)
        )
        assert result is False


# ---------------------------------------------------------------------------
# check_and_send_budget_alert
# ---------------------------------------------------------------------------


class TestBudgetAlert:
    def test_no_alert_level_returns_early(self, mock_db_session, make_trip):
        trip = make_trip()
        with patch(
            "src.services.budget_item_service.BudgetItemService.get_budget_summary",
            return_value={"alert_level": None, "percent_consumed": 10},
        ):
            # Should not raise and should not call create_and_send
            NotificationService.check_and_send_budget_alert(mock_db_session, trip)

    def test_warning_alert_dispatches_notification(self, mock_db_session, make_trip):
        trip = make_trip()
        with (
            patch(
                "src.services.budget_item_service.BudgetItemService.get_budget_summary",
                return_value={"alert_level": "WARNING", "percent_consumed": 80},
            ),
            patch(
                "src.services.notification_service.NotificationService._already_sent",
                return_value=False,
            ),
            patch(
                "src.services.notification_service.NotificationService.create_and_send"
            ) as mock_send,
        ):
            NotificationService.check_and_send_budget_alert(mock_db_session, trip)
        mock_send.assert_called_once()
        kwargs = mock_send.call_args.kwargs
        assert kwargs["notif_type"] == NotificationType.BUDGET_ALERT
        assert "80%" in kwargs["body"]

    def test_already_sent_suppresses_notification(self, mock_db_session, make_trip):
        trip = make_trip()
        with (
            patch(
                "src.services.budget_item_service.BudgetItemService.get_budget_summary",
                return_value={"alert_level": "EXCEEDED", "percent_consumed": 110},
            ),
            patch(
                "src.services.notification_service.NotificationService._already_sent",
                return_value=True,
            ),
            patch(
                "src.services.notification_service.NotificationService.create_and_send"
            ) as mock_send,
        ):
            NotificationService.check_and_send_budget_alert(mock_db_session, trip)
        mock_send.assert_not_called()

    def test_budget_summary_exception_is_swallowed(self, mock_db_session, make_trip):
        trip = make_trip()
        with patch(
            "src.services.budget_item_service.BudgetItemService.get_budget_summary",
            side_effect=RuntimeError("db down"),
        ):
            # Must not raise — caller is a scheduler loop
            NotificationService.check_and_send_budget_alert(mock_db_session, trip)
