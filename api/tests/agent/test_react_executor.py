"""Unit tests for ReAct executor — parse_react_output() and react_execute()."""

from __future__ import annotations

import asyncio
import json
from unittest.mock import AsyncMock, patch

import pytest

from src.agent.react_executor import parse_react_output, react_execute

# ---------------------------------------------------------------------------
# parse_react_output — Final Answer
# ---------------------------------------------------------------------------


class TestParseReactOutputFinalAnswer:
    def test_simple_json(self):
        output = (
            "Thought: I have all the data.\n"
            'Final Answer: {"destinations": [{"city": "Paris"}]}'
        )
        result = parse_react_output(output)
        assert isinstance(result, str)
        parsed = json.loads(result)
        assert parsed["destinations"][0]["city"] == "Paris"

    def test_with_markdown_fences(self):
        output = 'Final Answer: ```json\n{"key": "value"}\n```'
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert json.loads(result) == {"key": "value"}

    def test_with_backtick_no_lang(self):
        output = 'Final Answer: ```\n{"key": "value"}\n```'
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert json.loads(result) == {"key": "value"}

    def test_multiline_json(self):
        output = (
            "Thought: done.\n"
            "Final Answer: {\n"
            '  "destinations": [\n'
            '    {"city": "Rome", "country": "Italy"}\n'
            "  ]\n"
            "}"
        )
        result = parse_react_output(output)
        assert isinstance(result, str)
        parsed = json.loads(result)
        assert parsed["destinations"][0]["city"] == "Rome"

    def test_takes_priority_over_action(self):
        """Final Answer is checked before Action — if both present, Final Answer wins."""
        output = (
            "Action: resolve_iata_code\n"
            'Action Input: {"city": "Paris"}\n'
            'Final Answer: {"result": true}'
        )
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert json.loads(result) == {"result": True}

    def test_plain_text_final_answer(self):
        output = "Final Answer: I could not find any flights."
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert result == "I could not find any flights."


# ---------------------------------------------------------------------------
# parse_react_output — Action + Action Input
# ---------------------------------------------------------------------------


