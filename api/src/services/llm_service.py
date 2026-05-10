"""Backward-compatible facade over :class:`LLMRouter`.

Existing call sites (``activity_planner_node``, ``baggage_node``,
``react_executor`` …) consume three legacy methods:

- :meth:`call_llm` / :meth:`acall_llm` — system + user prompt → JSON dict
- :meth:`acall_llm_messages` — list of LangChain message objects → raw string

This module preserves those contracts so the agent code keeps working
while :class:`LLMRouter` becomes the single ingress to the provider.
New code should import :class:`LLMRouter` directly and use its
:meth:`chat_completion` / :meth:`stream_chat_completion` / :meth:`embed`
surface, which exposes tool use, structured outputs, streaming and the
fallback chain.
"""

from __future__ import annotations

import json
import re
from typing import Any

from langchain_core.messages import (
    AIMessage,
    BaseMessage,
    HumanMessage,
    SystemMessage,
)

from src.services.llm_router import LLMRouter
from src.utils.errors import AppError


def _strip_markdown_fences(text: str) -> str:
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*\n?", "", text)
    text = re.sub(r"\n?```\s*$", "", text)
    return text.strip()


def _message_to_openai_dict(msg: BaseMessage) -> dict[str, Any]:
    """Translate a LangChain message into the OpenAI chat schema.

    The agent code still constructs prompts with LangChain message
    objects (``SystemMessage`` / ``HumanMessage`` / ``AIMessage``);
    this keeps that boundary stable while we migrate node by node.
    """
    if isinstance(msg, SystemMessage):
        return {"role": "system", "content": msg.content}
    if isinstance(msg, HumanMessage):
        return {"role": "user", "content": msg.content}
    if isinstance(msg, AIMessage):
        return {"role": "assistant", "content": msg.content}
    role = getattr(msg, "type", "user")
    if role == "human":
        role = "user"
    elif role == "ai":
        role = "assistant"
    return {"role": role, "content": msg.content}


def _extract_content(payload: dict[str, Any]) -> str:
    try:
        return payload["choices"][0]["message"].get("content") or ""
    except (KeyError, IndexError, TypeError) as exc:
        raise AppError(
            "LLM_INVALID_RESPONSE",
            502,
            f"Provider returned no message content: {exc}",
        ) from exc


class LLMService:
    """Process-wide facade — preserves the historical method names.

    Singleton kept only because legacy code does ``LLMService()`` and
    expects the same instance back. The router itself manages its own
    HTTP client lifecycle.
    """

    _instance: LLMService | None = None

    def __new__(cls) -> LLMService:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def _router(self) -> LLMRouter:
        return LLMRouter.get()

    # ── Legacy sync surface (system+user → JSON dict) ─────────────────

    def call_llm(self, system_prompt: str, user_prompt: str) -> dict:
        """Synchronous wrapper kept for the small number of non-async callers.

        The router itself is async; we run it on the running event loop
        when present, or open a transient one otherwise. Production
        callers are async — this is mostly used by tests and scripts.
        """
        import asyncio

        try:
            asyncio.get_running_loop()
        except RuntimeError:
            # No loop running — open a transient one for this call.
            return asyncio.run(self.acall_llm(system_prompt, user_prompt))
        # A loop is already running. Bail with a clear programming error
        # rather than spawning a nested loop and risking deadlocks.
        raise AppError(
            "LLM_SYNC_IN_ASYNC",
            500,
            "call_llm() invoked from within a running event loop; use acall_llm() instead.",
        )

    # ── Async surfaces ────────────────────────────────────────────────

    async def acall_llm(self, system_prompt: str, user_prompt: str) -> dict:
        """Send a system + user prompt and parse the response as JSON."""
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        payload = await self._router().chat_completion(messages=messages)
        raw = _extract_content(payload)
        try:
            return json.loads(_strip_markdown_fences(raw))
        except (json.JSONDecodeError, TypeError) as exc:
            raise AppError(
                "LLM_INVALID_RESPONSE",
                502,
                f"LLM returned invalid JSON: {exc}",
            ) from exc

    async def acall_llm_messages(self, messages: list[BaseMessage]) -> str:
        """Send a pre-built LangChain message list and return the raw assistant content.

        Used by the existing ReAct executor — it threads tool observations
        as ``HumanMessage`` and parses ``Thought / Action / Final Answer``
        from the assistant text. Phase 2 replaces this loop with native
        tool calls; until then this stays as a thin shim.
        """
        openai_messages = [_message_to_openai_dict(m) for m in messages]
        payload = await self._router().chat_completion(messages=openai_messages)
        return _extract_content(payload)
