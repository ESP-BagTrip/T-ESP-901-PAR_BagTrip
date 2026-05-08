"""In-process LLM router targeting an OpenAI-compatible endpoint (OVHcloud AI Endpoints by default).

The router is the single ingress to the LLM provider for the whole API
process. It centralises four concerns the per-call sites used to do badly
or not at all:

- **Model fallback**: every call walks a chain (primary → fallbacks). A
  model that raises a non-retryable error (bad request, unsupported
  feature, schema rejection) is skipped to the next candidate.
- **Transient retry**: 5xx / 408 / 429 / network errors are retried with
  exponential backoff + jitter, *bounded by attempt count and per-model
  budget*. Tenacity gates the loop.
- **Concurrency**: a shared ``asyncio.Semaphore`` caps in-flight calls
  per process so the API stays under OVH's RPM cap (configurable).
- **Tracing**: every call logs model, attempt, latency, prompt/completion
  tokens and finish_reason via the structured logger so an audit can
  reconstruct what happened without re-running the agent.

The public surface intentionally mirrors the OpenAI Chat Completions
schema: callers pass ``messages`` (and optionally ``tools``,
``tool_choice``, ``response_format``, ``temperature``, ``max_tokens``,
``stream``) and get back the raw provider response.
"""

from __future__ import annotations

import asyncio
import json
import os
import time
from collections.abc import AsyncIterator
from typing import Any

import httpx
from tenacity import (
    AsyncRetrying,
    RetryError,
    before_sleep_log,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential_jitter,
)

from src.config.env import settings
from src.utils.errors import AppError
from src.utils.logger import logger

# ── Retryable error taxonomy ───────────────────────────────────────────


class _TransientLLMError(Exception):
    """Wrapper for HTTP/network errors that warrant a same-model retry."""

    def __init__(self, message: str, *, status: int | None = None) -> None:
        super().__init__(message)
        self.status = status


class _PermanentLLMError(Exception):
    """Provider rejected the request in a way that retrying won't help.

    Examples: 400 with ``feature 'tool calls' is not currently supported``,
    401/403 auth, 422 schema rejection. The router skips to the next model
    in the fallback chain instead of retrying.
    """

    def __init__(self, message: str, *, status: int | None = None) -> None:
        super().__init__(message)
        self.status = status


# ── Internal HTTP client lifecycle ─────────────────────────────────────


