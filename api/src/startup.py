"""Application lifespan: startup / shutdown orchestration.

`main.py` used to inline the full lifespan (DB check, ad-hoc migration, Stripe
product init, admin seed, scheduler fan-out and teardown). It is extracted here
so the app factory stays minimal. Behaviour is unchanged — same checks, same
seeds, same scheduler set, same cancellation order — only relocated.

The background scheduler tasks are kept on `app.state.scheduler_tasks` so
`run_shutdown` can cancel and await them symmetrically.
"""

from __future__ import annotations

import asyncio
import contextlib
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from src.config.database import check_database_connection, engine
from src.integrations.http_client import close_http_client, init_http_client
from src.utils.logger import logger


def _run_db_check() -> None:
    """Vérifier la connexion à la base de données avant de créer les tables."""
    logger.info("Checking database connection...")
    check_database_connection()
    logger.info("Database connection successful")


def _run_trips_migration() -> None:
    """Migrer la table trips si nécessaire (idempotent)."""
    # Schema managed by: alembic upgrade head
    try:
        from src.migrations.migrate_trips_table import migrate_trips_table

        migrate_trips_table(engine)
    except Exception as e:
        logger.warn(f"Trips table migration failed (may already be migrated): {e}")


def _init_stripe_products() -> None:
    """Initialiser les produits Stripe."""
    try:
        from src.services.stripe_products_service import StripeProductsService

        StripeProductsService.initialize_products()
    except Exception as e:
        logger.warn(f"Stripe products initialization failed: {e}")


def _seed_default_admin() -> None:
    """Créer l'admin par défaut."""
    try:
        from src.seeds.create_admin import create_default_admin

        create_default_admin()
    except Exception as e:
        logger.warn(f"Default admin seed failed: {e}")


def _start_schedulers() -> list[asyncio.Task]:
    """Lancer tous les jobs planifiés en tâches de fond.

    Each scheduler is Redis-locked internally so multi-worker deployments only
    run one tick per interval. The returned tasks are cancelled at shutdown.
    """
    from src.jobs.currency_refresh_job import currency_refresh_scheduler
    from src.jobs.notification_job import notification_scheduler
    from src.jobs.plan_expiration_job import plan_expiration_scheduler
    from src.jobs.refresh_token_cleanup_job import refresh_token_cleanup_scheduler
    from src.jobs.trip_status_job import trip_status_scheduler
    from src.jobs.zombie_payment_intents_job import zombie_payment_intents_scheduler

    # Order preserved from the original inline lifespan.
    return [
        # Job de transition automatique des statuts de trips
        asyncio.create_task(trip_status_scheduler()),
        # Job de notifications planifiées
        asyncio.create_task(notification_scheduler()),
        # Job d'expiration des plans Premium (downgrade auto si pas de sub active)
        asyncio.create_task(plan_expiration_scheduler()),
        # Job de cleanup des PaymentIntents AUTHORIZED stuck (> 6 jours)
        asyncio.create_task(zombie_payment_intents_scheduler()),
        # Scheduler de refresh des taux de change ECB (topic 04b)
        asyncio.create_task(currency_refresh_scheduler()),
        # Job de purge des refresh tokens revoked / expirés (SMP327-062)
        asyncio.create_task(refresh_token_cleanup_scheduler()),
    ]


async def _stop_schedulers(tasks: list[asyncio.Task]) -> None:
    """Annuler et attendre proprement tous les schedulers."""
    for task in tasks:
        task.cancel()
    for task in tasks:
        with contextlib.suppress(asyncio.CancelledError):
            await task


async def run_startup(app: FastAPI) -> None:
    """Bootstrap exécuté à l'ouverture du lifespan."""
    # Shared outbound HTTP client — every integration wrapper pulls from this
    # pool instead of opening its own per-request AsyncClient.
    await init_http_client()

    _run_db_check()
    _run_trips_migration()
    _init_stripe_products()
    _seed_default_admin()

    app.state.scheduler_tasks = _start_schedulers()


async def run_shutdown(app: FastAPI) -> None:
    """Teardown exécuté à la fermeture du lifespan."""
    tasks: list[asyncio.Task] = getattr(app.state, "scheduler_tasks", [])
    await _stop_schedulers(tasks)

    await close_http_client()
    logger.info("Application shutting down")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Gestion du cycle de vie de l'application."""
    await run_startup(app)
    yield
    await run_shutdown(app)
