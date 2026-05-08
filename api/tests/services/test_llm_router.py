"""Unit tests for :class:`LLMRouter`.

The router is exercised against an in-process ``httpx.MockTransport`` so
the tests cover the real httpx + tenacity stack without ever touching
the network. The real OVH endpoint behaviour is verified separately by
the Phase 0 PoC script (``api/docs/refactor/poc_ovh.py`` — out of repo).
"""

from __future__ import annotations

import asyncio
import json
from typing import Any

import httpx
import pytest

from src.services.llm_router import (
    LLMRouter,
    _PermanentLLMError,
    _TransientLLMError,
)

# ── Fixtures ──────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def _reset_router() -> None:
    """Each test starts with a fresh singleton."""
    LLMRouter.reset_for_tests()
    yield
    LLMRouter.reset_for_tests()


def _success_response(model: str, content: str = "ok") -> dict[str, Any]:
    return {
        "id": f"chat-{model}",
        "model": model,
        "choices": [
            {
                "message": {"role": "assistant", "content": content},
                "finish_reason": "stop",
                "index": 0,
            }
        ],
        "usage": {"prompt_tokens": 7, "completion_tokens": 3, "total_tokens": 10},
    }


def _install_transport(monkeypatch, handler) -> list[dict[str, Any]]:
    """Replace the router's HTTP client with an httpx.MockTransport.

    Returns a recorder list that grows with one entry per dispatched
    request so tests can assert on what was sent.
    """
    seen: list[dict[str, Any]] = []

    def _wrapped(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content) if request.content else {}
        seen.append({"url": str(request.url), "body": body})
        return handler(request, body)

    transport = httpx.MockTransport(_wrapped)
    client = httpx.AsyncClient(
        base_url="https://mock.test/v1",
        transport=transport,
        headers={"Authorization": "Bearer test", "Content-Type": "application/json"},
    )

    router = LLMRouter.get()
    router._client = client
    return seen


# ── chat_completion ───────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_chat_completion_primary_succeeds(monkeypatch):
    """Primary model answers 200 — router returns first response, no fallback used."""

    def _h(req: httpx.Request, body: dict[str, Any]) -> httpx.Response:
        return httpx.Response(200, json=_success_response(body["model"], "pong"))

    seen = _install_transport(monkeypatch, _h)
    router = LLMRouter.get()

    payload = await router.chat_completion(
        messages=[{"role": "user", "content": "ping"}],
        models=["primary", "fallback-1"],
        temperature=0.0,
    )

    assert payload["choices"][0]["message"]["content"] == "pong"
    assert payload["_router"]["model_used"] == "primary"
    assert [a["model"] for a in payload["_router"]["attempts"]] == ["primary"]
    assert len(seen) == 1
    assert seen[0]["body"]["model"] == "primary"
    assert seen[0]["body"]["temperature"] == 0.0


@pytest.mark.asyncio
async def test_chat_completion_falls_back_on_permanent_error():
    """A 4xx other than 429 skips straight to the next model — no retries on the failing one."""

    def _h(req: httpx.Request, body: dict[str, Any]) -> httpx.Response:
        if body["model"] == "primary":
            return httpx.Response(
                400,
                json={"message": "feature 'tool calls' is not currently supported"},
            )
        return httpx.Response(200, json=_success_response(body["model"]))

    seen = _install_transport(None, _h)
    router = LLMRouter.get()

    payload = await router.chat_completion(
        messages=[{"role": "user", "content": "x"}],
        models=["primary", "fallback-1"],
    )

    assert payload["_router"]["model_used"] == "fallback-1"
    # Exactly one call to primary (no retries on permanent errors), then one to fallback-1.
    primaries = [s for s in seen if s["body"]["model"] == "primary"]
    fallbacks = [s for s in seen if s["body"]["model"] == "fallback-1"]
    assert len(primaries) == 1
    assert len(fallbacks) == 1


