"""`@handle_app_errors` decorator for FastAPI route handlers.

Routes used to boiler-plate this pattern around every body:

```python
try:
    ...
except AppError as e:
    raise create_http_exception(e) from e
except Exception as e:
    raise create_http_exception(AppError("INTERNAL_ERROR", 500, "Failed")) from e
```

The global exception handler in `main.py` already catches `AppError` and maps
it to a JSON response, so most of that is dead code. This decorator formalises
the "just raise `AppError`, we'll do the right thing" contract:

- `AppError` bubbles up to the global handler untouched (the framework keeps its
  correct `status_code`, `code`, `detail`).
- Any other exception is logged with its traceback and re-raised as an
  `AppError("INTERNAL_ERROR", 500)`, which then goes through the same global
  handler. That keeps the response shape consistent across the API.

Use on new endpoints; existing try/except blocks can be migrated incrementally.
"""

from __future__ import annotations

import functools
from collections.abc import Awaitable, Callable
from typing import Any

from src.utils.errors import AppError
from src.utils.logger import logger


def handle_app_errors[F: Callable[..., Awaitable[Any]]](func: F) -> F:
    """Wrap a FastAPI async route so it always raises `AppError` on failure.

    Example:
        @router.get("/things")
        @handle_app_errors
        async def list_things(...):
            return await ThingService.list_things(...)  # may raise AppError
    """

    @functools.wraps(func)
    async def wrapper(*args: Any, **kwargs: Any) -> Any:
        try:
            return await func(*args, **kwargs)
        except AppError:
            # Global exception handler turns this into the right JSON response.
            raise
        except Exception as exc:
            logger.error(
                f"Unhandled error in route {func.__name__}: {exc}",
                exc_info=True,
            )
            raise AppError(
                "INTERNAL_ERROR",
                500,
                "An unexpected error occurred. Please try again.",
            ) from exc

    return wrapper  # type: ignore[return-value]
