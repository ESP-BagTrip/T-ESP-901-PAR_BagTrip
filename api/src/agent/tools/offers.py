"""Outils LangChain pour la gestion des offres (sélection et réservation)."""

from uuid import UUID

from langchain_core.tools import tool

from src.config.database import SessionLocal
from src.models.flight_offer import FlightOffer
from src.models.hotel_offer import HotelOffer
from src.services.booking_intents_service import BookingIntentsService
from src.services.context_service import ContextService
from src.utils.errors import AppError
from src.utils.logger import logger


@tool
async def select_offer_tool(
    offer_id: str,
    offer_type: str,  # "flight" | "hotel"
    trip_id: str | None = None,
    user_id: str | None = None,
    conversation_id: str | None = None,
) -> str:
    """
    Sélectionner une offre (vol ou hôtel).
    Met à jour le contexte pour indiquer que cette offre a été sélectionnée.

    Args:
        offer_id: ID de l'offre à sélectionner (UUID en string)
        offer_type: Type d'offre ("flight" ou "hotel")
        trip_id: ID du trip (UUID en string)
        user_id: ID de l'utilisateur (UUID en string)
        conversation_id: ID de la conversation (UUID en string, optionnel pour mise à jour contexte)
    """
    try:
        # Valider les paramètres
        if not offer_id or not offer_type or not trip_id or not user_id:
            return "Erreur: offer_id, offer_type, trip_id et user_id sont requis."

        if offer_type not in ["flight", "hotel"]:
            return "Erreur: offer_type doit être 'flight' ou 'hotel'."

        # Convertir les strings en UUID
        try:
            offer_uuid = UUID(offer_id)
            trip_uuid = UUID(trip_id)
            user_uuid = UUID(user_id)
        except ValueError:
            return "Erreur: Les IDs doivent être des UUID valides."

        # Créer une session DB
        db = SessionLocal()
        try:
            # Vérifier que l'offre existe et appartient au trip
            if offer_type == "flight":
                offer = (
                    db.query(FlightOffer)
                    .filter(
                        FlightOffer.id == offer_uuid,
                        FlightOffer.trip_id == trip_uuid,
                    )
                    .first()
                )
                if not offer:
                    return "Erreur: Offre de vol non trouvée ou n'appartient pas à ce trip."
            else:  # hotel
                offer = (
                    db.query(HotelOffer)
                    .filter(
                        HotelOffer.id == offer_uuid,
                        HotelOffer.trip_id == trip_uuid,
                    )
                    .first()
                )
                if not offer:
                    return "Erreur: Offre d'hôtel non trouvée ou n'appartient pas à ce trip."

            # Mettre à jour le contexte si conversation_id est fourni
            if conversation_id:
                try:
                    conv_uuid = UUID(conversation_id)
                    context = ContextService.get_context(db, user_uuid, trip_uuid, conv_uuid)

                    if context:
                        # Mettre à jour context.state.selected
                        new_state = {
                            **context.state,
                            "selected": {
                                **context.state.get("selected", {}),
                                "flight_offer_id": (
                                    offer_id
                                    if offer_type == "flight"
                                    else context.state.get("selected", {}).get(
                                        "flight_offer_id"
                                    )
                                ),
                                "hotel_offer_id": (
                                    offer_id
                                    if offer_type == "hotel"
                                    else context.state.get("selected", {}).get(
                                        "hotel_offer_id"
                                    )
                                ),
                            },
                        }

                        try:
                            ContextService.update_context(
                                db=db,
                                context_id=context.id,
                                state=new_state,
                                ui=context.ui,
                                current_version=context.version,
                            )
                        except AppError as e:
                            if e.code == "CONTEXT_VERSION_MISMATCH":
                                logger.warning(
                                    "Context version mismatch during offer selection",
                                    {"context_id": str(context.id)},
                                )
                            else:
                                raise
                except Exception as e:
                    logger.error(
                        "Error updating context in select_offer_tool",
                        {"error": str(e), "conversation_id": conversation_id},
                    )
                    # Ne pas faire échouer la sélection si la mise à jour du contexte échoue

            result = {
                "success": True,
                "offer_id": offer_id,
                "offer_type": offer_type,
                "message": f"Offre {offer_type} sélectionnée avec succès.",
            }

            logger.info(
                "Offer selected",
                {
                    "offer_id": offer_id,
                    "offer_type": offer_type,
                    "trip_id": trip_id,
                    "user_id": user_id,
                },
            )

            return str(result)

        finally:
            db.close()

    except Exception as e:
        logger.error("Error in select_offer_tool", {"error": str(e), "offer_id": offer_id})
        return f"Erreur lors de la sélection de l'offre: {str(e)}"


