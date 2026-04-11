"""Unit tests for the JSON repair loop in `react_executor`.

Covers:
- `_parse_final_answer` returns dict on valid JSON, None on invalid
- `_build_repair_prompt` includes both the raw text and the error
- `_repair_json_once` returns the parsed dict when the second call succeeds
- `_repair_json_once` returns None + logs when the second call is also broken
- `_repair_json_once` swallows LLM call exceptions (best effort)
- `react_execute` wires the repair loop into the happy path
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.agent.react_executor import (
    _build_repair_prompt,
    _parse_final_answer,
    _repair_json_once,
    react_execute,
)


class TestParseFinalAnswer:
    def test_valid_json(self):
        assert _parse_final_answer('{"a": 1}') == {"a": 1}

    def test_invalid_json_returns_none(self):
        assert _parse_final_answer("{not json}") is None

    def test_empty_returns_none(self):
        assert _parse_final_answer("") is None

    def test_non_object_json(self):
        # Top-level array is valid JSON but the type hint is `dict | None` — the
        # helper returns whatever `json.loads` produces. Callers downstream
        # assume dicts; that's enforced elsewhere.
        assert _parse_final_answer("[1, 2]") == [1, 2]


class TestBuildRepairPrompt:
    def test_contains_raw_and_error(self):
        prompt = _build_repair_prompt('{"a: 1', "Expecting value")
        assert '{"a: 1' in prompt
        assert "Expecting value" in prompt
        assert "ONLY" in prompt  # the instruction emphasis


class TestRepairJsonOnce:
    @pytest.mark.asyncio
    async def test_successful_repair_returns_dict(self):
        llm = MagicMock()
        llm.acall_llm_messages = AsyncMock(return_value='{"fixed": true}')
        result = await _repair_json_once(llm, '{"broken', "Expecting , delim")
        assert result == {"fixed": True}
        llm.acall_llm_messages.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_repair_strips_markdown_fences(self):
        """The LLM sometimes re-wraps the output in ```json … ``` — strip it."""
        llm = MagicMock()
        llm.acall_llm_messages = AsyncMock(return_value='```json\n{"ok": 1}\n```')
        result = await _repair_json_once(llm, "{broken", "error")
        assert result == {"ok": 1}

    @pytest.mark.asyncio
    async def test_repair_second_failure_returns_none(self):
        llm = MagicMock()
        llm.acall_llm_messages = AsyncMock(return_value="still broken")
        result = await _repair_json_once(llm, "{broken", "error")
        assert result is None

    @pytest.mark.asyncio
    async def test_repair_llm_timeout_returns_none(self):
        llm = MagicMock()
        llm.acall_llm_messages = AsyncMock(side_effect=TimeoutError("slow"))
        result = await _repair_json_once(llm, "{broken", "error")
        assert result is None

    @pytest.mark.asyncio
    async def test_repair_llm_exception_returns_none(self):
        llm = MagicMock()
        llm.acall_llm_messages = AsyncMock(side_effect=RuntimeError("boom"))
        result = await _repair_json_once(llm, "{broken", "error")
        assert result is None


class TestReactExecuteRepairIntegration:
    @pytest.mark.asyncio
    async def test_react_execute_uses_repair_on_broken_final_answer(self):
        """A malformed Final Answer on iteration 1 triggers a repair re-prompt."""
        # First call: returns a Final Answer with broken JSON
        # Repair call: returns a valid JSON fix
        llm_responses = iter(
            [
                'Thought: done\nFinal Answer: {"destinations": [broken]',
                '{"destinations": ["Paris"]}',
            ]
        )

        async def _fake_call(_messages):
            return next(llm_responses)

        fake_llm = MagicMock()
        fake_llm.acall_llm_messages = AsyncMock(side_effect=_fake_call)

        with patch("src.agent.react_executor.LLMService", return_value=fake_llm):
            result = await react_execute(
                agent_instruction="Suggest trips.",
                user_prompt="I like beaches.",
                tool_names=[],
                tool_registry={},
            )

        assert result == {"destinations": ["Paris"]}
        # Two calls total: original + one repair
        assert fake_llm.acall_llm_messages.await_count == 2

    @pytest.mark.asyncio
    async def test_react_execute_degrades_when_repair_also_fails(self):
        """If both the original and the repair are broken, return repair_failed."""
        llm_responses = iter(
            [
                'Thought: done\nFinal Answer: {"broken',
                "still broken",
            ]
        )

        async def _fake_call(_messages):
            return next(llm_responses)

        fake_llm = MagicMock()
        fake_llm.acall_llm_messages = AsyncMock(side_effect=_fake_call)

        with patch("src.agent.react_executor.LLMService", return_value=fake_llm):
            result = await react_execute(
                agent_instruction="x",
                user_prompt="y",
                tool_names=[],
                tool_registry={},
            )

        assert result.get("repair_failed") is True
        assert result.get("raw_answer") is not None

    @pytest.mark.asyncio
    async def test_react_execute_skips_repair_when_flag_disabled(self):
        """`REACT_JSON_REPAIR_ENABLED=False` → no second LLM call."""
        fake_llm = MagicMock()
        fake_llm.acall_llm_messages = AsyncMock(
            return_value='Thought: done\nFinal Answer: {"broken'
        )

        with (
            patch("src.agent.react_executor.LLMService", return_value=fake_llm),
            patch("src.agent.react_executor.settings") as mock_settings,
        ):
            mock_settings.LLM_CALL_TIMEOUT_SECONDS = 60
            mock_settings.REACT_JSON_REPAIR_ENABLED = False
            result = await react_execute(
                agent_instruction="x",
                user_prompt="y",
                tool_names=[],
                tool_registry={},
            )

        assert result.get("repair_failed") is True
        # Only one LLM call, no repair attempt
        assert fake_llm.acall_llm_messages.await_count == 1
