"""Routes pour l'agent IA."""

import json
from typing import AsyncGenerator

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from langchain_core.messages import HumanMessage
from pydantic import BaseModel

from src.agent.graph import graph
from src.utils.logger import logger

router = APIRouter(tags=["Agent"])


class ChatRequest(BaseModel):
    """Modèle de requête pour le chat."""
    message: str
    userid: str


async def stream_generator(input_message: str, userid: str) -> AsyncGenerator[str, None]:
    """Générateur pour le streaming SSE de la réponse de l'agent."""
    try:
        # Configuration initiale de l'état
        initial_state = {
            "messages": [HumanMessage(content=input_message)],
            "userid": userid
        }

        # Streaming des événements du graphe
        async for event in graph.astream_events(
            initial_state,
            version="v2",
            config={"configurable": {"thread_id": userid}} # Thread ID pour la mémoire conversationnelle si activée
        ):
            kind = event["event"]

            # Streaming des tokens du chat model
            if kind == "on_chat_model_stream":
                content = event["data"]["chunk"].content
                if content:
                    # Format SSE: data: <json>\n\n
                    data = json.dumps({"type": "token", "content": content})
                    yield f"data: {data}\n\n"

            # Notification d'utilisation d'outil
            elif kind == "on_tool_start":
                tool_name = event["name"]
                data = json.dumps({"type": "tool_start", "tool": tool_name})
                yield f"data: {data}\n\n"

            elif kind == "on_tool_end":
                tool_name = event["name"]
                # output = event["data"].get("output")
                data = json.dumps({"type": "tool_end", "tool": tool_name})
                yield f"data: {data}\n\n"

        # Fin du stream
        yield "data: [DONE]\n\n"

    except Exception as e:
        logger.error("Error in agent stream", {"error": str(e)})
        error_data = json.dumps({"type": "error", "message": str(e)})
        yield f"data: {error_data}\n\n"


@router.post("/agent/chat")
async def chat_endpoint(request: ChatRequest):
    """
    Endpoint SSE pour interagir avec l'agent.
    Retourne un flux d'événements (tokens, usage d'outils).
    """
    logger.info("Starting chat session", {"userid": request.userid})

    return StreamingResponse(
        stream_generator(request.message, request.userid),
        media_type="text/event-stream"
    )