@tool
async def book_offer_tool(
    offer_id: str,
    offer_type: str,  # "flight" | "hotel"
    trip_id: str | None = None,
    user_id: str | None = None,
    conversation_id: str | None = None,
) -> str:
    """
    Réserver une offre (vol ou hôtel).
    Pour le POC, crée un BookingIntent qui sera traité plus tard.

    Args:
        offer_id: ID de l'offre à réserver (UUID en string)
        offer_type: Type d'offre ("flight" ou "hotel")
        trip_id: ID du trip (UUID en string)
        user_id: ID de l'utilisateur (UUID en string)
        conversation_id: ID de la conversation (UUID en string, optionnel pour mise à jour contexte)
    """
    try:
        # Valider les paramètres
        if not offer_id or not offer_type or not trip_id or not user_id:
            return "Erreur: offer_id, offer_type, trip_id et user_id sont requis."

        if offer_type not in ["flight", "hotel"]:
            return "Erreur: offer_type doit être 'flight' ou 'hotel'."

        # Convertir les strings en UUID
        try:
            offer_uuid = UUID(offer_id)
            trip_uuid = UUID(trip_id)
            user_uuid = UUID(user_id)
        except ValueError:
            return "Erreur: Les IDs doivent être des UUID valides."

        # Créer une session DB
        db = SessionLocal()
        try:
            # Créer le booking intent
            try:
                if offer_type == "flight":
                    booking_intent = BookingIntentsService.create_intent(
                        db=db,
                        trip_id=trip_uuid,
                        user_id=user_uuid,
                        type="flight",
                        flight_offer_id=offer_uuid,
                    )
                else:  # hotel
                    booking_intent = BookingIntentsService.create_intent(
                        db=db,
                        trip_id=trip_uuid,
                        user_id=user_uuid,
                        type="hotel",
                        hotel_offer_id=offer_uuid,
                    )

                # Mettre à jour le contexte si conversation_id est fourni
                if conversation_id:
                    try:
                        conv_uuid = UUID(conversation_id)
                        context = ContextService.get_context(db, user_uuid, trip_uuid, conv_uuid)

                        if context:
                            # Mettre à jour le stage à "booking"
                            new_state = {
                                **context.state,
                                "stage": "booking",
                            }

                            try:
                                ContextService.update_context(
                                    db=db,
                                    context_id=context.id,
                                    state=new_state,
                                    ui=context.ui,
                                    current_version=context.version,
                                )
                            except AppError as e:
                                if e.code == "CONTEXT_VERSION_MISMATCH":
                                    logger.warning(
                                        "Context version mismatch during booking",
                                        {"context_id": str(context.id)},
                                    )
                                else:
                                    raise
                    except Exception as e:
                        logger.error(
                            "Error updating context in book_offer_tool",
                            {
                                "error": str(e),
                                "conversation_id": conversation_id,
                            },
                        )
                        # Ne pas faire échouer la réservation si la mise à jour du contexte échoue

                result = {
                    "success": True,
                    "booking_intent_id": str(booking_intent.id),
                    "offer_id": offer_id,
                    "offer_type": offer_type,
                    "message": f"Réservation {offer_type} créée avec succès. ID: {booking_intent.id}",
                }

                logger.info(
                    "Booking intent created",
                    {
                        "booking_intent_id": str(booking_intent.id),
                        "offer_id": offer_id,
                        "offer_type": offer_type,
                        "trip_id": trip_id,
                        "user_id": user_id,
                    },
                )

                return str(result)

            except AppError as e:
                return f"Erreur lors de la création de la réservation: {e.message}"

        finally:
            db.close()

    except Exception as e:
        logger.error("Error in book_offer_tool", {"error": str(e), "offer_id": offer_id})
        return f"Erreur lors de la réservation: {str(e)}"
