"""Circuit breaker for Amadeus network calls.

Every Amadeus operation (token, flights, hotels, POIs, …) already retries on
transient errors via ``@amadeus_retry`` and surfaces failures as ``AppError``.
This decorator adds a shared in-process breaker on top: after a run of
*provider-health* failures (timeouts, connection errors, 429/502/503) the
circuit trips OPEN and we fail-fast with a clean ``UPSTREAM_UNAVAILABLE``
``AppError`` instead of paying the full retry budget on every request.

Client-side errors (400/404) are **not** counted — they say nothing about
Amadeus being healthy — so they re-raise without tripping the breaker.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from functools import wraps

from src.integrations.circuit_breaker import CircuitBreaker, CircuitOpenError
from src.utils.errors import AppError

# One breaker shared across all Amadeus endpoints: they hit the same upstream,
# so a sustained outage on any of them is the same "Amadeus is down" signal.
_breaker = CircuitBreaker("amadeus")

# Same statuses ``amadeus_retry`` treats as transient/provider-health failures.
_HEALTH_FAILURE_STATUSES = frozenset({429, 502, 503})


class _ClientError:
    """Carries a client-side ``AppError`` (400/404) back as a *successful* breaker
    result so it never trips the circuit, while still being re-raised to the caller."""

    __slots__ = ("error",)

    def __init__(self, error: AppError) -> None:
        self.error = error


def amadeus_breaker[**P, T](
    fn: Callable[P, Awaitable[T]],
) -> Callable[P, Awaitable[T]]:
    """Run an Amadeus network coroutine through the shared circuit breaker."""

    @wraps(fn)
    async def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        async def _invoke() -> T | _ClientError:
            try:
                return await fn(*args, **kwargs)
            except AppError as exc:
                # Provider-health failures (timeouts, 429/502/503) propagate so the
                # breaker counts them. Client errors (400/404) are returned as a
                # benign result so they never trip the circuit.
                if exc.status_code in _HEALTH_FAILURE_STATUSES:
                    raise
                return _ClientError(exc)

        try:
            result = await _breaker.call(_invoke)
        except CircuitOpenError as exc:
            raise AppError(
                "UPSTREAM_UNAVAILABLE",
                503,
                "Amadeus temporarily unavailable (circuit open)",
                {"circuit": exc.name, "retry_after": round(exc.retry_after, 1)},
            ) from exc

        if isinstance(result, _ClientError):
            raise result.error
        return result

    return wrapper
