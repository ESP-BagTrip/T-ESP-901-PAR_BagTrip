"""Retry logic for Amadeus API calls."""

from tenacity import (
    RetryCallState,
    retry,
    retry_if_exception,
    stop_after_attempt,
    wait_exponential_jitter,
)

from src.utils.errors import AppError

_default_wait = wait_exponential_jitter(initial=1, max=10, jitter=2)


def _is_retryable(exc: BaseException) -> bool:
    """Check if an AppError is retryable (transient failure)."""
    return isinstance(exc, AppError) and exc.status_code in (429, 502, 503)


def _wait_with_retry_after(retry_state: RetryCallState) -> float:
    """Respect Retry-After header on 429, otherwise use exponential backoff."""
    exc = retry_state.outcome and retry_state.outcome.exception()
    if isinstance(exc, AppError) and exc.detail:
        retry_after = exc.detail.get("retry_after")
        if retry_after is not None:
            try:
                return min(float(retry_after), 30.0)
            except (ValueError, TypeError):
                pass
    return _default_wait(retry_state)


amadeus_retry = retry(
    retry=retry_if_exception(_is_retryable),
    stop=stop_after_attempt(3),
    wait=_wait_with_retry_after,
    reraise=True,
)
