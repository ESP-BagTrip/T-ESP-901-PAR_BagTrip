"""Rate limiting middleware."""

import time
from collections import defaultdict

from cachetools import TTLCache
from fastapi import Request
from fastapi.responses import JSONResponse

from src.api.auth.middleware import verify_jwt_token


class RateLimiter:
    """Rate limiter simple basé sur le user_id."""

    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        """
        Args:
            max_requests: Nombre maximum de requêtes par fenêtre
            window_seconds: Durée de la fenêtre en secondes
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: dict[str, list] = defaultdict(list)

    def is_allowed(self, user_id: str) -> tuple[bool, int]:
        """
        Vérifie si une requête est autorisée.

        Returns:
            Tuple[bool, int]: (is_allowed, remaining_requests)
        """
        now = time.time()
        user_requests = self.requests[user_id]

        # Nettoyer les requêtes anciennes
        cutoff = now - self.window_seconds
        user_requests[:] = [req_time for req_time in user_requests if req_time > cutoff]

        # Vérifier la limite
        if len(user_requests) >= self.max_requests:
            return False, 0

        # Ajouter la nouvelle requête
        user_requests.append(now)

        remaining = self.max_requests - len(user_requests)
        return True, remaining

    def get_retry_after(self, user_id: str) -> int:
        """Retourne le nombre de secondes avant de pouvoir refaire une requête."""
        if not self.requests[user_id]:
            return 0

        oldest_request = min(self.requests[user_id])
        window_end = oldest_request + self.window_seconds
        now = time.time()

        return max(0, int(window_end - now))


# Instance globale (pour POC, en production utiliser Redis)
agent_chat_rate_limiter = RateLimiter(max_requests=10, window_seconds=60)

# Rate limiter pour les endpoints IA (5 requêtes/minute)
ai_rate_limiter = RateLimiter(max_requests=5, window_seconds=60)

# Auth rate limiter: per-IP, 5 requests/minute, auto-expiring via TTLCache
_AUTH_RATE_LIMIT_MAX = 5
_AUTH_RATE_LIMIT_WINDOW = 60
_auth_rate_cache: TTLCache = TTLCache(maxsize=10000, ttl=_AUTH_RATE_LIMIT_WINDOW)

_AUTH_RATE_LIMITED_PATHS = {
    "/v1/auth/login",
    "/v1/auth/register",
    "/v1/auth/google",
    "/v1/auth/apple",
    "/v1/auth/refresh",
}


def _get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


async def auth_rate_limit_middleware(request: Request, call_next):
    """Per-IP rate limiting for auth endpoints."""
    if request.method == "POST" and request.url.path in _AUTH_RATE_LIMITED_PATHS:
        ip = _get_client_ip(request)
        key = f"auth:{ip}"

        count = _auth_rate_cache.get(key, 0)
        if count >= _AUTH_RATE_LIMIT_MAX:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": "Too many requests. Please try again later.",
                    "retry_after": _AUTH_RATE_LIMIT_WINDOW,
                },
                headers={"Retry-After": str(_AUTH_RATE_LIMIT_WINDOW)},
            )

        _auth_rate_cache[key] = count + 1

    return await call_next(request)


async def rate_limit_middleware(request: Request, call_next):
    """Middleware pour appliquer le rate limiting."""
    # Déterminer si c'est un endpoint AI rate-limité
    ai_rate_limited = (
        request.url.path.endswith("/agent/chat")
        or "/v1/ai/" in request.url.path
        or "/suggest" in request.url.path
    )
    if ai_rate_limited and request.method == "POST":
        # Récupérer le token depuis les headers ou les cookies
        auth_header = request.headers.get("Authorization")
        user_id = None

        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
            user_id = verify_jwt_token(token)
        else:
            cookie_token = request.cookies.get("access_token")
            if cookie_token:
                user_id = verify_jwt_token(cookie_token)

        if user_id:
            is_allowed, remaining = ai_rate_limiter.is_allowed(user_id)

            if not is_allowed:
                retry_after = ai_rate_limiter.get_retry_after(user_id)
                return JSONResponse(
                    status_code=429,
                    content={
                        "detail": "Rate limit exceeded. Please try again later.",
                        "retry_after": retry_after,
                    },
                    headers={"Retry-After": str(retry_after)},
                )

            # Ajouter header avec remaining requests
            response = await call_next(request)
            response.headers["X-RateLimit-Remaining"] = str(remaining)
            response.headers["X-RateLimit-Limit"] = str(ai_rate_limiter.max_requests)
            return response

    return await call_next(request)
