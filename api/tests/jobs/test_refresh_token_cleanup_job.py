"""Unit tests for the refresh-token cleanup job (SMP327-062)."""

import contextlib
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

from sqlalchemy.sql.elements import BooleanClauseList

from src.jobs.refresh_token_cleanup_job import (
    _EXPIRY_GRACE_DAYS,
    purge_stale_refresh_tokens,
)
from src.models.refresh_token import RefreshToken


@patch("src.jobs.refresh_token_cleanup_job.SessionLocal")
def test_purges_revoked_or_long_expired_tokens(mock_session_local):
    """Returns the deleted count and commits + closes."""
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.delete.return_value = 4
    mock_session_local.return_value = mock_db

    deleted = purge_stale_refresh_tokens()

    assert deleted == 4
    mock_db.query.assert_called_once_with(RefreshToken)
    mock_db.commit.assert_called_once()
    mock_db.close.assert_called_once()


@patch("src.jobs.refresh_token_cleanup_job.SessionLocal")
def test_filter_targets_revoked_or_expired_beyond_grace(mock_session_local):
    """The filter is an OR(revoked is True, expires_at < now - 7d)."""
    mock_db = MagicMock()
    mock_query = MagicMock()
    mock_db.query.return_value = mock_query
    mock_query.filter.return_value.delete.return_value = 0
    mock_session_local.return_value = mock_db

    before = datetime.now(UTC)
    purge_stale_refresh_tokens()
    after = datetime.now(UTC)

    # Inspect the OR clause passed to .filter(...)
    assert mock_query.filter.call_count == 1
    clause = mock_query.filter.call_args.args[0]
    assert isinstance(clause, BooleanClauseList)
    sql = str(clause.compile(compile_kwargs={"literal_binds": True}))
    assert "revoked" in sql
    assert "expires_at" in sql
    # OR of exactly two conditions: revoked-is-true and expired-beyond-cutoff.
    assert " OR " in sql.upper()

    # The 7-day grace must be applied to the expiry cutoff. The literal-bound
    # SQL renders the cutoff as 'YYYY-MM-DD HH:...'; assert the cutoff DATE
    # (now - 7d) appears, which only holds if the grace is correctly applied.
    assert _EXPIRY_GRACE_DAYS == 7
    cutoff_date_min = (before - timedelta(days=_EXPIRY_GRACE_DAYS)).strftime("%Y-%m-%d")
    cutoff_date_max = (after - timedelta(days=_EXPIRY_GRACE_DAYS)).strftime("%Y-%m-%d")
    assert cutoff_date_min in sql or cutoff_date_max in sql


@patch("src.jobs.refresh_token_cleanup_job.SessionLocal")
def test_session_closed_even_on_exception(mock_session_local):
    """Session must close even if the delete raises."""
    mock_db = MagicMock()
    mock_db.query.side_effect = Exception("boom")
    mock_session_local.return_value = mock_db

    with contextlib.suppress(Exception):
        purge_stale_refresh_tokens()

    mock_db.close.assert_called_once()
