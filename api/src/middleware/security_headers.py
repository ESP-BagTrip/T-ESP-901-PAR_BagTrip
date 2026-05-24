"""Security headers middleware — HSTS, CSP, X-Frame-Options, etc."""

from __future__ import annotations

from collections.abc import Awaitable, Callable

from fastapi import Request, Response

from src.config.env import settings

# Conservative CSP — the API serves JSON only, no HTML/JS execution expected.
_DEFAULT_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"

_STATIC_HEADERS: dict[str, str] = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "accelerometer=(), camera=(), geolocation=(), microphone=()",
    "Content-Security-Policy": _DEFAULT_CSP,
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "same-origin",
}


async def security_headers_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
) -> Response:
    """Attach security headers to every response."""
    response = await call_next(request)
    for header, value in _STATIC_HEADERS.items():
        response.headers.setdefault(header, value)

    # HSTS only makes sense over HTTPS. We enable it whenever cookies are secure
    # (i.e. production + any env that forces secure transport).
    if settings.COOKIE_SECURE:
        response.headers.setdefault(
            "Strict-Transport-Security",
            "max-age=31536000; includeSubDomains",
        )
    return response
