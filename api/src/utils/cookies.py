"""Helpers pour gérer les cookies d'authentification httpOnly."""

from fastapi import Response

from src.config.env import settings


def set_auth_cookies(
    response: Response,
    access_token: str,
    refresh_token: str,
    expires_in: int,
) -> None:
    """Set les cookies d'authentification sur la réponse."""
    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        secure=settings.COOKIE_SECURE,
        samesite="lax",
        max_age=expires_in,
        domain=settings.COOKIE_DOMAIN,
    )
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=settings.COOKIE_SECURE,
        samesite="lax",
        path="/v1/auth",
        max_age=30 * 24 * 60 * 60,  # 30 jours
        domain=settings.COOKIE_DOMAIN,
    )
    response.set_cookie(
        key="auth-status",
        value="authenticated",
        httponly=False,
        secure=settings.COOKIE_SECURE,
        samesite="lax",
        max_age=expires_in,
        domain=settings.COOKIE_DOMAIN,
    )


def clear_auth_cookies(response: Response) -> None:
    """Supprime les cookies d'authentification."""
    response.delete_cookie(
        key="access_token",
        domain=settings.COOKIE_DOMAIN,
    )
    response.delete_cookie(
        key="refresh_token",
        path="/v1/auth",
        domain=settings.COOKIE_DOMAIN,
    )
    response.delete_cookie(
        key="auth-status",
        domain=settings.COOKIE_DOMAIN,
    )
