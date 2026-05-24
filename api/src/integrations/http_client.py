"""Shared `httpx.AsyncClient` singleton for all outbound HTTP integrations.

Every integration wrapper (Amadeus, Unsplash, Open-Meteo, OAuth token verifiers,
agent tools, …) used to create a per-call `httpx.AsyncClient()` with `async
with`. That pattern is correct as a last resort, but it burns an entire TLS
handshake per request and prevents HTTP/2 or connection reuse — painful on a
service that fans out to several third parties per user request.

This module exposes a single pool owned by the FastAPI lifespan. Callers go
through `get_http_client()` and pass a per-request `timeout=` so each integration
keeps its own SLA without each one owning a client.
"""

from __future__ import annotations

import httpx

from src.utils.logger import logger

_client: httpx.AsyncClient | None = None

# Tuned for a handful of concurrent backends + the agent fanout:
#  - 100 total connections keeps us well under default OS FD limits
#  - 20 keepalive connections preserves pools across request bursts
#  - default timeout is intentionally generous; hot callers override per request
_DEFAULT_LIMITS = httpx.Limits(max_connections=100, max_keepalive_connections=20)
_DEFAULT_TIMEOUT = httpx.Timeout(30.0)


async def init_http_client() -> None:
    """Create the shared client. Idempotent — safe on warm reload."""
    global _client
    if _client is not None:
        return
    _client = httpx.AsyncClient(timeout=_DEFAULT_TIMEOUT, limits=_DEFAULT_LIMITS)
    logger.info("Shared httpx.AsyncClient initialized")


async def close_http_client() -> None:
    """Close the shared client at lifespan teardown."""
    global _client
    if _client is None:
        return
    await _client.aclose()
    _client = None
    logger.info("Shared httpx.AsyncClient closed")


def get_http_client() -> httpx.AsyncClient:
    """Return the shared client.

    Raises:
        RuntimeError: If the lifespan did not run `init_http_client()` first —
            this is a bug, not a runtime condition to recover from.
    """
    if _client is None:
        raise RuntimeError(
            "Shared httpx.AsyncClient is not initialized. "
            "Make sure the FastAPI lifespan called init_http_client()."
        )
    return _client