@pytest.mark.asyncio
async def test_chat_completion_retries_transient_then_falls_back(monkeypatch):
    """5xx is retried per-model, then falls back to the next when retries are exhausted."""
    # Force aggressive retry config so the test stays fast.
    monkeypatch.setattr(
        "src.services.llm_router.settings.LLM_RETRY_MAX_ATTEMPTS",
        2,
        raising=False,
    )
    monkeypatch.setattr(
        "src.services.llm_router.settings.LLM_RETRY_BACKOFF_BASE_S",
        0.01,
        raising=False,
    )
    monkeypatch.setattr(
        "src.services.llm_router.settings.LLM_RETRY_BACKOFF_MAX_S",
        0.02,
        raising=False,
    )

    def _h(req: httpx.Request, body: dict[str, Any]) -> httpx.Response:
        if body["model"] == "primary":
            return httpx.Response(500, json={"message": "boom"})
        return httpx.Response(200, json=_success_response(body["model"]))

    seen = _install_transport(monkeypatch, _h)
    router = LLMRouter.get()

    payload = await router.chat_completion(
        messages=[{"role": "user", "content": "x"}],
        models=["primary", "fallback-1"],
    )

    assert payload["_router"]["model_used"] == "fallback-1"
    primaries = [s for s in seen if s["body"]["model"] == "primary"]
    # ``stop_after_attempt(2)`` ⇒ at most two attempts on primary.
    assert len(primaries) == 2
    attempts = payload["_router"]["attempts"]
    assert attempts[0]["model"] == "primary"
    assert attempts[0]["outcome"] == "exhausted_retries"
    assert attempts[1]["model"] == "fallback-1"
    assert attempts[1]["outcome"] == "ok"


@pytest.mark.asyncio
async def test_chat_completion_all_models_fail_raises_app_error(monkeypatch):
    """When every model in the chain fails, the router raises a structured AppError."""
    from src.utils.errors import AppError

    monkeypatch.setattr("src.services.llm_router.settings.LLM_RETRY_MAX_ATTEMPTS", 1, raising=False)

    def _h(req: httpx.Request, body: dict[str, Any]) -> httpx.Response:
        return httpx.Response(503, json={"message": "down"})

    _install_transport(monkeypatch, _h)
    router = LLMRouter.get()

    with pytest.raises(AppError) as exc:
        await router.chat_completion(
            messages=[{"role": "user", "content": "x"}],
            models=["primary", "fallback-1"],
        )
    assert exc.value.code == "LLM_UNAVAILABLE"
    assert exc.value.status_code == 502


@pytest.mark.asyncio
async def test_chat_completion_propagates_tools_and_response_format():
    """tools / tool_choice / response_format land verbatim in the request body."""
    seen = _install_transport(
        None,
        lambda req, body: httpx.Response(200, json=_success_response(body["model"])),
    )
    router = LLMRouter.get()
    tool = {
        "type": "function",
        "function": {"name": "noop", "description": "n/a", "parameters": {}},
    }
    fmt = {"type": "json_schema", "json_schema": {"name": "x", "schema": {}, "strict": True}}

    await router.chat_completion(
        messages=[{"role": "user", "content": "x"}],
        models=["primary"],
        tools=[tool],
        tool_choice="auto",
        response_format=fmt,
    )

    body = seen[0]["body"]
    assert body["tools"] == [tool]
    assert body["tool_choice"] == "auto"
    assert body["response_format"] == fmt


@pytest.mark.asyncio
async def test_chat_completion_explicit_model_skips_chain():
    """Passing ``model=`` overrides the fallback chain entirely."""
    seen = _install_transport(
        None,
        lambda req, body: httpx.Response(200, json=_success_response(body["model"])),
    )
    router = LLMRouter.get()
    await router.chat_completion(
        messages=[{"role": "user", "content": "x"}],
        model="explicit-only",
    )
    assert [s["body"]["model"] for s in seen] == ["explicit-only"]


# ── stream_chat_completion ────────────────────────────────────────────


