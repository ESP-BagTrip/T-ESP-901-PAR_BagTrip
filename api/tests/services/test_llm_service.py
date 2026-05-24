"""Tests for :class:`LLMService` — the legacy facade over ``LLMRouter``.

Verifies the contract historical agent code relies on:

- ``acall_llm`` parses JSON content (stripping markdown fences).
- ``acall_llm_messages`` translates LangChain messages → OpenAI dicts and
  returns the raw assistant content untouched.
- Markdown fence stripping is robust to whitespace/casing variants.
- Non-JSON content surfaces an :class:`AppError` ``LLM_INVALID_RESPONSE``.
"""

from __future__ import annotations

import json
from typing import Any
from unittest.mock import AsyncMock

import pytest
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from src.services.llm_router import LLMRouter
from src.services.llm_service import LLMService, _strip_markdown_fences
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _reset_router() -> None:
    LLMRouter.reset_for_tests()
    yield
    LLMRouter.reset_for_tests()


def _stub_chat_completion(content: str) -> AsyncMock:
    return AsyncMock(
        return_value={
            "choices": [{"message": {"role": "assistant", "content": content}}],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1},
        }
    )


@pytest.mark.asyncio
async def test_acall_llm_parses_clean_json(monkeypatch):
    stub = _stub_chat_completion('{"city": "Lisbon", "iata": "LIS"}')
    monkeypatch.setattr(LLMRouter, "chat_completion", stub)

    result = await LLMService().acall_llm("system", "user")
    assert result == {"city": "Lisbon", "iata": "LIS"}
    stub.assert_awaited_once()
    payload_kwargs = stub.await_args.kwargs
    assert payload_kwargs["messages"][0]["role"] == "system"
    assert payload_kwargs["messages"][1]["role"] == "user"


@pytest.mark.asyncio
async def test_acall_llm_strips_markdown_fences(monkeypatch):
    raw = '```json\n{"ok": true}\n```'
    monkeypatch.setattr(LLMRouter, "chat_completion", _stub_chat_completion(raw))

    result = await LLMService().acall_llm("s", "u")
    assert result == {"ok": True}

    @pytest.mark.asyncio
    async def test_hung_call_raises_llm_timeout(self):
        """SMP-324 — a stuck upstream proxy used to keep the SSE
        connection open silently. Wrap the underlying ``ainvoke`` in
        ``asyncio.wait_for`` so the caller always observes a bounded
        failure path."""
        import asyncio

        async def _hang(*_args, **_kwargs):
            await asyncio.sleep(60)  # longer than the patched timeout

        fake_llm = MagicMock()
        fake_llm.ainvoke = _hang

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            patch("src.services.llm_service.settings.LLM_CALL_TIMEOUT_SECONDS", 0.05),
            pytest.raises(AppError) as exc,
        ):
            await service.acall_llm("sys", "user")

        assert exc.value.code == "LLM_TIMEOUT"
        assert exc.value.status_code == 504


@pytest.mark.asyncio
async def test_acall_llm_invalid_json_raises_app_error(monkeypatch):
    monkeypatch.setattr(LLMRouter, "chat_completion", _stub_chat_completion("not json"))
    with pytest.raises(AppError) as exc:
        await LLMService().acall_llm("s", "u")
    assert exc.value.code == "LLM_INVALID_RESPONSE"
    assert exc.value.status_code == 502

    @pytest.mark.asyncio
    async def test_hung_call_raises_llm_timeout(self):
        """Same hang protection as ``acall_llm`` — covers the ReAct
        executor path which uses ``acall_llm_messages``."""
        import asyncio

        async def _hang(*_args, **_kwargs):
            await asyncio.sleep(60)

        fake_llm = MagicMock()
        fake_llm.ainvoke = _hang

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            patch("src.services.llm_service.settings.LLM_CALL_TIMEOUT_SECONDS", 0.05),
            pytest.raises(AppError) as exc,
        ):
            await service.acall_llm_messages([MagicMock()])

        assert exc.value.code == "LLM_TIMEOUT"


@pytest.mark.asyncio
async def test_acall_llm_messages_returns_raw_string(monkeypatch):
    """Used by the ReAct executor — must NOT JSON-parse the response."""
    raw = "Thought: I should call get_weather\nAction: get_weather"
    monkeypatch.setattr(LLMRouter, "chat_completion", _stub_chat_completion(raw))

    msgs = [
        SystemMessage(content="you are an agent"),
        HumanMessage(content="what's the weather"),
        AIMessage(content="prior assistant turn"),
    ]
    result = await LLMService().acall_llm_messages(msgs)
    assert result == raw


@pytest.mark.asyncio
async def test_acall_llm_messages_maps_roles(monkeypatch):
    """SystemMessage/HumanMessage/AIMessage map to system/user/assistant in the payload."""
    captured: dict[str, Any] = {}

    async def _capture(self, **kwargs):
        captured.update(kwargs)
        return {"choices": [{"message": {"content": "ok"}}]}

    monkeypatch.setattr(LLMRouter, "chat_completion", _capture)

    msgs = [
        SystemMessage(content="sys"),
        HumanMessage(content="user"),
        AIMessage(content="assistant"),
    ]
    await LLMService().acall_llm_messages(msgs)
    roles = [m["role"] for m in captured["messages"]]
    assert roles == ["system", "user", "assistant"]


@pytest.mark.parametrize(
    "raw,expected",
    [
        ('{"a":1}', '{"a":1}'),
        ('```json\n{"a":1}\n```', '{"a":1}'),
        ('```\n{"a":1}\n```', '{"a":1}'),
        ("   ```json\n{}\n```   ", "{}"),
    ],
)
def test_strip_markdown_fences(raw: str, expected: str) -> None:
    assert _strip_markdown_fences(raw) == expected


def test_singleton_returns_same_instance():
    a = LLMService()
    b = LLMService()
    assert a is b


@pytest.mark.asyncio
async def test_call_llm_sync_in_async_loop_raises(monkeypatch):
    """Calling the sync surface from inside a running loop is a programming error."""
    monkeypatch.setattr(LLMRouter, "chat_completion", _stub_chat_completion('{"x":1}'))
    with pytest.raises(AppError) as exc:
        LLMService().call_llm("s", "u")
    assert exc.value.code == "LLM_SYNC_IN_ASYNC"


def test_call_llm_outside_loop_runs(monkeypatch):
    """Without a running loop, ``call_llm`` opens a transient one and returns the dict."""
    monkeypatch.setattr(LLMRouter, "chat_completion", _stub_chat_completion('{"y":2}'))
    result = LLMService().call_llm("s", "u")
    assert result == {"y": 2}


def test_strip_markdown_then_parse_smoke():
    raw = "```json\n" + json.dumps({"k": [1, 2, 3]}) + "\n```"
    assert json.loads(_strip_markdown_fences(raw)) == {"k": [1, 2, 3]}
