"""Unit tests for `LLMService`.

We patch `_get_llm` to return a MagicMock/AsyncMock so we never touch OpenAI.
The singleton is reset between tests to avoid state leakage.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.services.llm_service import LLMService
from src.utils.errors import AppError


@pytest.fixture(autouse=True)
def _reset_llm_singleton():
    """Reset the LLMService singleton/state so tests don't leak patches."""
    LLMService._instance = None
    LLMService._llm = None
    yield
    LLMService._instance = None
    LLMService._llm = None


class TestStripMarkdownFences:
    def test_strips_json_fence(self):
        text = '```json\n{"a": 1}\n```'
        assert LLMService._strip_markdown_fences(text) == '{"a": 1}'

    def test_strips_plain_fence(self):
        text = '```\n{"b": 2}\n```'
        assert LLMService._strip_markdown_fences(text) == '{"b": 2}'

    def test_no_fence_returns_trimmed(self):
        assert LLMService._strip_markdown_fences('  {"x": 1}  ') == '{"x": 1}'


class TestCallLlm:
    def test_parses_valid_json(self):
        fake_response = MagicMock()
        fake_response.content = '{"ok": true}'
        fake_llm = MagicMock()
        fake_llm.invoke.return_value = fake_response

        service = LLMService()
        with patch.object(service, "_get_llm", return_value=fake_llm):
            result = service.call_llm("sys", "user")

        assert result == {"ok": True}
        fake_llm.invoke.assert_called_once()

    def test_strips_markdown_fences_before_parsing(self):
        fake_response = MagicMock()
        fake_response.content = '```json\n{"destinations": [1, 2]}\n```'
        fake_llm = MagicMock()
        fake_llm.invoke.return_value = fake_response

        service = LLMService()
        with patch.object(service, "_get_llm", return_value=fake_llm):
            result = service.call_llm("sys", "user")

        assert result == {"destinations": [1, 2]}

    def test_llm_invoke_failure_raises_llm_error(self):
        fake_llm = MagicMock()
        fake_llm.invoke.side_effect = RuntimeError("boom")

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            pytest.raises(AppError) as exc,
        ):
            service.call_llm("sys", "user")

        assert exc.value.code == "LLM_ERROR"
        assert exc.value.status_code == 502

    def test_invalid_json_raises_llm_invalid_response(self):
        fake_response = MagicMock()
        fake_response.content = "not json at all"
        fake_llm = MagicMock()
        fake_llm.invoke.return_value = fake_response

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            pytest.raises(AppError) as exc,
        ):
            service.call_llm("sys", "user")

        assert exc.value.code == "LLM_INVALID_RESPONSE"


class TestACallLlm:
    @pytest.mark.asyncio
    async def test_async_happy_path(self):
        fake_response = MagicMock()
        fake_response.content = '{"items": []}'
        fake_llm = MagicMock()
        fake_llm.ainvoke = AsyncMock(return_value=fake_response)

        service = LLMService()
        with patch.object(service, "_get_llm", return_value=fake_llm):
            result = await service.acall_llm("sys", "user")

        assert result == {"items": []}
        fake_llm.ainvoke.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_async_failure_raises_llm_error(self):
        fake_llm = MagicMock()
        fake_llm.ainvoke = AsyncMock(side_effect=RuntimeError("network"))

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            pytest.raises(AppError) as exc,
        ):
            await service.acall_llm("sys", "user")

        assert exc.value.code == "LLM_ERROR"

    @pytest.mark.asyncio
    async def test_async_invalid_json(self):
        fake_response = MagicMock()
        fake_response.content = "```\nnope\n```"
        fake_llm = MagicMock()
        fake_llm.ainvoke = AsyncMock(return_value=fake_response)

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            pytest.raises(AppError) as exc,
        ):
            await service.acall_llm("sys", "user")

        assert exc.value.code == "LLM_INVALID_RESPONSE"

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


class TestACallLlmMessages:
    @pytest.mark.asyncio
    async def test_returns_raw_content(self):
        fake_response = MagicMock()
        fake_response.content = "raw text"
        fake_llm = MagicMock()
        fake_llm.ainvoke = AsyncMock(return_value=fake_response)

        service = LLMService()
        with patch.object(service, "_get_llm", return_value=fake_llm):
            result = await service.acall_llm_messages([MagicMock()])

        assert result == "raw text"

    @pytest.mark.asyncio
    async def test_failure_raises_llm_error(self):
        fake_llm = MagicMock()
        fake_llm.ainvoke = AsyncMock(side_effect=RuntimeError("timeout"))

        service = LLMService()
        with (
            patch.object(service, "_get_llm", return_value=fake_llm),
            pytest.raises(AppError) as exc,
        ):
            await service.acall_llm_messages([MagicMock()])

        assert exc.value.code == "LLM_ERROR"

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


class TestSingleton:
    def test_same_instance_returned(self):
        a = LLMService()
        b = LLMService()
        assert a is b
