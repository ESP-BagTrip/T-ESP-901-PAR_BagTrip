"""Authentification OAuth2 Amadeus avec cache mémoire."""

import time

import httpx

from src.config.env import settings
from src.integrations.amadeus.errors import raise_amadeus_connection_error
from src.integrations.amadeus.retry import amadeus_retry
from src.utils.errors import AppError
from src.utils.logger import logger

# Cache de token en mémoire
_token_cache: dict[str, any] | None = None


@amadeus_retry
async def fetch_token() -> str:
    """
    Récupère un token d'accès Amadeus avec cache.
    Le token est mis en cache jusqu'à 5 secondes avant son expiration.
    """
    global _token_cache

    now = time.time() * 1000  # millisecondes
    if _token_cache and _token_cache.get("expires_at", 0) > now + 5000:
        return _token_cache["access_token"]

    url = f"{settings.AMADEUS_BASE_URL}/v1/security/oauth2/token"

    form_data = {
        "grant_type": "client_credentials",
        "client_id": settings.AMADEUS_CLIENT_ID,
        "client_secret": settings.AMADEUS_CLIENT_SECRET,
    }

    logger.debug(
        "Amadeus token request",
        {
            "url": url,
            "baseUrl": settings.AMADEUS_BASE_URL,
            "clientId": settings.AMADEUS_CLIENT_ID,
            "clientSecretLength": len(settings.AMADEUS_CLIENT_SECRET)
            if settings.AMADEUS_CLIENT_SECRET
            else 0,
            "timeout": settings.REQUEST_TIMEOUT_MS,
        },
    )

    try:
        logger.info("Making Amadeus token request", {"url": url})

        async with httpx.AsyncClient(timeout=settings.REQUEST_TIMEOUT_MS / 1000) as client:
            response = await client.post(
                url,
                data=form_data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )

        logger.debug(
            "Amadeus token response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "data": response.json() if response.status_code == 200 else None,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus token response error",
                {
                    "status": response.status_code,
                    "data": response.text,
                },
            )
            raise AppError(
                "UPSTREAM_AUTH_ERROR",
                502,
                f"Amadeus token error: status {response.status_code}",
                {"upstream_status": response.status_code},
            )

        data = response.json()

        if not data.get("access_token"):
            logger.error(
                "Amadeus token response missing access_token",
                {
                    "status": response.status_code,
                    "data": data,
                },
            )
            raise AppError(
                "UPSTREAM_AUTH_ERROR", 502, "Amadeus token response missing access_token"
            )

        logger.info(
            "Amadeus token obtained successfully",
            {
                "tokenType": data.get("token_type"),
                "expiresIn": data.get("expires_in"),
            },
        )

        expires_in = int(data.get("expires_in", 1799)) * 1000  # fallback ~30m
        _token_cache = {
            "access_token": data["access_token"],
            "expires_at": now + expires_in,
        }

        return _token_cache["access_token"]

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus token request failed",
            {
                "message": str(error),
                "url": str(error.request.url) if hasattr(error, "request") else None,
            },
        )
        raise_amadeus_connection_error(error, "token acquisition")