class LLMRouter:
    """Singleton dispatcher around the OVH OpenAI-compatible endpoint.

    Construction is lazy so unit tests can monkeypatch ``settings`` before
    the first call. The shared semaphore is bound to the process event
    loop the first time it is requested; tests that spin up a fresh loop
    must call :meth:`reset_for_tests` to drop the cached semaphore.
    """

    _instance: LLMRouter | None = None

    def __init__(self) -> None:
        self._client: httpx.AsyncClient | None = None
        self._semaphore: asyncio.Semaphore | None = None
        self._semaphore_loop: asyncio.AbstractEventLoop | None = None

    @classmethod
    def get(cls) -> LLMRouter:
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    @classmethod
    def reset_for_tests(cls) -> None:
        """Drop cached client + semaphore so each test runs against fresh state."""
        if cls._instance is not None and cls._instance._client is not None:
            # ``aclose`` is async; tests are expected to await before resetting.
            cls._instance._client = None
        cls._instance = None

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    # ── Configuration ─────────────────────────────────────────────────

    def _model_chain(self, override: list[str] | None) -> list[str]:
        if override:
            return [m.strip() for m in override if m and m.strip()]
        primary = settings.LLM_MODEL_PRIMARY or settings.LLM_MODEL
        fallbacks_raw = settings.LLM_MODEL_FALLBACKS or ""
        fallbacks = [m.strip() for m in fallbacks_raw.split(",") if m.strip()]
        chain = [primary, *fallbacks]
        # De-duplicate while preserving order.
        seen: set[str] = set()
        result: list[str] = []
        for m in chain:
            if m and m not in seen:
                seen.add(m)
                result.append(m)
        return result

    def _http_client(self) -> httpx.AsyncClient:
        if self._client is None:
            timeout = httpx.Timeout(
                connect=10.0,
                read=float(settings.LLM_CALL_TIMEOUT_SECONDS),
                write=10.0,
                pool=5.0,
            )
            self._client = httpx.AsyncClient(
                base_url=settings.LLM_API_BASE,
                timeout=timeout,
                headers={
                    "Authorization": f"Bearer {settings.LLM_API_KEY}",
                    "Content-Type": "application/json",
                },
            )
        return self._client

    def _get_semaphore(self) -> asyncio.Semaphore:
        loop = asyncio.get_running_loop()
        if self._semaphore is None or self._semaphore_loop is not loop:
            self._semaphore = asyncio.Semaphore(settings.LLM_MAX_CONCURRENCY)
            self._semaphore_loop = loop
        return self._semaphore

    # ── Public API ────────────────────────────────────────────────────

    async def chat_completion(
        self,
        *,
        messages: list[dict[str, Any]],
        model: str | None = None,
        tools: list[dict[str, Any]] | None = None,
        tool_choice: str | dict[str, Any] | None = None,
        response_format: dict[str, Any] | None = None,
        temperature: float = 0.7,
        max_tokens: int | None = None,
        models: list[str] | None = None,
    ) -> dict[str, Any]:
        """Issue a non-streaming chat completion against the model chain.

        Returns the raw provider response (an OpenAI-compatible JSON dict
        with ``choices[0].message`` etc.). Adds two non-standard fields
        for observability:

        - ``_router.model_used``: the model that actually answered.
        - ``_router.attempts``: ordered list of ``(model, status)`` pairs.
        """
        chain = [model] if model else self._model_chain(models)
        body_base = self._build_body(
            messages=messages,
            tools=tools,
            tool_choice=tool_choice,
            response_format=response_format,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        attempts: list[dict[str, Any]] = []
        for candidate in chain:
            try:
                response = await self._call_with_retry(candidate, body_base, attempts)
            except _PermanentLLMError as exc:
                attempts.append(
                    {"model": candidate, "status": exc.status, "outcome": "permanent_error"}
                )
                continue
            except RetryError as exc:
                last = exc.last_attempt.exception() if exc.last_attempt else None
                attempts.append(
                    {
                        "model": candidate,
                        "status": getattr(last, "status", None),
                        "outcome": "exhausted_retries",
                    }
                )
                continue
            response["_router"] = {"model_used": candidate, "attempts": attempts}
            return response

        # Every model in the chain failed. Surface a structured error.
        logger.error(
            "LLMRouter exhausted fallback chain",
            {"chain": chain, "attempts": attempts},
        )
        raise AppError(
            "LLM_UNAVAILABLE",
            502,
            f"All models in chain {chain} failed: {attempts[-1] if attempts else 'no_attempts'}",
        )

    async def stream_chat_completion(
        self,
        *,
        messages: list[dict[str, Any]],
        model: str | None = None,
        tools: list[dict[str, Any]] | None = None,
        tool_choice: str | dict[str, Any] | None = None,
        response_format: dict[str, Any] | None = None,
        temperature: float = 0.7,
        max_tokens: int | None = None,
        models: list[str] | None = None,
    ) -> AsyncIterator[dict[str, Any]]:
        """Stream chat completion chunks (Server-Sent Events).

        Yields parsed JSON deltas (``choices[0].delta.content`` for token
        deltas, ``choices[0].delta.tool_calls`` for tool argument deltas,
        ``finish_reason`` on the last chunk). The ``[DONE]`` sentinel
        terminates the stream.

        Streaming intentionally does NOT walk the fallback chain — once
        the first chunk has been forwarded to the caller, switching
        models would corrupt the user-facing stream. If the primary model
        rejects the request before the first byte (4xx), the router
        falls back; once a 200 response is in flight, errors propagate.
        """
        chain = [model] if model else self._model_chain(models)
        body_base = self._build_body(
            messages=messages,
            tools=tools,
            tool_choice=tool_choice,
            response_format=response_format,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=True,
        )
        last_error: Exception | None = None
        for candidate in chain:
            body = {**body_base, "model": candidate}
            client = self._http_client()
            sem = self._get_semaphore()
            await sem.acquire()
            try:
                t0 = time.monotonic()
                async with client.stream("POST", "/chat/completions", json=body) as resp:
                    if resp.status_code != 200:
                        text = await resp.aread()
                        msg = text.decode("utf-8", errors="replace")[:500]
                        if _is_retryable(resp.status_code):
                            last_error = _TransientLLMError(msg, status=resp.status_code)
                            logger.warn(
                                "LLMRouter stream transient failure, trying next model",
                                {"model": candidate, "status": resp.status_code},
                            )
                            continue
                        last_error = _PermanentLLMError(msg, status=resp.status_code)
                        logger.warn(
                            "LLMRouter stream permanent failure, trying next model",
                            {"model": candidate, "status": resp.status_code},
                        )
                        continue
                    logger.info(
                        "LLMRouter stream open",
                        {"model": candidate, "ttfb_s": round(time.monotonic() - t0, 3)},
                    )
                    yield {"_router": {"model_used": candidate}}
                    async for chunk in _iter_sse_chunks(resp):
                        yield chunk
                    return
            finally:
                sem.release()

        raise AppError(
            "LLM_UNAVAILABLE",
            502,
            f"Stream chain {chain} failed: {last_error}",
        )

    async def embed(
        self,
        *,
        inputs: list[str],
        model: str | None = None,
    ) -> list[list[float]]:
        """Compute embeddings via the same OpenAI-compatible /embeddings route.

        Returns a list of vectors, one per input, in input order.
        """
        body = {
            "model": model or settings.LLM_EMBEDDING_MODEL,
            "input": inputs,
        }
        sem = self._get_semaphore()
        async with sem:
            t0 = time.monotonic()
            client = self._http_client()
            resp = await client.post("/embeddings", json=body)
        latency = round(time.monotonic() - t0, 3)
        if resp.status_code != 200:
            text = resp.text[:500]
            logger.error(
                "LLMRouter embeddings failure",
                {"model": body["model"], "status": resp.status_code, "body": text},
            )
            raise AppError(
                "LLM_EMBEDDING_FAILED",
                502,
                f"Embeddings request failed ({resp.status_code}): {text}",
            )
        payload = resp.json()
        vectors = [row["embedding"] for row in payload.get("data", [])]
        logger.info(
            "LLMRouter embed",
            {
                "model": body["model"],
                "n_inputs": len(inputs),
                "n_outputs": len(vectors),
                "latency_s": latency,
            },
        )
        return vectors

    # ── Internals ─────────────────────────────────────────────────────

    @staticmethod
    def _build_body(
        *,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None,
        tool_choice: str | dict[str, Any] | None,
        response_format: dict[str, Any] | None,
        temperature: float,
        max_tokens: int | None,
        stream: bool = False,
    ) -> dict[str, Any]:
        body: dict[str, Any] = {
            "messages": messages,
            "temperature": temperature,
        }
        if max_tokens is not None:
            body["max_tokens"] = max_tokens
        if tools:
            body["tools"] = tools
            if tool_choice is not None:
                body["tool_choice"] = tool_choice
        if response_format is not None:
            body["response_format"] = response_format
        if stream:
            body["stream"] = True
        return body

    async def _call_with_retry(
        self,
        model: str,
        body_base: dict[str, Any],
        attempts: list[dict[str, Any]],
    ) -> dict[str, Any]:
        body = {**body_base, "model": model}
        sem = self._get_semaphore()

        async def _do_call() -> dict[str, Any]:
            async with sem:
                t0 = time.monotonic()
                client = self._http_client()
                try:
                    resp = await client.post("/chat/completions", json=body)
                except (httpx.TimeoutException, httpx.NetworkError) as exc:
                    raise _TransientLLMError(f"network: {exc}") from exc
            latency = round(time.monotonic() - t0, 3)
            status = resp.status_code
            if status == 200:
                payload = resp.json()
                usage = payload.get("usage") or {}
                logger.info(
                    "LLMRouter call ok",
                    {
                        "model": model,
                        "latency_s": latency,
                        "prompt_tokens": usage.get("prompt_tokens"),
                        "completion_tokens": usage.get("completion_tokens"),
                        "finish_reason": (payload.get("choices", [{}])[0].get("finish_reason")),
                        "tool_calls": _count_tool_calls(payload),
                    },
                )
                attempts.append({"model": model, "status": 200, "outcome": "ok"})
                return payload
            text = resp.text[:500]
            if _is_retryable(status):
                logger.warn(
                    "LLMRouter transient error",
                    {"model": model, "status": status, "latency_s": latency},
                )
                raise _TransientLLMError(text, status=status)
            logger.warn(
                "LLMRouter permanent error",
                {"model": model, "status": status, "body": text, "latency_s": latency},
            )
            raise _PermanentLLMError(text, status=status)

        async for attempt in AsyncRetrying(
            stop=stop_after_attempt(settings.LLM_RETRY_MAX_ATTEMPTS),
            wait=wait_exponential_jitter(
                initial=settings.LLM_RETRY_BACKOFF_BASE_S,
                max=settings.LLM_RETRY_BACKOFF_MAX_S,
                jitter=0.5,
            ),
            retry=retry_if_exception_type(_TransientLLMError),
            before_sleep=before_sleep_log(logger._logger, 30)
            if hasattr(logger, "_logger")
            else None,  # noqa: SLF001
            reraise=False,
        ):
            with attempt:
                return await _do_call()
        # ``AsyncRetrying`` either returns or raises ``RetryError``.
        raise RuntimeError("unreachable")  # pragma: no cover


# ── Helpers ────────────────────────────────────────────────────────────


def _is_retryable(status: int) -> bool:
    return status in (408, 429) or 500 <= status < 600


def _count_tool_calls(payload: dict[str, Any]) -> int:
    try:
        return len(payload["choices"][0]["message"].get("tool_calls") or [])
    except (KeyError, IndexError, TypeError):
        return 0


async def _iter_sse_chunks(resp: httpx.Response) -> AsyncIterator[dict[str, Any]]:
    """Parse an OpenAI-compatible SSE stream into JSON chunks.

    The stream format is ``data: <json>\\n\\n`` per event, terminated by
    ``data: [DONE]``. Lines that don't start with ``data:`` (heartbeats,
    comments) are ignored.
    """
    async for line in resp.aiter_lines():
        if not line:
            continue
        if not line.startswith("data:"):
            continue
        payload = line[len("data:") :].strip()
        if payload == "[DONE]":
            return
        try:
            yield json.loads(payload)
        except json.JSONDecodeError:
            logger.warn("LLMRouter dropped malformed SSE chunk", {"raw": payload[:200]})
            continue


# Re-exported for tests + callers that need to introspect the chain
__all__ = [
    "LLMRouter",
    "_PermanentLLMError",
    "_TransientLLMError",
]


# Allow importing the router via ``llm_router.router`` for convenience.
router: LLMRouter = LLMRouter.get()


# Defensive: in long-lived processes, close the client on interpreter
# shutdown so we don't leak the underlying TCP pool. ``atexit`` hooks
# can't await; we register a sync wrapper that schedules ``aclose``
# only if a loop is running, otherwise no-ops.
def _shutdown() -> None:  # pragma: no cover - shutdown best-effort
    inst = LLMRouter._instance
    if inst is None or inst._client is None:
        return
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            loop.create_task(inst.aclose())
        else:
            loop.run_until_complete(inst.aclose())
    except RuntimeError:
        # No event loop available — drop the reference; ``httpx`` will
        # finalise the underlying socket pool when the object is GC'd.
        inst._client = None


# Skip atexit registration in pytest to keep test isolation clean.
if not os.environ.get("PYTEST_CURRENT_TEST"):
    import atexit

    atexit.register(_shutdown)
