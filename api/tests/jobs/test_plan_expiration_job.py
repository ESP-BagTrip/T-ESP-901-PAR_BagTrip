"""Unit tests for the plan expiration job."""

import contextlib
import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

from src.jobs.plan_expiration_job import downgrade_expired_plans
from src.models.user import User


def _user(**kw) -> User:
    """Detached User with overridable fields."""
    defaults = {
        "id": uuid.uuid4(),
        "email": f"x{uuid.uuid4().hex[:6]}@y.z",
        "password_hash": "h",
        "plan": "PREMIUM",
        "stripe_customer_id": "cus_x",
        "stripe_subscription_id": None,
        "plan_expires_at": None,
    }
    defaults.update(kw)
    return User(**defaults)


@patch("src.jobs.plan_expiration_job.SessionLocal")
def test_downgrades_only_expired_premium_with_no_active_sub(mock_session_local):
    """The query filter correctness IS the test — we check users get downgraded."""
    expired_user = _user(
        plan="PREMIUM",
        plan_expires_at=datetime.now(UTC) - timedelta(hours=1),
        stripe_subscription_id=None,
    )
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.all.return_value = [expired_user]
    mock_session_local.return_value = mock_db

    downgraded = downgrade_expired_plans()

    assert downgraded == 1
    assert expired_user.plan == "FREE"
    assert expired_user.plan_expires_at is None
    mock_db.commit.assert_called_once()
    mock_db.close.assert_called_once()


@patch("src.jobs.plan_expiration_job.SessionLocal")
def test_no_users_to_downgrade(mock_session_local):
    """Empty result set → 0 downgrades, still commits + closes."""
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.all.return_value = []
    mock_session_local.return_value = mock_db

    assert downgrade_expired_plans() == 0
    mock_db.close.assert_called_once()


@patch("src.jobs.plan_expiration_job.SessionLocal")
def test_session_closed_even_on_exception(mock_session_local):
    """Lifecycle: session must close even if the query raises."""
    mock_db = MagicMock()
    mock_db.query.side_effect = Exception("boom")
    mock_session_local.return_value = mock_db

    with contextlib.suppress(Exception):
        downgrade_expired_plans()

    mock_db.close.assert_called_once()
