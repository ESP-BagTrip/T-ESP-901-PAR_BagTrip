"""Outils LangChain pour la recherche de vols."""

import asyncio
from datetime import date
from uuid import UUID

from langchain_core.tools import tool

from src.config.database import SessionLocal
from src.services.context_service import ContextService
from src.services.flight_search_service import FlightSearchService
from src.utils.errors import AppError
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


@tool
async def search_flights_tool(
    origin: str,
    destination: str,
    departure_date: str,
    return_date: str | None = None,
    adults: int = 1,
    children: int = 0,
    trip_id: str | None = None,
    user_id: str | None = None,
    conversation_id: str | None = None,
) -> str:
    """
    Rechercher des vols disponibles entre deux destinations.
    Utilisez cet outil pour trouver des vols quand l'utilisateur demande des vols.

    Args:
        origin: Code IATA de l'aéroport d'origine (ex: "CDG", "JFK")
        destination: Code IATA de l'aéroport de destination (ex: "FCO", "LAX")
        departure_date: Date de départ au format YYYY-MM-DD (ex: "2024-06-15")
        return_date: Date de retour au format YYYY-MM-DD (optionnel, pour aller-retour)
        adults: Nombre d'adultes (défaut: 1)
        children: Nombre d'enfants (défaut: 0)
        trip_id: ID du trip (UUID en string)
        user_id: ID de l'utilisateur (UUID en string)
        conversation_id: ID de la conversation (UUID en string, optionnel pour mise à jour contexte)
    """
    try:
        # Valider les paramètres requis
        if not trip_id or not user_id:
            return "Erreur: trip_id et user_id sont requis pour rechercher des vols."

        # Convertir les strings en UUID
        try:
            trip_uuid = UUID(trip_id)
            user_uuid = UUID(user_id)
        except ValueError:
            return "Erreur: trip_id et user_id doivent être des UUID valides."

        # Parser les dates
        try:
            departure = date.fromisoformat(departure_date)
            return_dt = date.fromisoformat(return_date) if return_date else None
        except ValueError:
            return "Erreur: Format de date invalide. Utilisez YYYY-MM-DD (ex: 2024-06-15)"

        # Vérifier le cache idempotent (exclure trip_id, user_id, conversation_id qui ne sont pas pertinents pour la recherche)
        cache_params = {
            "origin": origin.upper(),
            "destination": destination.upper(),
            "departure_date": departure_date,
            "return_date": return_date,
            "adults": adults,
            "children": children,
        }
        cached_result = idempotency_cache.get("search_flights", cache_params)
        if cached_result is not None:
            logger.info("Returning cached result for search_flights")
            return cached_result

        # Créer une session DB
        db = SessionLocal()
        try:
            # Appeler le service de recherche avec timeout
            try:
                search, offers = await asyncio.wait_for(
                    FlightSearchService.create_search(
                        db=db,
                        trip_id=trip_uuid,
                        user_id=user_uuid,
                        origin_iata=origin.upper(),
                        destination_iata=destination.upper(),
                        departure_date=departure,
                        return_date=return_dt,
                        adults=adults,
                        children=children if children > 0 else None,
                    ),
                    timeout=30.0,
                )
            except asyncio.TimeoutError:
                logger.warning("Flight search timed out after 30s")
                return "Erreur: La recherche de vols a pris trop de temps. Veuillez réessayer."

            # Construire la réponse standardisée
            offers_data = []
            for offer in offers[:10]:  # Limiter à 10 offres pour la réponse
                offers_data.append(
                    {
                        "id": str(offer.id),
                        "amadeus_offer_id": offer.amadeus_offer_id,
                        "price": float(offer.grand_total) if offer.grand_total else 0.0,
                        "currency": offer.currency or "EUR",
                        "origin": origin.upper(),
                        "destination": destination.upper(),
                        "departure_date": departure_date,
                        "return_date": return_date,
                    }
                )

            result = {
                "offers": offers_data,
                "search_id": str(search.id),
                "total_offers": len(offers),
            }

            # Mettre à jour le contexte si conversation_id est fourni
            if conversation_id:
                try:
                    conv_uuid = UUID(conversation_id)
                    context = ContextService.get_context(db, user_uuid, trip_uuid, conv_uuid)

                    if context:
                        # Construire les widgets à partir des offres (limiter à 5)
                        widgets = []
                        for offer in offers[:5]:
                            widgets.append(
                                {
                                    "type": "FLIGHT_OFFER_CARD",
                                    "offer_id": str(offer.id),
                                    "title": f"{origin.upper()} → {destination.upper()}",
                                    "subtitle": f"À partir de {offer.grand_total or 0} {offer.currency or 'EUR'}",
                                    "actions": [
                                        {"type": "SELECT_FLIGHT", "label": "Choisir"},
                                        {"type": "BOOK_FLIGHT", "label": "Réserver"},
                                    ],
                                }
                            )

                        # Mettre à jour le contexte
                        new_state = {
                            **context.state,
                            "stage": "proposing",
                            "requirements": {
                                **context.state.get("requirements", {}),
                                "from": origin.upper(),
                                "to": destination.upper(),
                                "dates": {
                                    "start": departure_date,
                                    "end": return_date if return_date else None,
                                },
                            },
                        }

                        new_ui = {
                            **context.ui,
                            "widgets": widgets,
                        }

                        try:
                            ContextService.update_context(
                                db=db,
                                context_id=context.id,
                                state=new_state,
                                ui=new_ui,
                                current_version=context.version,
                            )
                        except AppError as e:
                            if e.code == "CONTEXT_VERSION_MISMATCH":
                                logger.warning(
                                    "Context version mismatch during flight search",
                                    {"context_id": str(context.id)},
                                )
                            else:
                                raise
                except Exception as e:
                    logger.error(
                        "Error updating context in search_flights_tool",
                        {
                            "error": str(e),
                            "conversation_id": conversation_id,
                        },
                    )
                    # Ne pas faire échouer la recherche si la mise à jour du contexte échoue

            logger.info(
                "Flight search completed",
                {
                    "trip_id": trip_id,
                    "user_id": user_id,
                    "search_id": str(search.id),
                    "offers_count": len(offers),
                },
            )

            result_str = str(result)
            # Stocker dans le cache
            idempotency_cache.set("search_flights", cache_params, result_str)

            return result_str

        finally:
            db.close()

    except Exception as e:
        logger.error("Error in search_flights_tool", {"error": str(e), "trip_id": trip_id})
        return f"Erreur lors de la recherche de vols: {str(e)}"