@pytest.mark.asyncio
async def test_stream_chat_completion_yields_chunks():
    """Streaming yields parsed JSON chunks until the [DONE] sentinel."""
    chunks = [
        {"choices": [{"delta": {"role": "assistant"}}]},
        {"choices": [{"delta": {"content": "Hel"}}]},
        {"choices": [{"delta": {"content": "lo"}}]},
        {"choices": [{"delta": {}, "finish_reason": "stop"}]},
    ]
    body = "\n".join(f"data: {json.dumps(c)}" for c in chunks) + "\n\ndata: [DONE]\n\n"

    def _h(req: httpx.Request, _body: dict[str, Any]) -> httpx.Response:
        return httpx.Response(
            200,
            headers={"content-type": "text/event-stream"},
            content=body.encode("utf-8"),
        )

    _install_transport(None, _h)
    router = LLMRouter.get()
    received: list[dict[str, Any]] = []
    async for chunk in router.stream_chat_completion(
        messages=[{"role": "user", "content": "x"}],
        models=["primary"],
    ):
        received.append(chunk)

    # First yield is the router meta marker; remaining are the parsed deltas.
    assert received[0] == {"_router": {"model_used": "primary"}}
    assert [c["choices"][0]["delta"].get("content") for c in received[1:]] == [
        None,
        "Hel",
        "lo",
        None,
    ]


# ── embed ─────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_embed_returns_vectors_in_order():
    """The embeddings endpoint is hit on /embeddings with the right shape."""

    def _h(req: httpx.Request, body: dict[str, Any]) -> httpx.Response:
        assert "/embeddings" in str(req.url)
        return httpx.Response(
            200,
            json={
                "data": [{"embedding": [0.1, 0.2], "index": i} for i in range(len(body["input"]))]
            },
        )

    _install_transport(None, _h)
    router = LLMRouter.get()
    vectors = await router.embed(inputs=["a", "b", "c"], model="bge-m3")
    assert len(vectors) == 3
    assert vectors[0] == [0.1, 0.2]


# ── concurrency cap ───────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_semaphore_caps_concurrent_calls(monkeypatch):
    """Only LLM_MAX_CONCURRENCY calls run in parallel — extras queue up."""
    monkeypatch.setattr("src.services.llm_router.settings.LLM_MAX_CONCURRENCY", 2, raising=False)

    in_flight = 0
    peak = 0
    gate = asyncio.Event()

    async def _h_async(request: httpx.Request) -> httpx.Response:
        nonlocal in_flight, peak
        body = json.loads(request.content)
        in_flight += 1
        peak = max(peak, in_flight)
        # Hold the call open until every queued request has had a chance to be admitted.
        await gate.wait()
        in_flight -= 1
        return httpx.Response(200, json=_success_response(body["model"]))

    transport = httpx.MockTransport(_h_async)
    client = httpx.AsyncClient(
        base_url="https://mock.test/v1",
        transport=transport,
        headers={"Authorization": "Bearer test"},
    )
    router = LLMRouter.get()
    router._client = client

    tasks = [
        asyncio.create_task(
            router.chat_completion(
                messages=[{"role": "user", "content": str(i)}],
                models=["primary"],
            )
        )
        for i in range(5)
    ]
    # Yield enough times for tasks to either acquire the semaphore or queue on it.
    for _ in range(20):
        await asyncio.sleep(0)
    gate.set()
    await asyncio.gather(*tasks)

    assert peak == 2, f"semaphore was breached, observed peak={peak}"


# ── error taxonomy ────────────────────────────────────────────────────


def test_transient_and_permanent_errors_carry_status():
    """Error classes round-trip the HTTP status for downstream telemetry."""
    t = _TransientLLMError("timeout", status=503)
    p = _PermanentLLMError("bad request", status=400)
    assert t.status == 503
    assert p.status == 400
    assert "timeout" in str(t)
    assert "bad request" in str(p)