class TestParseReactOutputAction:
    def test_valid_json_input(self):
        output = (
            "Thought: I need the IATA code.\n"
            "Action: resolve_iata_code\n"
            'Action Input: {"city_name": "Paris"}'
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        tool_name, tool_input = result
        assert tool_name == "resolve_iata_code"
        assert tool_input == {"city_name": "Paris"}

    def test_markdown_fenced_input(self):
        output = (
            "Action: search_real_flights\n"
            "Action Input: ```json\n"
            '{"origin": "CDG", "destination": "BCN"}\n'
            "```"
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[0] == "search_real_flights"
        assert result[1]["origin"] == "CDG"
        assert result[1]["destination"] == "BCN"

    def test_input_followed_by_thought(self):
        """Action Input boundary regex stops at next Thought line."""
        output = (
            "Action: get_weather\n"
            'Action Input: {"latitude": 48.85, "longitude": 2.35}\n'
            "Thought: Now I wait for the result."
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[0] == "get_weather"
        assert result[1]["latitude"] == 48.85

    def test_input_followed_by_another_action(self):
        """Action Input boundary regex stops at next Action line."""
        output = (
            "Action: resolve_iata_code\n"
            'Action Input: {"city_name": "Tokyo"}\n'
            "Action: search_real_flights\n"
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[0] == "resolve_iata_code"
        assert result[1] == {"city_name": "Tokyo"}

    def test_multiline_json_input(self):
        output = (
            "Action: search_real_flights\n"
            "Action Input: {\n"
            '  "origin": "CDG",\n'
            '  "destination": "NRT",\n'
            '  "departure_date": "2025-07-01"\n'
            "}"
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[0] == "search_real_flights"
        assert result[1]["destination"] == "NRT"


# ---------------------------------------------------------------------------
# parse_react_output — JSON recovery (malformed input)
# ---------------------------------------------------------------------------


class TestParseReactOutputJsonRecovery:
    def test_malformed_json_recovery(self):
        """Regex r'\\{[^}]+\\}' extracts first JSON-like object."""
        output = (
            "Action: resolve_iata_code\n"
            'Action Input: the city is {"city_name": "Tokyo"} okay'
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[1] == {"city_name": "Tokyo"}

    def test_totally_broken_json_returns_raw(self):
        output = "Action: resolve_iata_code\nAction Input: not valid at all"
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[1] == {"raw": "not valid at all"}

    def test_recovery_with_extra_text_around_json(self):
        output = (
            "Action: get_weather\n"
            'Action Input: Here are the params: {"latitude": 35.6} end'
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[1]["latitude"] == 35.6


# ---------------------------------------------------------------------------
# parse_react_output — Destinations fallback
# ---------------------------------------------------------------------------


class TestParseReactOutputDestinationsFallback:
    def test_raw_json_with_destinations_key(self):
        """Raw JSON with 'destinations' key is detected without Action/Final Answer."""
        output = '{"destinations": [{"city": "Barcelona", "country": "Spain"}]}'
        result = parse_react_output(output)
        assert isinstance(result, str)
        parsed = json.loads(result)
        assert len(parsed["destinations"]) == 1
        assert parsed["destinations"][0]["city"] == "Barcelona"

    def test_raw_json_destinations_in_markdown_fence(self):
        output = '```json\n{"destinations": [{"city": "Lisbon"}]}\n```'
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert "Lisbon" in result

    def test_raw_json_destinations_multiline(self):
        output = (
            "{\n"
            '  "destinations": [\n'
            '    {"city": "Tokyo", "country": "Japan"}\n'
            "  ]\n"
            "}"
        )
        result = parse_react_output(output)
        assert isinstance(result, str)
        parsed = json.loads(result)
        assert parsed["destinations"][0]["city"] == "Tokyo"


# ---------------------------------------------------------------------------
# parse_react_output — Edge cases / fallback
# ---------------------------------------------------------------------------


class TestParseReactOutputEdgeCases:
    def test_no_action_no_final_answer_returns_raw(self):
        output = "I don't know what to do."
        result = parse_react_output(output)
        assert isinstance(result, str)
        assert result == "I don't know what to do."

    def test_empty_string(self):
        result = parse_react_output("")
        assert isinstance(result, str)
        assert result == ""

    def test_action_without_input_falls_through(self):
        """Action present but no Action Input => no input_match => fallback."""
        output = "Action: resolve_iata_code"
        result = parse_react_output(output)
        # No input_match, so it falls through to destinations fallback / raw
        assert isinstance(result, str)

    def test_only_thought(self):
        output = "Thought: I need to think about this more."
        result = parse_react_output(output)
        assert isinstance(result, str)

    def test_whitespace_around_action_name(self):
        output = (
            "Action:   resolve_iata_code  \n" 'Action Input: {"city_name": "Paris"}'
        )
        result = parse_react_output(output)
        assert isinstance(result, tuple)
        assert result[0] == "resolve_iata_code"


# ---------------------------------------------------------------------------
# react_execute — async tests with mocked LLM
# ---------------------------------------------------------------------------


class TestReactExecute:
    @pytest.mark.asyncio
    async def test_final_answer_first_iteration(self):
        """LLM returns Final Answer on first call => returns parsed JSON."""
        mock_llm = AsyncMock(
            return_value='Thought: done.\nFinal Answer: {"city": "Paris"}'
        )
        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = mock_llm
            result = await react_execute(
                agent_instruction="Find a destination",
                user_prompt="I want to go somewhere warm",
                tool_names=[],
                tool_registry={},
            )
        assert result == {"city": "Paris"}
        assert mock_llm.call_count == 1

    @pytest.mark.asyncio
    async def test_tool_call_then_final_answer(self):
        """LLM calls a tool, gets observation, then returns Final Answer."""
        mock_tool_fn = AsyncMock(return_value={"iata": "CDG"})
        tool_registry = {
            "resolve_iata_code": {
                "description": "Resolve IATA code",
                "fn": mock_tool_fn,
            }
        }

        call_count = 0

        async def mock_llm_side_effect(messages):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return (
                    "Thought: I need the IATA code.\n"
                    "Action: resolve_iata_code\n"
                    'Action Input: {"city_name": "Paris"}'
                )
            return 'Final Answer: {"iata": "CDG", "city": "Paris"}'

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = AsyncMock(
                side_effect=mock_llm_side_effect
            )
            result = await react_execute(
                agent_instruction="Find IATA",
                user_prompt="Paris",
                tool_names=["resolve_iata_code"],
                tool_registry=tool_registry,
            )

        assert result["iata"] == "CDG"
        mock_tool_fn.assert_called_once_with(city_name="Paris")

    @pytest.mark.asyncio
    async def test_unknown_tool_returns_error_observation(self):
        """If LLM calls a tool not in registry, observation contains error."""
        call_count = 0

        async def mock_llm_side_effect(messages):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return (
                    "Action: nonexistent_tool\n"
                    'Action Input: {"foo": "bar"}'
                )
            # After seeing the error observation, LLM gives final answer
            return 'Final Answer: {"error": "tool not found"}'

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = AsyncMock(
                side_effect=mock_llm_side_effect
            )
            result = await react_execute(
                agent_instruction="Test",
                user_prompt="Test",
                tool_names=["resolve_iata_code"],
                tool_registry={},
            )

        assert "error" in result

    @pytest.mark.asyncio
    async def test_max_iterations_forces_final_answer(self):
        """After max iterations, LLM is prompted for a final answer."""
        iteration = 0

        async def mock_llm_side_effect(messages):
            nonlocal iteration
            iteration += 1
            # Always return action until forced
            if any("maximum number of tool calls" in m.content for m in messages if hasattr(m, "content")):
                return 'Final Answer: {"forced": true}'
            return (
                "Action: resolve_iata_code\n"
                'Action Input: {"city_name": "Paris"}'
            )

        mock_tool_fn = AsyncMock(return_value={"iata": "CDG"})
        tool_registry = {
            "resolve_iata_code": {
                "description": "Resolve IATA code",
                "fn": mock_tool_fn,
            }
        }

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = AsyncMock(
                side_effect=mock_llm_side_effect
            )
            result = await react_execute(
                agent_instruction="Test",
                user_prompt="Test",
                tool_names=["resolve_iata_code"],
                tool_registry=tool_registry,
                max_iterations=2,
            )

        assert result == {"forced": True}
        # 2 iterations + 1 forced final = 3 LLM calls
        assert mock_tool_fn.call_count == 2

    @pytest.mark.asyncio
    async def test_llm_call_failure_returns_error(self):
        """If LLM call raises, returns error dict."""
        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = AsyncMock(
                side_effect=RuntimeError("LLM unavailable")
            )
            result = await react_execute(
                agent_instruction="Test",
                user_prompt="Test",
                tool_names=[],
                tool_registry={},
            )

        assert "error" in result
        assert "LLM unavailable" in result["error"]

    @pytest.mark.asyncio
    async def test_tool_type_error_returns_error_observation(self):
        """TypeError during tool call produces an error observation, not a crash."""

        async def bad_tool(**kwargs):
            raise TypeError("unexpected keyword argument")

        tool_registry = {
            "bad_tool": {"description": "Bad tool", "fn": bad_tool}
        }

        call_count = 0

        async def mock_llm_side_effect(messages):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return 'Action: bad_tool\nAction Input: {"wrong": "params"}'
            return 'Final Answer: {"recovered": true}'

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = AsyncMock(
                side_effect=mock_llm_side_effect
            )
            result = await react_execute(
                agent_instruction="Test",
                user_prompt="Test",
                tool_names=["bad_tool"],
                tool_registry=tool_registry,
            )

        assert result == {"recovered": True}

    @pytest.mark.asyncio
    async def test_llm_call_timeout_returns_error(self):
        """If LLM call exceeds LLM_CALL_TIMEOUT_SECONDS, returns timeout error."""

        async def slow_llm(messages):
            await asyncio.sleep(999)

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = slow_llm
            with patch("src.agent.react_executor.settings") as mock_settings:
                mock_settings.LLM_CALL_TIMEOUT_SECONDS = 0.1
                result = await react_execute(
                    agent_instruction="Test",
                    user_prompt="Test",
                    tool_names=[],
                    tool_registry={},
                )

        assert "error" in result
        assert "timed out" in result["error"]

    @pytest.mark.asyncio
    async def test_final_llm_call_timeout_returns_error(self):
        """If the forced final LLM call times out, returns timeout error."""
        call_count = 0

        async def llm_side_effect(messages):
            nonlocal call_count
            call_count += 1
            if call_count <= 1:
                # First iteration returns an action
                return 'Action: tool\nAction Input: {"k": "v"}'
            # Forced final call times out
            await asyncio.sleep(999)

        tool_registry = {"tool": {"description": "test", "fn": AsyncMock(return_value={})}}

        with patch("src.agent.react_executor.LLMService") as mock_llm_cls:
            mock_llm_cls.return_value.acall_llm_messages = llm_side_effect
            with patch("src.agent.react_executor.settings") as mock_settings:
                mock_settings.LLM_CALL_TIMEOUT_SECONDS = 0.1
                result = await react_execute(
                    agent_instruction="Test",
                    user_prompt="Test",
                    tool_names=["tool"],
                    tool_registry=tool_registry,
                    max_iterations=1,
                )

        assert "error" in result
        assert "timed out" in result["error"]
