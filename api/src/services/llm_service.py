"""Service wrapper pour appels LLM (OpenAI-compatible via LangChain)."""

import asyncio
import json
import re

from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from src.config.env import settings
from src.utils.errors import AppError
from src.utils.logger import logger


class LLMService:
    """Singleton lazy pour appels LLM."""

    _instance: "LLMService | None" = None
    _llm: ChatOpenAI | None = None

    def __new__(cls) -> "LLMService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def _get_llm(self) -> ChatOpenAI:
        if self._llm is None:
            # SMP-324 — without ``timeout`` ``ChatOpenAI`` keeps the
            # underlying httpx client on its default (no read timeout),
            # which lets a hung upstream proxy block ``ainvoke`` forever.
            # The wizard's destinations_only path used to emit two
            # ``progress`` events then go silent because of this. The
            # ReAct executor already wraps every call in ``wait_for``;
            # this constructor-level fallback covers any caller that
            # forgets — defense in depth.
            self._llm = ChatOpenAI(
                model=settings.LLM_MODEL,
                base_url=settings.LLM_API_BASE,
                api_key=settings.LLM_API_KEY,
                temperature=0.7,
                timeout=float(settings.LLM_CALL_TIMEOUT_SECONDS),
                max_retries=2,
            )
        return self._llm

    @staticmethod
    def _strip_markdown_fences(text: str) -> str:
        """Retire les code fences markdown avant parsing JSON."""
        text = text.strip()
        text = re.sub(r"^```(?:json)?\s*\n?", "", text)
        text = re.sub(r"\n?```\s*$", "", text)
        return text.strip()

    def call_llm(self, system_prompt: str, user_prompt: str) -> dict:
        """Appelle le LLM et retourne le JSON parsé (synchrone)."""
        try:
            llm = self._get_llm()
            response = llm.invoke(
                [
                    SystemMessage(content=system_prompt),
                    HumanMessage(content=user_prompt),
                ]
            )
            raw = response.content
        except Exception as e:
            raise AppError("LLM_ERROR", 502, f"LLM call failed: {e}") from e

        try:
            cleaned = self._strip_markdown_fences(raw)
            return json.loads(cleaned)
        except (json.JSONDecodeError, TypeError) as e:
            raise AppError(
                "LLM_INVALID_RESPONSE",
                502,
                f"LLM returned invalid JSON: {e}",
            ) from e

    async def acall_llm(self, system_prompt: str, user_prompt: str) -> dict:
        """Appelle le LLM de manière asynchrone et retourne le JSON parsé.

        Wrapped in ``asyncio.wait_for`` so a hung upstream proxy raises
        ``LLM_TIMEOUT`` after ``LLM_CALL_TIMEOUT_SECONDS`` instead of
        keeping the SSE connection open forever — the bug behind the
        "destinations stream hangs without error" report.
        """
        try:
            llm = self._get_llm()
            response = await asyncio.wait_for(
                llm.ainvoke(
                    [
                        SystemMessage(content=system_prompt),
                        HumanMessage(content=user_prompt),
                    ]
                ),
                timeout=settings.LLM_CALL_TIMEOUT_SECONDS,
            )
            raw = response.content
        except TimeoutError as e:
            logger.warn(
                "LLM call timed out",
                {"timeout_seconds": settings.LLM_CALL_TIMEOUT_SECONDS},
            )
            raise AppError(
                "LLM_TIMEOUT",
                504,
                f"LLM call timed out after {settings.LLM_CALL_TIMEOUT_SECONDS}s",
            ) from e
        except Exception as e:
            raise AppError("LLM_ERROR", 502, f"LLM call failed: {e}") from e

        try:
            cleaned = self._strip_markdown_fences(raw)
            return json.loads(cleaned)
        except (json.JSONDecodeError, TypeError) as e:
            raise AppError(
                "LLM_INVALID_RESPONSE",
                502,
                f"LLM returned invalid JSON: {e}",
            ) from e

    async def acall_llm_messages(self, messages: list[BaseMessage]) -> str:
        """Appelle le LLM avec une liste de messages et retourne le contenu brut.

        Utilisé par le ReAct executor pour la boucle conversationnelle.
        Same timeout discipline as ``acall_llm`` — silent hangs are
        the most insidious failure mode of the SSE pipeline.
        """
        try:
            llm = self._get_llm()
            response = await asyncio.wait_for(
                llm.ainvoke(messages),
                timeout=settings.LLM_CALL_TIMEOUT_SECONDS,
            )
            return response.content
        except TimeoutError as e:
            logger.warn(
                "LLM call timed out",
                {"timeout_seconds": settings.LLM_CALL_TIMEOUT_SECONDS},
            )
            raise AppError(
                "LLM_TIMEOUT",
                504,
                f"LLM call timed out after {settings.LLM_CALL_TIMEOUT_SECONDS}s",
            ) from e
        except Exception as e:
            raise AppError("LLM_ERROR", 502, f"LLM call failed: {e}") from e
