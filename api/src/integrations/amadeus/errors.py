"""Amadeus error handling utilities."""

import httpx

from src.utils.errors import AppError


def raise_for_amadeus_status(response: httpx.Response, context: str) -> None:
    """Raise an AppError based on Amadeus HTTP response status code."""
    status = response.status_code
    detail: dict = {"upstream_status": status, "context": context}
    try:
        body = response.json()
        if "errors" in body:
            detail["upstream_errors"] = body["errors"]
    except Exception:
        pass

    if status == 429:
        retry_after = response.headers.get("Retry-After")
        if retry_after is not None:
            detail["retry_after"] = retry_after
        raise AppError("RATE_LIMITED", 429, f"Amadeus rate limit exceeded during {context}", detail)
    if status == 401:
        raise AppError(
            "UPSTREAM_AUTH_ERROR", 502, f"Amadeus authentication failed during {context}", detail
        )
    if status == 404:
        raise AppError("NOT_FOUND", 404, f"Resource not found during {context}", detail)
    if status == 400:
        raise AppError("INVALID_REQUEST", 400, f"Invalid request during {context}", detail)
    # All other non-success statuses → 502
    raise AppError("UPSTREAM_ERROR", 502, f"Amadeus error (HTTP {status}) during {context}", detail)


def raise_amadeus_connection_error(error: httpx.HTTPError, context: str) -> None:
    """Raise an AppError for httpx connection/timeout errors."""
    raise AppError(
        "UPSTREAM_UNAVAILABLE",
        503,
        f"Amadeus unavailable during {context}: {error}",
        {"context": context, "error_type": type(error).__name__},
    ) from error
