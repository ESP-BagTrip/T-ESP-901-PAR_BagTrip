"""Point d'entrée FastAPI."""

import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api.admin.routes import router as admin_router
from src.api.agent.routes import router as agent_router
from src.api.auth.routes import router as auth_router
from src.api.booking.routes import router as booking_router
from src.api.booking_intents.book_routes import router as booking_intents_book_router
from src.api.booking_intents.routes import router as booking_intents_router
from src.api.conversations.routes import (
    detail_router as conversations_detail_router,
)
from src.api.conversations.routes import (
    router as conversations_router,
)
from src.api.flights.offers.routes import router as flight_offers_router
from src.api.flights.searches.routes import router as flight_searches_router
from src.api.hotels.offers.routes import router as hotel_offers_router
from src.api.hotels.searches.routes import router as hotel_searches_router
from src.api.messages.routes import router as messages_router
from src.api.payments.routes import router as payments_router
from src.api.profile.routes import router as profile_router
from src.api.stripe.webhooks.routes import router as stripe_webhooks_router
from src.api.travel.routes import router as travel_router
from src.api.travelers.routes import router as travelers_router
from src.api.trips.routes import router as trips_router
from src.config.database import Base, check_database_connection, engine
from src.config.env import settings
from src.middleware.rate_limit import auth_rate_limit_middleware, rate_limit_middleware
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import LogLevel, logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application."""
    # Vérifier la connexion à la base de données avant de créer les tables
    logger.info("Checking database connection...")
    check_database_connection()
    logger.info("Database connection successful")

    # Migrer la table users si nécessaire
    try:
        from src.migrations.migrate_user_table import migrate_user_table

        migrate_user_table(engine)
    except Exception as e:
        logger.warn(f"User table migration failed (may already be migrated): {e}")

    # Migrer les tables de booking si nécessaire
    try:
        from src.migrations.migrate_booking_tables import migrate_booking_tables

        migrate_booking_tables(engine)
    except Exception as e:
        logger.warn(f"Booking tables migration failed (may already be migrated): {e}")

    # Migrer les tables de conversation si nécessaire
    try:
        from src.migrations.migrate_conversation_tables import migrate_conversation_tables

        migrate_conversation_tables(engine)
    except Exception as e:
        logger.warn(f"Conversation tables migration failed (may already be migrated): {e}")

    # Migrer la table refresh_tokens si nécessaire
    try:
        from src.migrations.migrate_refresh_tokens import migrate_refresh_tokens

        migrate_refresh_tokens(engine)
    except Exception as e:
        logger.warn(f"Refresh tokens migration failed (may already be migrated): {e}")

    # Migrer la table traveler_profiles si nécessaire
    try:
        from src.migrations.migrate_traveler_profiles import migrate_traveler_profiles

        migrate_traveler_profiles(engine)
    except Exception as e:
        logger.warn(f"Traveler profiles migration failed (may already be migrated): {e}")

    # Initialiser les produits Stripe
    try:
        from src.services.stripe_products_service import StripeProductsService

        StripeProductsService.initialize_products()
    except Exception as e:
        logger.warn(f"Stripe products initialization failed: {e}")

    # Créer les tables au démarrage
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created")
    yield
    # Nettoyage à l'arrêt (si nécessaire)
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
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiting middleware (après CORS)
app.middleware("http")(rate_limit_middleware)
app.middleware("http")(auth_rate_limit_middleware)

# Inclusion des routes - toutes sous /v1
# Routes principales selon PLAN.md
app.include_router(auth_router)  # Déjà préfixé avec /v1/auth
app.include_router(admin_router)  # Préfixé avec /admin
app.include_router(trips_router)  # Déjà préfixé avec /v1/trips
app.include_router(travelers_router)  # Déjà préfixé avec /v1/trips
app.include_router(conversations_router)  # Préfixé avec /v1/trips/{tripId}/conversations
app.include_router(conversations_detail_router)  # Préfixé avec /v1/conversations
app.include_router(messages_router)  # Préfixé avec /v1/conversations/{conversationId}/messages
app.include_router(flight_searches_router)  # Déjà préfixé avec /v1/trips
app.include_router(flight_offers_router)  # Déjà préfixé avec /v1/trips
app.include_router(hotel_searches_router)  # Déjà préfixé avec /v1/trips
app.include_router(hotel_offers_router)  # Déjà préfixé avec /v1/trips
app.include_router(booking_intents_router)  # Déjà préfixé avec /v1/trips
app.include_router(booking_intents_book_router)  # Déjà préfixé avec /v1/booking-intents
app.include_router(payments_router)  # Déjà préfixé avec /v1/booking-intents
app.include_router(stripe_webhooks_router)  # Déjà préfixé avec /v1/stripe

# Routes utilitaires
app.include_router(travel_router)  # Déjà préfixé avec /v1/travel (locations, inspirations)
app.include_router(agent_router)  # Déjà préfixé avec /v1/agent

# Routes dépréciées (ancien pattern, remplacé par booking_intents)
# Conservées pour compatibilité mais marquées comme deprecated
app.include_router(profile_router)  # Préfixé avec /v1/profile
app.include_router(booking_router)  # DÉPRÉCIÉ - utiliser /v1/trips/{tripId}/booking-intents


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
    return create_http_exception(exc)


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

    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.NODE_ENV == "development",
        log_level="debug" if settings.NODE_ENV == "development" else "info",
    )
