"""Transactional email delivery over SMTP.

Provider-agnostic: configured entirely from SMTP_* settings, so any provider
(SES, Sendgrid, Mailgun, a self-hosted relay...) works without an SDK. When
SMTP_HOST is unset the service reports itself disabled and callers degrade
gracefully — they must never block or leak on a missing mailer.
"""

from email.message import EmailMessage

import aiosmtplib

from src.config.env import settings
from src.services.notification_messages import normalize_locale
from src.utils.logger import logger

_RESET_SUBJECT = {
    "en": "Reset your BagTrip password",
    "fr": "Reinitialisez votre mot de passe BagTrip",
}

_RESET_BODY = {
    "en": (
        "You requested a password reset for your BagTrip account.\n\n"
        "Open the link below in the BagTrip app to choose a new password:\n"
        "{link}\n\n"
        "This link expires in 1 hour. If you did not request this, you can "
        "safely ignore this email."
    ),
    "fr": (
        "Vous avez demande la reinitialisation du mot de passe de votre compte "
        "BagTrip.\n\n"
        "Ouvrez le lien ci-dessous dans l'application BagTrip pour choisir un "
        "nouveau mot de passe :\n"
        "{link}\n\n"
        "Ce lien expire dans 1 heure. Si vous n'etes pas a l'origine de cette "
        "demande, vous pouvez ignorer cet email."
    ),
}


class MailerService:
    """Send transactional emails over SMTP. All sends are best-effort."""

    @staticmethod
    def is_enabled() -> bool:
        """True when an SMTP host is configured."""
        return bool(settings.SMTP_HOST)

    @staticmethod
    def build_reset_link(raw_token: str) -> str:
        """Build the deep link the mobile app opens to reset a password."""
        return f"{settings.PASSWORD_RESET_URL_BASE}?token={raw_token}"

    @staticmethod
    async def send_password_reset(to_email: str, raw_token: str, locale: str | None = None) -> bool:
        """Send a password-reset email. Returns True on success, never raises.

        The raw token only ever travels by email — it is never logged, and the
        function swallows transport errors so the forgot-password flow stays
        non-blocking and can't leak whether the address exists.
        """
        if not MailerService.is_enabled():
            return False

        loc = normalize_locale(locale)
        lang = "fr" if loc.startswith("fr") else "en"
        link = MailerService.build_reset_link(raw_token)

        message = EmailMessage()
        message["From"] = settings.SMTP_FROM_EMAIL
        message["To"] = to_email
        message["Subject"] = _RESET_SUBJECT[lang]
        message.set_content(_RESET_BODY[lang].format(link=link))

        try:
            await aiosmtplib.send(
                message,
                hostname=settings.SMTP_HOST,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USERNAME,
                password=settings.SMTP_PASSWORD,
                start_tls=settings.SMTP_USE_TLS,
            )
            return True
        except Exception as exc:
            # Best-effort: a mailer outage must not break the auth flow. We log
            # the failure (without the token) for observability and move on.
            logger.error(
                "Failed to send password-reset email",
                data={"error": str(exc)},
            )
            return False
