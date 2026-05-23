"""Unit tests for MailerService (SMTP transactional email)."""

from email.message import EmailMessage
from unittest.mock import AsyncMock, patch

import pytest

from src.services import mailer_service
from src.services.mailer_service import MailerService


class TestIsEnabled:
    def test_disabled_without_host(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", None)
        assert MailerService.is_enabled() is False

    def test_enabled_with_host(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", "smtp.example.com")
        assert MailerService.is_enabled() is True


class TestBuildResetLink:
    def test_appends_token_to_base(self, monkeypatch):
        monkeypatch.setattr(
            mailer_service.settings, "PASSWORD_RESET_URL_BASE", "bagtrip://reset-password"
        )
        assert MailerService.build_reset_link("abc") == "bagtrip://reset-password?token=abc"


@pytest.mark.asyncio
class TestSendPasswordReset:
    async def test_returns_false_when_disabled(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", None)
        with patch.object(mailer_service.aiosmtplib, "send", new=AsyncMock()) as send:
            result = await MailerService.send_password_reset("u@example.com", "tok")
        assert result is False
        send.assert_not_called()

    async def test_success_sends_message(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", "smtp.example.com")
        monkeypatch.setattr(mailer_service.settings, "SMTP_FROM_EMAIL", "no-reply@bagtrip.fr")
        with patch.object(mailer_service.aiosmtplib, "send", new=AsyncMock()) as send:
            result = await MailerService.send_password_reset("u@example.com", "tok", "en")
        assert result is True
        send.assert_awaited_once()
        message: EmailMessage = send.await_args.args[0]
        assert message["To"] == "u@example.com"
        assert message["Subject"] == "Reset your BagTrip password"
        assert "tok" in message.get_content()

    async def test_french_locale_uses_french_subject(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", "smtp.example.com")
        with patch.object(mailer_service.aiosmtplib, "send", new=AsyncMock()) as send:
            await MailerService.send_password_reset("u@example.com", "tok", "fr-FR")
        message: EmailMessage = send.await_args.args[0]
        assert "Reinitialisez" in message["Subject"]

    async def test_swallows_transport_errors(self, monkeypatch):
        monkeypatch.setattr(mailer_service.settings, "SMTP_HOST", "smtp.example.com")
        with patch.object(
            mailer_service.aiosmtplib, "send", new=AsyncMock(side_effect=OSError("smtp down"))
        ):
            result = await MailerService.send_password_reset("u@example.com", "tok")
        # A transport failure must not raise — the auth flow stays non-blocking.
        assert result is False
