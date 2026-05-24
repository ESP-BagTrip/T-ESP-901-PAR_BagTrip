"""Liveness and readiness probes.

``/health`` is a cheap liveness check (process is up, event loop responsive).
``/health/ready`` is a readiness probe that actually exercises the critical
dependencies so an orchestrator can gate traffic:

- **PostgreSQL** is mandatory. If ``SELECT 1`` fails the instance cannot serve,
  so readiness returns ``503``.
- **Redis** is optional — every consumer (rate limit, idempotency cache,
  distributed lock) has an in-process fallback. A Redis outage degrades the
  instance but it can still serve, so a down/unconfigured Redis yields
  ``status: "degraded"`` with a ``200``, never a ``503``.
"""

from __future__ import annotations

from typing import Annotated, Any

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from src.config.database import get_db
from src.integrations.redis_client import get_redis_client
from src.utils.logger import logger

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health() -> dict[str, str]:
    """Liveness probe — the process is up."""
    return {"status": "ok"}


def _check_database(db: Session) -> bool:
    try:
        db.execute(text("SELECT 1"))
        return True
    except Exception as exc:
        logger.error(f"[HEALTH] database readiness check failed: {exc}")
        return False


def _check_redis() -> str:
    """Return ``"ok"``, ``"down"`` (configured but unreachable) or ``"skipped"``."""
    client = get_redis_client()
    if client is None:
        return "skipped"
    try:
        client.ping()
        return "ok"
    except Exception as exc:
        logger.error(f"[HEALTH] redis readiness check failed: {exc}")
        return "down"


@router.get("/health/ready")
async def readiness(
    response: Response,
    db: Annotated[Session, Depends(get_db)],
) -> dict[str, Any]:
    """Readiness probe — pings DB (mandatory) and Redis (optional)."""
    db_ok = _check_database(db)
    redis_status = _check_redis()

    if not db_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        overall = "unavailable"
    elif redis_status == "down":
        overall = "degraded"
    else:
        overall = "ok"

    return {
        "status": overall,
        "checks": {
            "database": "ok" if db_ok else "down",
            "redis": redis_status,
        },
    }
