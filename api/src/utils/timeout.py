"""Décorateurs et helpers pour ajouter des timeouts aux fonctions."""

import asyncio
import builtins
import logging
from collections.abc import AsyncIterator, Callable
from concurrent.futures import ThreadPoolExecutor, TimeoutError
from functools import wraps
from typing import Any

logger = logging.getLogger(__name__)


def with_timeout(timeout_seconds: float, fallback_value: Any = None):
    """
    Décorateur pour ajouter un timeout à une fonction async.

    Args:
        timeout_seconds: Timeout en secondes
        fallback_value: Valeur à retourner si timeout
    """

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=timeout_seconds,
                )
            except builtins.TimeoutError:
                logger.warning(f"Function {func.__name__} timed out after {timeout_seconds}s")
                return fallback_value
            except Exception as e:
                logger.error(f"Error in {func.__name__}: {e}")
                return fallback_value

        return wrapper

    return decorator


async def async_generator_with_timeout[T](
    agen: AsyncIterator[T],
    total_timeout_seconds: float,
) -> AsyncIterator[T]:
    """Wrap an async generator with a global wall-clock timeout.

    Yields items from *agen* until it is exhausted or the total elapsed time
    exceeds *total_timeout_seconds*, whichever comes first.

    Raises ``TimeoutError`` when the deadline is exceeded.
    """
    loop = asyncio.get_event_loop()
    deadline = loop.time() + total_timeout_seconds
    ait = agen.__aiter__()
    while True:
        remaining = deadline - loop.time()
        if remaining <= 0:
            raise builtins.TimeoutError(
                f"Async generator exceeded {total_timeout_seconds}s total timeout"
            )
        try:
            item = await asyncio.wait_for(ait.__anext__(), timeout=remaining)
            yield item
        except StopAsyncIteration:
            break


def with_timeout_sync(timeout_seconds: float, fallback_value: Any = None):
    """
    Décorateur pour ajouter un timeout à une fonction synchrone.
    Utilise ThreadPoolExecutor pour exécuter dans un thread séparé.
    """

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            executor = ThreadPoolExecutor(max_workers=1)
            future = executor.submit(func, *args, **kwargs)

            try:
                result = future.result(timeout=timeout_seconds)
                executor.shutdown(wait=False)
                return result
            except TimeoutError:
                logger.warning(f"Function {func.__name__} timed out after {timeout_seconds}s")
                executor.shutdown(wait=False)
                return fallback_value
            except Exception as e:
                logger.error(f"Error in {func.__name__}: {e}")
                executor.shutdown(wait=False)
                return fallback_value

        return wrapper

    return decorator
