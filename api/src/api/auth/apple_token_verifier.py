"""Verification of Apple ID tokens via JWKS."""

import time

from jose import jwk, jwt
from jose.exceptions import JWTError

from src.config.env import settings
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_apple_jwks_cache: dict | None = None
_cache_timestamp: float = 0
CACHE_DURATION = 3600  # 1 hour


async def _fetch_apple_jwks() -> dict:
    global _apple_jwks_cache, _cache_timestamp

    now = time.time()
    if _apple_jwks_cache and (now - _cache_timestamp) < CACHE_DURATION:
        return _apple_jwks_cache

    client = get_http_client()
    response = await client.get("https://appleid.apple.com/auth/keys")
    response.raise_for_status()
    _apple_jwks_cache = response.json()
    _cache_timestamp = now

    return _apple_jwks_cache


async def verify_apple_id_token(id_token: str) -> dict:
    """Verify an Apple ID token and return decoded claims.

    In development mode: lenient verification (issuer check only).
    In production: full RS256 signature verification via Apple JWKS.
    """
    if settings.NODE_ENV != "production":
        # Dev mode: decode without full signature verification
        try:
            claims = jwt.get_unverified_claims(id_token)
            issuer = claims.get("iss", "")
            if issuer != "https://appleid.apple.com":
                logger.warning(f"Apple token issuer mismatch in dev mode: {issuer}")
            return claims
        except Exception as e:
            raise JWTError(f"Failed to decode Apple token: {e}") from e

    # Production: full verification
    jwks_data = await _fetch_apple_jwks()

    unverified_header = jwt.get_unverified_header(id_token)
    kid = unverified_header.get("kid")
    if not kid:
        raise JWTError("Apple token missing key ID (kid)")

    # Find the matching key
    matching_key = None
    for key_data in jwks_data.get("keys", []):
        if key_data.get("kid") == kid:
            matching_key = key_data
            break

    if not matching_key:
        raise JWTError("Token key ID not found in Apple JWKS")

    public_key = jwk.construct(matching_key)

    audience = settings.APPLE_BUNDLE_ID
    if not audience:
        raise JWTError("APPLE_BUNDLE_ID not configured for production verification")

    return jwt.decode(
        id_token,
        public_key,
        algorithms=["RS256"],
        audience=audience,
        issuer="https://appleid.apple.com",
    )
