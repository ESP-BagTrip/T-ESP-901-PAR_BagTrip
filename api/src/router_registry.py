"""Centralised router registration for the FastAPI app.

`main.py` used to carry ~30 inline `app.include_router(...)` calls. They are
extracted here so the app factory stays minimal. The registration order is
preserved verbatim — it is the same order FastAPI matches routes in, so
changing it could shadow paths.
"""

from __future__ import annotations

from fastapi import FastAPI

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
from src.api.health.routes import router as health_router
from src.api.home.routes import router as home_router
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


def register_routers(app: FastAPI) -> None:
    """Mount every API router on the app, all under /v1."""
    # Liveness + readiness probes (no prefix: /health, /health/ready)
    app.include_router(health_router)
    # Routes principales selon PLAN.md
    app.include_router(auth_router)  # Déjà préfixé avec /v1/auth
    app.include_router(admin_router)  # Préfixé avec /admin
    app.include_router(trips_router)  # Déjà préfixé avec /v1/trips
    app.include_router(home_router)  # Déjà préfixé avec /v1/home
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
