"""Point d'entrée FastAPI."""

import asyncio
import contextlib
import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api.accommodations.routes import router as accommodations_router
from src.api.activities.routes import router as activities_router
from src.api.admin.routes import router as admin_router
from src.api.ai.plan_trip_routes import router as ai_plan_trip_router
from src.api.ai.post_trip_routes import router as ai_post_trip_router
from src.api.auth.routes import router as auth_router
from src.api.baggage.routes import router as baggage_router
from src.api.booking.routes import router as booking_router
from src.api.booking_intents.book_routes import router as booking_intents_book_router
from src.api.booking_intents.routes import router as booking_intents_router
from src.api.budget_items.routes import router as budget_items_router
from src.api.device_tokens.routes import router as device_tokens_router
from src.api.feedback.routes import router as feedback_router
from src.api.flights.info.routes import router as flight_info_router
from src.api.flights.manual.routes import router as manual_flights_router
from src.api.flights.offers.routes import router as flight_offers_router
from src.api.flights.orders.routes import router as flight_orders_router
from src.api.flights.searches.routes import router as flight_searches_router
from src.api.hotels.routes import router as hotel_search_router
from src.api.invites.routes import router as invites_router
from src.api.notifications.routes import router as notifications_router
from src.api.payments.routes import router as payments_router
from src.api.profile.routes import router as profile_router
from src.api.shares.routes import router as shares_router
from src.api.stripe.webhooks.routes import router as stripe_webhooks_router
from src.api.subscription.routes import router as subscription_router
from src.api.travel.routes import router as travel_router
from src.api.travelers.routes import router as travelers_router
from src.api.trips.routes import router as trips_router
from src.config.database import check_database_connection, engine
from src.config.env import settings
from src.integrations.http_client import close_http_client, init_http_client
from src.middleware.rate_limit import auth_rate_limit_middleware, rate_limit_middleware
from src.middleware.request_id import request_id_middleware
from src.middleware.security_headers import security_headers_middleware
from src.utils.errors import AppError
from src.utils.logger import LogLevel, logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application."""
    # Shared outbound HTTP client — every integration wrapper pulls from this
    # pool instead of opening its own per-request AsyncClient.
    await init_http_client()

    # Vérifier la connexion à la base de données avant de créer les tables
    logger.info("Checking database connection...")
    check_database_connection()
    logger.info("Database connection successful")

    # Schema managed by: alembic upgrade head

    # Migrer la table trips si nécessaire
    try:
        from src.migrations.migrate_trips_table import migrate_trips_table

        migrate_trips_table(engine)
    except Exception as e:
        logger.warn(f"Trips table migration failed (may already be migrated): {e}")

    # Initialiser les produits Stripe
    try:
        from src.services.stripe_products_service import StripeProductsService

        StripeProductsService.initialize_products()
    except Exception as e:
        logger.warn(f"Stripe products initialization failed: {e}")

    # Créer l'admin par défaut
    try:
        from src.seeds.create_admin import create_default_admin

        create_default_admin()
    except Exception as e:
        logger.warn(f"Default admin seed failed: {e}")

    # Lancer le job de transition automatique des statuts de trips
    from src.jobs.trip_status_job import trip_status_scheduler

    scheduler_task = asyncio.create_task(trip_status_scheduler())

    # Lancer le job de notifications planifiées
    from src.jobs.notification_job import notification_scheduler

    notif_scheduler_task = asyncio.create_task(notification_scheduler())

    yield

    # Arrêter les schedulers
    scheduler_task.cancel()
    notif_scheduler_task.cancel()
    with contextlib.suppress(asyncio.CancelledError):
        await scheduler_task
    with contextlib.suppress(asyncio.CancelledError):
        await notif_scheduler_task

    await close_http_client()
    logger.info("Application shutting down")


app = FastAPI(
    title="BagTrip API",
    description="API Python pour BagTrip avec intégration Amadeus",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting middleware (après CORS)
app.middleware("http")(rate_limit_middleware)
app.middleware("http")(auth_rate_limit_middleware)

# Security headers — added after auth middlewares so they wrap every response.
app.middleware("http")(security_headers_middleware)

# Request-ID middleware must run OUTERMOST — FastAPI runs middlewares in
# reverse registration order, so registering last means this is the first
# middleware to see the request and the last to see the response. That way
# every other middleware and handler logs with the request id already set.
app.middleware("http")(request_id_middleware)

# Inclusion des routes - toutes sous /v1
# Routes principales selon PLAN.md
app.include_router(auth_router)  # Déjà préfixé avec /v1/auth
app.include_router(admin_router)  # Préfixé avec /admin
app.include_router(trips_router)  # Déjà préfixé avec /v1/trips
app.include_router(travelers_router)  # Déjà préfixé avec /v1/trips
app.include_router(activities_router)  # Déjà préfixé avec /v1/trips
app.include_router(accommodations_router)  # Déjà préfixé avec /v1/trips
app.include_router(baggage_router)  # Déjà préfixé avec /v1/trips
app.include_router(shares_router)  # Déjà préfixé avec /v1/trips
app.include_router(invites_router)  # Préfixé avec /v1/invites
app.include_router(budget_items_router)  # Déjà préfixé avec /v1/trips
app.include_router(feedback_router)  # Déjà préfixé avec /v1/trips
app.include_router(flight_searches_router)  # Déjà préfixé avec /v1/trips
app.include_router(flight_offers_router)  # Déjà préfixé avec /v1/trips
app.include_router(flight_orders_router)  # Déjà préfixé avec /v1/trips
app.include_router(manual_flights_router)  # Déjà préfixé avec /v1/trips
app.include_router(flight_info_router)  # Déjà préfixé avec /v1/travel/flights
app.include_router(booking_intents_router)  # Déjà préfixé avec /v1/trips
app.include_router(booking_intents_book_router)  # Déjà préfixé avec /v1/booking-intents
app.include_router(payments_router)  # Déjà préfixé avec /v1/booking-intents
app.include_router(stripe_webhooks_router)  # Déjà préfixé avec /v1/stripe
app.include_router(subscription_router)  # Préfixé avec /v1/subscription
app.include_router(device_tokens_router)  # Déjà préfixé avec /v1/device-tokens
app.include_router(notifications_router)  # Déjà préfixé avec /v1/notifications

# Routes utilitaires
app.include_router(travel_router)  # Déjà préfixé avec /v1/travel (locations, inspirations)

# Routes dépréciées (ancien pattern, remplacé par booking_intents)
# Conservées pour compatibilité mais marquées comme deprecated
app.include_router(profile_router)  # Préfixé avec /v1/profile
app.include_router(booking_router)  # DÉPRÉCIÉ - utiliser /v1/trips/{tripId}/booking-intents

# Routes IA
app.include_router(ai_post_trip_router)
app.include_router(ai_plan_trip_router)
app.include_router(hotel_search_router)


# Gestion globale des erreurs
@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    """Gestionnaire d'erreurs pour AppError."""
    # Logger l'erreur avec plus de détails en mode debug
    if logger.level == LogLevel.DEBUG:
        logger.error(
            f"AppError: {exc.code}",
            {
                "code": exc.code,
                "status_code": exc.status_code,
                "message": exc.message,
                "detail": exc.detail,
                "path": request.url.path,
                "method": request.method,
            },
        )

    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": {
                "error": exc.message,
                "code": exc.code,
                **(exc.detail or {}),
            }
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Gestionnaire d'erreurs général."""
    # En mode debug, logger avec traceback complète
    if logger.level == LogLevel.DEBUG:
        logger.error(
            f"Unhandled exception: {type(exc).__name__}",
            {
                "error": str(exc),
                "path": request.url.path,
                "method": request.method,
            },
            exc_info=True,
        )
    else:
        logger.error(
            "Unhandled exception",
            {"error": str(exc), "path": request.url.path, "method": request.method},
        )

    # En mode debug, inclure plus de détails dans la réponse
    detail = str(exc)
    if logger.level == LogLevel.DEBUG:
        detail = {
            "error": str(exc),
            "type": type(exc).__name__,
            "traceback": traceback.format_exc(),
        }

    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "detail": detail},
    )


@app.get("/")
async def root():
    """Route racine."""
    return {"message": "BagTrip API", "version": "1.0.0"}


@app.get("/health")
async def health():
    """Route de santé."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    # Bandit B104: binding inside docker is intentional — the container only
    # exposes the port through the docker-compose network, not public internet.
    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",  # nosec B104
        port=settings.PORT,
        reload=settings.NODE_ENV == "development",
        log_level="debug" if settings.NODE_ENV == "development" else "info",
    )
