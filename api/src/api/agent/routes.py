"""Routes pour l'agent IA."""

import json
from collections.abc import AsyncGenerator
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessage, HumanMessage
from sqlalchemy.orm import Session

from src.agent.graph import graph
from src.api.agent.schemas import ActionRequest, ChatRequest
from src.api.auth.middleware import get_current_user
from src.api.conversations.routes import (
    verify_conversation_ownership,
    verify_trip_ownership,
)
from src.config.database import get_db
from src.models.user import User
from src.services.context_service import ContextService
from src.services.message_service import MessageService
from src.utils.errors import AppError, create_http_exception
from src.utils.logger import logger

router = APIRouter(prefix="/v1/agent", tags=["Agent"])


async def emit_sse_event(event_type: str, data: dict) -> str:
    """Helper pour émettre un événement SSE au format standard."""
    event_data = json.dumps(data)
    return f"event: {event_type}\ndata: {event_data}\n\n"


async def stream_agent_response(
    db: Session,
    user_id: UUID,
    trip_id: UUID,
    conversation_id: UUID,
    message_history: list,
    context_version: int | None,
    context_id: UUID | None,
) -> AsyncGenerator[str]:
    """Générateur pour le streaming SSE de la réponse de l'agent avec gestion du contexte."""
    assistant_message_id = None
    full_response_text = ""
    current_context = None

    try:
        # Charger le contexte actuel
        if context_id:
            from src.models.context import Context

            current_context = db.query(Context).filter(Context.id == context_id).first()

        # Utiliser l'historique des messages complet pour l'agent
        initial_state = {
            "messages": message_history,
            "userid": str(user_id),
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "context_version": context_version,
        }

        # Variable pour suivre les événements
        event_count = 0

        logger.info(
            "Starting agent stream",
            {
                "user_id": str(user_id),
                "trip_id": str(trip_id),
                "conversation_id": str(conversation_id),
                "message_count": len(message_history),
            },
        )

        # Streaming des événements du graphe
        async for event in graph.astream_events(
            initial_state,
            version="v2",
            config={
                "configurable": {"thread_id": str(user_id)}
            },  # Thread ID pour la mémoire conversationnelle si activée
        ):
            event_count += 1
            kind = event["event"]
            event_name = event.get("name", "")

            # Streaming des tokens du chat model
            if kind == "on_chat_model_stream":
                content = event["data"]["chunk"].content
                if content:
                    full_response_text += content
                    # Émettre message.delta
                    yield await emit_sse_event(
                        "message.delta",
                        {"text": content},
                    )

            # Capturer le message final si le streaming n'a pas eu lieu (ainvoke au lieu d'astream)
            elif kind == "on_chain_end" and event_name == "agent":
                # Extraire le message de la réponse
                output = event.get("data", {}).get("output", {})
                if isinstance(output, dict) and "messages" in output:
                    messages = output["messages"]
                    if messages:
                        last_message = messages[-1]
                        if hasattr(last_message, "content"):
                            message_content = last_message.content
                            last_ai_message = message_content
                            if message_content and not full_response_text:
                                # Si on n'a pas eu de streaming, utiliser le message complet
                                full_response_text = message_content
                                # Émettre le message complet comme delta unique
                                yield await emit_sse_event(
                                    "message.delta",
                                    {"text": message_content},
                                )

            # Capturer aussi les messages AI depuis les événements de mise à jour d'état
            elif kind == "on_chain_stream" and event_name == "agent":
                chunk = event.get("data", {}).get("chunk", {})
                if isinstance(chunk, dict) and "messages" in chunk:
                    messages = chunk["messages"]
                    if messages:
                        last_message = messages[-1]
                        if hasattr(last_message, "content"):
                            message_content = last_message.content
                            if message_content and message_content != full_response_text:
                                # Nouveau contenu détecté
                                new_content = message_content[len(full_response_text):]
                                if new_content:
                                    full_response_text = message_content
                                    yield await emit_sse_event(
                                        "message.delta",
                                        {"text": new_content},
                                    )

            # Notification d'utilisation d'outil
            elif kind == "on_tool_start":
                tool_name = event["name"]
                yield await emit_sse_event(
                    "tool.start",
                    {"tool": tool_name},
                )

            elif kind == "on_tool_end":
                tool_name = event["name"]
                yield await emit_sse_event(
                    "tool.end",
                    {"tool": tool_name},
                )

                # Après chaque tool, mettre à jour le contexte si disponible
                if current_context:
                    # Recharger le contexte pour avoir la dernière version
                    updated_context = ContextService.get_context(
                        db, user_id, trip_id, conversation_id
                    )
                    if updated_context:
                        current_context = updated_context
                        yield await emit_sse_event(
                            "context.updated",
                            {
                                "version": updated_context.version,
                                "state": updated_context.state,
                                "ui": updated_context.ui,
                            },
                        )

        # Si on n'a pas capturé de texte mais qu'on a un message final, l'utiliser
        if not full_response_text and last_ai_message:
            full_response_text = last_ai_message
            # Émettre le message complet
            yield await emit_sse_event(
                "message.delta",
                {"text": full_response_text},
            )

        logger.info(
            "Agent stream completed",
            {
                "user_id": str(user_id),
                "trip_id": str(trip_id),
                "conversation_id": str(conversation_id),
                "event_count": event_count,
                "has_response": bool(full_response_text),
                "response_length": len(full_response_text) if full_response_text else 0,
            },
        )

        # Log si aucune réponse n'a été générée
        if not full_response_text:
            logger.warning(
                "No response generated by agent",
                {
                    "user_id": str(user_id),
                    "trip_id": str(trip_id),
                    "conversation_id": str(conversation_id),
                    "message_count": len(message_history),
                    "event_count": event_count,
                },
            )
            # Émettre une erreur pour informer le client
            yield await emit_sse_event(
                "error",
                {"message": "L'agent n'a pas généré de réponse. Veuillez réessayer."},
            )
            return

        # Persister le message assistant
        if full_response_text:
            assistant_message = MessageService.create_message(
                db=db,
                conversation_id=conversation_id,
                role="assistant",
                content=full_response_text,
                message_metadata={
                    "context_version": current_context.version if current_context else None
                },
            )
            assistant_message_id = assistant_message.id

            # Émettre message.final
            yield await emit_sse_event(
                "message.final",
                {
                    "message_id": str(assistant_message_id),
                    "text": full_response_text,
                },
            )

        # Mettre à jour le contexte version si nécessaire
        if current_context:
            try:
                # Incrémenter la version du contexte après la réponse
                ContextService.increment_context_version(db, current_context.id)
                updated_context = ContextService.get_context(db, user_id, trip_id, conversation_id)
                if updated_context:
                    yield await emit_sse_event(
                        "context.updated",
                        {
                            "version": updated_context.version,
                            "state": updated_context.state,
                            "ui": updated_context.ui,
                        },
                    )
            except Exception as e:
                logger.error(
                    "Error updating context version",
                    {"error": str(e), "context_id": str(current_context.id)},
                )

    except Exception as e:
        logger.error("Error in agent stream", {"error": str(e)})
        yield await emit_sse_event(
            "error",
            {"message": str(e)},
        )


