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

_VERIFICATION_SUBJECT = {
    "en": "Verify your BagTrip email",
    "fr": "Verifiez votre adresse email BagTrip",
}

_VERIFICATION_BODY = {
    "en": (
        "Welcome to BagTrip!\n\n"
        "Open the link below in the BagTrip app to confirm your email address:\n"
        "{link}\n\n"
        "This link expires in 24 hours. If you did not create a BagTrip account, "
        "you can safely ignore this email."
    ),
    "fr": (
        "Bienvenue sur BagTrip !\n\n"
        "Ouvrez le lien ci-dessous dans l'application BagTrip pour confirmer "
        "votre adresse email :\n"
        "{link}\n\n"
        "Ce lien expire dans 24 heures. Si vous n'avez pas cree de compte "
        "BagTrip, vous pouvez ignorer cet email."
    ),
}


_INVITE_SUBJECT = {
    "en": "You have been invited to a BagTrip trip",
    "fr": "Vous avez ete invite a un voyage BagTrip",
}

_INVITE_BODY = {
    "en": (
        '{inviter} invited you to join their BagTrip trip "{trip_title}".\n\n'
        "Open the link below in the BagTrip app to accept the invitation:\n"
        "{link}\n\n"
        "This invitation expires in 7 days. If you did not expect this, you can "
        "safely ignore this email."
    ),
    "fr": (
        '{inviter} vous a invite a rejoindre son voyage BagTrip "{trip_title}".\n\n'
        "Ouvrez le lien ci-dessous dans l'application BagTrip pour accepter "
        "l'invitation :\n"
        "{link}\n\n"
        "Cette invitation expire dans 7 jours. Si vous ne vous attendiez pas a "
        "ceci, vous pouvez ignorer cet email."
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
    def build_verification_link(raw_token: str) -> str:
        """Build the deep link the mobile app opens to verify an email."""
        return f"{settings.EMAIL_VERIFICATION_URL_BASE}?token={raw_token}"

    @staticmethod
    def build_invite_link(invite_token: str) -> str:
        """Build the deep link the mobile app opens to accept a trip invite."""
        return f"{settings.TRIP_INVITE_URL_BASE}?token={invite_token}"

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

    @staticmethod
    async def send_email_verification(
        to_email: str, raw_token: str, locale: str | None = None
    ) -> bool:
        """Send an email-verification email. Returns True on success, never raises.

        Verification is soft: the email lets the user confirm their address, but
        nothing in the app is gated on it. The raw token only travels by email,
        is never logged, and transport errors are swallowed so registration and
        the resend flow stay non-blocking.
        """
        if not MailerService.is_enabled():
            return False

        loc = normalize_locale(locale)
        lang = "fr" if loc.startswith("fr") else "en"
        link = MailerService.build_verification_link(raw_token)

        message = EmailMessage()
        message["From"] = settings.SMTP_FROM_EMAIL
        message["To"] = to_email
        message["Subject"] = _VERIFICATION_SUBJECT[lang]
        message.set_content(_VERIFICATION_BODY[lang].format(link=link))

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
            logger.error(
                "Failed to send email-verification email",
                data={"error": str(exc)},
            )
            return False

    @staticmethod
    async def send_trip_invite(
        to_email: str,
        trip_title: str,
        inviter_name: str,
        invite_token: str,
        locale: str | None = None,
    ) -> bool:
        """Send a trip-share invitation email. Returns True on success, never raises.

        Sent to an email that does not yet have a BagTrip account: the deep link
        carries the invite token so the recipient can sign up and claim the
        share. Best-effort — a mailer outage must never block invite creation,
        and the token only travels by email (never logged).
        """
        if not MailerService.is_enabled():
            return False

        loc = normalize_locale(locale)
        lang = "fr" if loc.startswith("fr") else "en"
        link = MailerService.build_invite_link(invite_token)

        message = EmailMessage()
        message["From"] = settings.SMTP_FROM_EMAIL
        message["To"] = to_email
        message["Subject"] = _INVITE_SUBJECT[lang]
        message.set_content(
            _INVITE_BODY[lang].format(
                inviter=inviter_name,
                trip_title=trip_title,
                link=link,
            )
        )

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
            logger.error(
                "Failed to send trip-invite email",
                data={"error": str(exc)},
            )
            return False
