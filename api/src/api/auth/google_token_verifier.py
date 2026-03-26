"""Verification of Google ID tokens (Firebase + OAuth)."""

import time

import httpx
from jose import jwt
from jose.exceptions import JWTError

from src.config.env import settings
from src.utils.logger import logger

_google_public_keys_cache: dict[str, str] | None = None
_cache_timestamp: float = 0
CACHE_DURATION = 3600  # 1 hour


async def _fetch_google_public_keys() -> dict[str, str]:
    global _google_public_keys_cache, _cache_timestamp

    now = time.time()
    if _google_public_keys_cache and (now - _cache_timestamp) < CACHE_DURATION:
        return _google_public_keys_cache

    async with httpx.AsyncClient() as client:
        response = await client.get("https://www.googleapis.com/oauth2/v1/certs")
        response.raise_for_status()
        _google_public_keys_cache = response.json()
        _cache_timestamp = now

    return _google_public_keys_cache


async def verify_google_id_token(id_token: str) -> dict:
    """Verify a Google ID token and return decoded claims.

    In development mode: lenient verification (issuer check only).
    In production: full RS256 signature verification with audience checks.
    Supports both Firebase tokens (real device) and Google OAuth tokens (simulator).
    """
    if settings.NODE_ENV != "production":
        # Dev mode: decode without full signature verification
        try:
            claims = jwt.get_unverified_claims(id_token)
            issuer = claims.get("iss", "")
            valid_issuers = [
                f"https://securetoken.google.com/{settings.GOOGLE_FIREBASE_PROJECT_ID}",
                "https://accounts.google.com",
                "accounts.google.com",
            ]
            if issuer not in valid_issuers:
                logger.warning(f"Google token issuer mismatch in dev mode: {issuer}")
            return claims
        except Exception as e:
            raise JWTError(f"Failed to decode Google token: {e}") from e

    # Production: full verification
    public_keys = await _fetch_google_public_keys()

    unverified_header = jwt.get_unverified_header(id_token)
    kid = unverified_header.get("kid")
    if not kid or kid not in public_keys:
        raise JWTError("Token key ID not found in Google public keys")

    public_key = public_keys[kid]

    # Try Firebase token first (real device)
    project_id = settings.GOOGLE_FIREBASE_PROJECT_ID
    try:
        return jwt.decode(
            id_token,
            public_key,
            algorithms=["RS256"],
            audience=project_id,
            issuer=f"https://securetoken.google.com/{project_id}",
        )
    except JWTError:
        pass

    # Try Google OAuth token (simulator)
    if settings.GOOGLE_OAUTH_CLIENT_ID:
        try:
            return jwt.decode(
                id_token,
                public_key,
                algorithms=["RS256"],
                audience=settings.GOOGLE_OAUTH_CLIENT_ID,
                issuer="https://accounts.google.com",
            )
        except JWTError:
            pass

    raise JWTError("Google token verification failed for all known audiences")
