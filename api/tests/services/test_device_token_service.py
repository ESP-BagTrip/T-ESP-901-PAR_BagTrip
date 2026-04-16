"""Unit tests for `DeviceTokenService`."""

from __future__ import annotations

import uuid

from src.models.device_token import DeviceToken
from src.services.device_token_service import DeviceTokenService


class TestRegister:
    def test_inserts_new_token_when_none_exists(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        user_id = uuid.uuid4()

        result = DeviceTokenService.register(
            mock_db_session, user_id=user_id, fcm_token="tok-abc", platform="ios"
        )

        assert isinstance(result, DeviceToken)
        assert result.fcm_token == "tok-abc"
        assert result.user_id == user_id
        assert result.platform == "ios"
        mock_db_session.add.assert_called_once()
        assert mock_db_session.commit.called

    def test_updates_existing_token_on_collision(self, mock_db_session):
        existing = DeviceToken(
            user_id=uuid.uuid4(),
            fcm_token="tok-abc",
            platform="ios",
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing
        new_user_id = uuid.uuid4()

        result = DeviceTokenService.register(
            mock_db_session, user_id=new_user_id, fcm_token="tok-abc", platform="android"
        )

        assert result is existing
        assert result.user_id == new_user_id
        assert result.platform == "android"
        # Update path should NOT call .add
        mock_db_session.add.assert_not_called()
        assert mock_db_session.commit.called


class TestUnregister:
    def test_calls_delete_on_filter_chain(self, mock_db_session):
        user_id = uuid.uuid4()
        DeviceTokenService.unregister(mock_db_session, user_id=user_id, fcm_token="tok-abc")

        # delete() is called on the filter chain — verify commit fired.
        assert mock_db_session.commit.called
        mock_db_session.query.assert_called_once()


class TestGetTokensForUsers:
    def test_empty_list_short_circuits(self, mock_db_session):
        result = DeviceTokenService.get_tokens_for_users(mock_db_session, [])
        assert result == {}
        mock_db_session.query.assert_not_called()

    def test_groups_tokens_by_user_id(self, mock_db_session):
        u1, u2 = uuid.uuid4(), uuid.uuid4()
        mock_db_session.query.return_value.filter.return_value.all.return_value = [
            (u1, "tok1"),
            (u1, "tok2"),
            (u2, "tok3"),
        ]

        result = DeviceTokenService.get_tokens_for_users(mock_db_session, [u1, u2])

        assert result == {u1: ["tok1", "tok2"], u2: ["tok3"]}

    def test_no_rows_returns_empty_dict(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.all.return_value = []
        assert DeviceTokenService.get_tokens_for_users(mock_db_session, [uuid.uuid4()]) == {}
