"""Unit tests for the per-account login lockout."""

from __future__ import annotations

import uuid

from src.services.auth_lockout_service import MAX_FAILURES, AuthLockoutService


def _fresh_email() -> str:
    # Unique per test so the process-shared in-memory counter never bleeds across tests.
    return f"{uuid.uuid4().hex}@example.com"


class TestAuthLockout:
    def test_unknown_email_is_not_locked(self) -> None:
        locked, retry_after = AuthLockoutService.is_locked(_fresh_email())
        assert locked is False
        assert retry_after == 0

    def test_record_failure_increments(self) -> None:
        email = _fresh_email()
        assert AuthLockoutService.record_failure(email) == 1
        assert AuthLockoutService.record_failure(email) == 2

    def test_not_locked_below_threshold(self) -> None:
        email = _fresh_email()
        for _ in range(MAX_FAILURES - 1):
            AuthLockoutService.record_failure(email)
        locked, _ = AuthLockoutService.is_locked(email)
        assert locked is False

    def test_locked_at_threshold_with_retry_after(self) -> None:
        email = _fresh_email()
        for _ in range(MAX_FAILURES):
            AuthLockoutService.record_failure(email)
        locked, retry_after = AuthLockoutService.is_locked(email)
        assert locked is True
        assert retry_after > 0

    def test_reset_clears_counter(self) -> None:
        email = _fresh_email()
        for _ in range(MAX_FAILURES):
            AuthLockoutService.record_failure(email)
        assert AuthLockoutService.is_locked(email)[0] is True
        AuthLockoutService.reset(email)
        assert AuthLockoutService.is_locked(email)[0] is False

    def test_key_is_hashed_not_plaintext(self) -> None:
        key = AuthLockoutService._key("Alice@Example.com")
        assert "alice" not in key.lower()
        assert key.startswith("login_fail:")
        # Case/whitespace-insensitive: same account -> same key.
        assert key == AuthLockoutService._key("  alice@example.com ")
