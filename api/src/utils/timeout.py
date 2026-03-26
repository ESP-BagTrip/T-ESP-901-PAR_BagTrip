"""Décorateurs pour ajouter des timeouts aux fonctions."""

import asyncio
import builtins
import logging
from collections.abc import Callable
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
