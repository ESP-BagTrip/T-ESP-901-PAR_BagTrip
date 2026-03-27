"""Retry logic for Amadeus API calls."""

from tenacity import (
    retry,
    retry_if_exception,
    stop_after_attempt,
    wait_exponential_jitter,
)

from src.utils.errors import AppError


def _is_retryable(exc: BaseException) -> bool:
    """Check if an AppError is retryable (transient failure)."""
    return isinstance(exc, AppError) and exc.status_code in (429, 502, 503)


amadeus_retry = retry(
    retry=retry_if_exception(_is_retryable),
    stop=stop_after_attempt(3),
    wait=wait_exponential_jitter(initial=1, max=10, jitter=2),
    reraise=True,
)