@router.post("/chat")
async def chat_endpoint(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint SSE pour interagir avec l'agent.
    Retourne un flux d'événements (tokens, usage d'outils, contexte).
    """
    try:
        # Vérifier ownership du trip
        await verify_trip_ownership(db, request.trip_id, current_user.id)

        # Vérifier ownership de la conversation
        conversation = await verify_conversation_ownership(
            db, request.conversation_id, current_user.id
        )

        # Vérifier que la conversation appartient au trip
        if conversation.trip_id != request.trip_id:
            raise AppError("INVALID_REQUEST", 400, "Trip ID does not match conversation")

        # Charger ou créer le contexte
        context = ContextService.get_context(
            db, current_user.id, request.trip_id, request.conversation_id
        )

        # Vérifier context_version (optimistic locking)
        if request.context_version is not None:
            if not context:
                raise HTTPException(
                    status_code=409,
                    detail={
                        "error": "stale_context",
                        "message": "Context not found but version provided. Please refresh and try again.",
                        "client_version": request.context_version,
                    },
                )
            if context.version != request.context_version:
                raise HTTPException(
                    status_code=409,
                    detail={
                        "error": "stale_context",
                        "message": (
                            "Context version mismatch. "
                            "Please refresh and try again."
                        ),
                        "current_version": context.version,
                        "client_version": request.context_version,
                    },
                )

        # Créer le contexte s'il n'existe pas
        if not context:
            context = ContextService.create_context(
                db=db,
                user_id=current_user.id,
                trip_id=request.trip_id,
                conversation_id=request.conversation_id,
                state={
                    "stage": "collecting_requirements",
                    "requirements": {},
                    "selected": {"flight_offer_id": None, "hotel_offer_id": None},
                },
                ui={"widgets": [], "quick_replies": []},
            )

        # Charger les derniers messages (20 max)
        messages = MessageService.get_messages_by_conversation(
            db, request.conversation_id, limit=20
        )

        # Construire l'historique des messages pour l'agent
        message_history = []
        for msg in messages:
            if msg.role == "user":
                message_history.append(HumanMessage(content=msg.content))
            elif msg.role == "assistant":
                message_history.append(AIMessage(content=msg.content))

        # Ajouter le nouveau message utilisateur
        message_history.append(HumanMessage(content=request.message))

        # Persister le message utilisateur
        MessageService.create_message(
            db=db,
            conversation_id=request.conversation_id,
            role="user",
            content=request.message,
        )

        logger.info(
            "Starting chat session",
            {
                "user_id": str(current_user.id),
                "trip_id": str(request.trip_id),
                "conversation_id": str(request.conversation_id),
                "context_version": context.version,
            },
        )

        # Stream la réponse de l'agent
        return StreamingResponse(
            stream_agent_response(
                db=db,
                user_id=current_user.id,
                trip_id=request.trip_id,
                conversation_id=request.conversation_id,
                message_history=message_history,
                context_version=context.version,
                context_id=context.id,
            ),
            media_type="text/event-stream",
        )

    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        logger.error("Unexpected error in chat_endpoint", {"error": str(e)})
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, f"Internal server error: {str(e)}")
        ) from e


@router.post("/actions")
async def agent_actions(
    request: ActionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint pour les actions rapides des widgets (SELECT/BOOK).
    """
    try:
        # Vérifier ownership du trip
        await verify_trip_ownership(db, request.trip_id, current_user.id)

        # Vérifier ownership de la conversation
        conversation = await verify_conversation_ownership(
            db, request.conversation_id, current_user.id
        )

        # Vérifier que la conversation appartient au trip
        if conversation.trip_id != request.trip_id:
            raise AppError("INVALID_REQUEST", 400, "Trip ID does not match conversation")

        # Charger le contexte
        context = ContextService.get_context(
            db, current_user.id, request.trip_id, request.conversation_id
        )
        if not context:
            raise AppError("CONTEXT_NOT_FOUND", 404, "Context not found")

        # Vérifier context_version (optimistic locking)
        if (
            request.context_version is not None
            and context.version != request.context_version
        ):
            raise HTTPException(
                status_code=409,
                detail={
                    "error": "stale_context",
                    "message": "Context version mismatch. Please refresh and try again.",
                    "current_version": context.version,
                    "client_version": request.context_version,
                },
            )

        # Parser l'action
        action_type = request.action.get("type")
        offer_id = request.action.get("offer_id")

        if not action_type or not offer_id:
            raise AppError(
                "INVALID_REQUEST", 400, "Action must contain 'type' and 'offer_id'"
            )

        # Valider le type d'action
        valid_actions = ["SELECT_FLIGHT", "BOOK_FLIGHT", "SELECT_HOTEL", "BOOK_HOTEL"]
        if action_type not in valid_actions:
            raise AppError(
                "INVALID_REQUEST",
                400,
                f"Invalid action type. Must be one of {valid_actions}",
            )

        # Convertir offer_id en UUID
        try:
            UUID(offer_id)
        except ValueError as e:
            raise AppError("INVALID_REQUEST", 400, "offer_id must be a valid UUID") from e

        # Déterminer le type d'offre et l'action à exécuter
        offer_type = "flight" if action_type in ["SELECT_FLIGHT", "BOOK_FLIGHT"] else "hotel"

        # Exécuter l'action via les tools
        from src.agent.tools.offers import book_offer_tool, select_offer_tool

        tool_params = {
            "offer_id": offer_id,
            "offer_type": offer_type,
            "trip_id": str(request.trip_id),
            "user_id": str(current_user.id),
            "conversation_id": str(request.conversation_id),
        }

        if action_type in ["SELECT_FLIGHT", "SELECT_HOTEL"]:
            # Appeler select_offer_tool
            result = await select_offer_tool.ainvoke(tool_params)
        else:  # BOOK_FLIGHT or BOOK_HOTEL
            # Appeler book_offer_tool
            result = await book_offer_tool.ainvoke(tool_params)

        # Recharger le contexte mis à jour
        updated_context = ContextService.get_context(
            db, current_user.id, request.trip_id, request.conversation_id
        )

        logger.info(
            "Action executed",
            {
                "action_type": action_type,
                "offer_id": offer_id,
                "trip_id": str(request.trip_id),
                "conversation_id": str(request.conversation_id),
                "user_id": str(current_user.id),
            },
        )

        return {
            "success": True,
            "action": action_type,
            "offer_id": offer_id,
            "context": {
                "version": updated_context.version if updated_context else None,
                "state": updated_context.state if updated_context else None,
                "ui": updated_context.ui if updated_context else None,
            },
            "result": result,
        }

    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e
    except Exception as e:
        logger.error("Unexpected error in agent_actions", {"error": str(e)})
        raise create_http_exception(
            AppError("INTERNAL_ERROR", 500, f"Internal server error: {str(e)}")
        ) from e
