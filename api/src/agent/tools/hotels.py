"""Outils LangChain pour la recherche d'hôtels."""

import asyncio
from datetime import date
from uuid import UUID

from langchain_core.tools import tool

from src.config.database import SessionLocal
from src.services.context_service import ContextService
from src.services.hotel_search_service import HotelSearchService
from src.utils.errors import AppError
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


@tool
async def search_hotels_tool(
    city_code: str,
    check_in: str,
    check_out: str,
    adults: int = 1,
    children: int = 0,
    trip_id: str | None = None,
    user_id: str | None = None,
    conversation_id: str | None = None,
) -> str:
    """
    Rechercher des hôtels disponibles dans une ville.
    Utilisez cet outil pour trouver des hôtels quand l'utilisateur demande des hébergements.

    Args:
        city_code: Code IATA de la ville (ex: "PAR", "NYC", "ROM")
        check_in: Date d'arrivée au format YYYY-MM-DD (ex: "2024-06-15")
        check_out: Date de départ au format YYYY-MM-DD (ex: "2024-06-20")
        adults: Nombre d'adultes (défaut: 1)
        children: Nombre d'enfants (défaut: 0)
        trip_id: ID du trip (UUID en string)
        user_id: ID de l'utilisateur (UUID en string)
        conversation_id: ID de la conversation (UUID en string, optionnel pour mise à jour contexte)
    """
    try:
        # Valider les paramètres requis
        if not trip_id or not user_id:
            return "Erreur: trip_id et user_id sont requis pour rechercher des hôtels."

        # Convertir les strings en UUID
        try:
            trip_uuid = UUID(trip_id)
            user_uuid = UUID(user_id)
        except ValueError:
            return "Erreur: trip_id et user_id doivent être des UUID valides."

        # Parser les dates
        try:
            check_in_date = date.fromisoformat(check_in)
            check_out_date = date.fromisoformat(check_out)
        except ValueError:
            return "Erreur: Format de date invalide. Utilisez YYYY-MM-DD (ex: 2024-06-15)"

        # Vérifier que check_out est après check_in
        if check_out_date <= check_in_date:
            return "Erreur: La date de départ doit être après la date d'arrivée."

        # Vérifier le cache idempotent (exclure trip_id, user_id, conversation_id qui ne sont pas pertinents pour la recherche)
        cache_params = {
            "city_code": city_code.upper(),
            "check_in": check_in,
            "check_out": check_out,
            "adults": adults,
            "children": children,
        }
        cached_result = idempotency_cache.get("search_hotels", cache_params)
        if cached_result is not None:
            logger.info("Returning cached result for search_hotels")
            return cached_result

        # Créer une session DB
        db = SessionLocal()
        try:
            # Appeler le service de recherche avec timeout
            try:
                search, offers = await asyncio.wait_for(
                    HotelSearchService.create_search(
                        db=db,
                        trip_id=trip_uuid,
                        user_id=user_uuid,
                        city_code=city_code.upper(),
                        check_in=check_in_date,
                        check_out=check_out_date,
                        adults=adults,
                        room_qty=1,  # Par défaut 1 chambre
                    ),
                    timeout=30.0,
                )
            except asyncio.TimeoutError:
                logger.warning("Hotel search timed out after 30s")
                return "Erreur: La recherche d'hôtels a pris trop de temps. Veuillez réessayer."

            # Construire la réponse standardisée
            offers_data = []
            for offer in offers[:10]:  # Limiter à 10 offres pour la réponse
                # Extraire le nom de l'hôtel depuis offer_json
                hotel_name = "Hôtel"
                if offer.offer_json and isinstance(offer.offer_json, dict):
                    hotel_info = offer.offer_json.get("hotel", {})
                    hotel_name = hotel_info.get("name", "Hôtel")

                offers_data.append(
                    {
                        "id": str(offer.id),
                        "hotel_id": offer.hotel_id,
                        "offer_id": offer.offer_id,
                        "hotel_name": hotel_name,
                        "price": float(offer.total_price) if offer.total_price else 0.0,
                        "currency": offer.currency or "EUR",
                        "city_code": city_code.upper(),
                        "check_in": check_in,
                        "check_out": check_out,
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
                            # Extraire le nom de l'hôtel
                            hotel_name = "Hôtel"
                            if offer.offer_json and isinstance(offer.offer_json, dict):
                                hotel_info = offer.offer_json.get("hotel", {})
                                hotel_name = hotel_info.get("name", "Hôtel")

                            widgets.append(
                                {
                                    "type": "HOTEL_OFFER_CARD",
                                    "offer_id": str(offer.id),
                                    "title": hotel_name,
                                    "subtitle": (
                                        f"À partir de {offer.total_price or 0} "
                                        f"{offer.currency or 'EUR'}/nuit"
                                    ),
                                    "actions": [
                                        {"type": "SELECT_HOTEL", "label": "Choisir"},
                                        {"type": "BOOK_HOTEL", "label": "Réserver"},
                                    ],
                                }
                            )

                        # Mettre à jour le contexte
                        new_state = {
                            **context.state,
                            "stage": "proposing",
                            "requirements": {
                                **context.state.get("requirements", {}),
                                "city": city_code.upper(),
                                "dates": {
                                    "check_in": check_in,
                                    "check_out": check_out,
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
                                    "Context version mismatch during hotel search",
                                    {"context_id": str(context.id)},
                                )
                            else:
                                raise
                except Exception as e:
                    logger.error(
                        "Error updating context in search_hotels_tool",
                        {"error": str(e), "conversation_id": conversation_id},
                    )
                    # Ne pas faire échouer la recherche si la mise à jour du contexte échoue

            logger.info(
                "Hotel search completed",
                {
                    "trip_id": trip_id,
                    "user_id": user_id,
                    "search_id": str(search.id),
                    "offers_count": len(offers),
                },
            )

            result_str = str(result)
            # Stocker dans le cache
            idempotency_cache.set("search_hotels", cache_params, result_str)

            return result_str

        finally:
            db.close()

    except Exception as e:
        logger.error("Error in search_hotels_tool", {"error": str(e), "trip_id": trip_id})
        return f"Erreur lors de la recherche d'hôtels: {str(e)}"
