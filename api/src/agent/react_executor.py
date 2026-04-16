"""ReAct executor — prompt-based tool calling loop.

Since gpt-oss-120b doesn't support native function calling, we implement
the ReAct (Reason + Act) pattern manually:
  1. Send system prompt with tool descriptions + user prompt
  2. Parse LLM output for Action/Action Input blocks
  3. Execute the tool
  4. Inject the Observation back into the conversation
  5. Repeat until Final Answer or max iterations
"""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from src.config.env import settings
from src.services.llm_service import LLMService
from src.utils.logger import logger

MAX_REACT_ITERATIONS = 5


def _parse_final_answer(raw: str) -> dict | None:
    """Try to parse a Final Answer string into a dict. Return None on failure.

    Kept as a single-purpose helper so the JSON repair loop can retry the
    same parse after a corrective LLM call without re-threading the parse
    logic through the caller.
    """
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def _build_repair_prompt(raw: str, error_preview: str) -> str:
    """Craft the corrective re-prompt sent after a JSON parse failure."""
    return (
        "Your previous response was not valid JSON. "
        f"Parse error: {error_preview}. "
        "Return ONLY the corrected JSON object — no explanation, no markdown "
        "fences, no text outside the object. The object to fix was:\n\n"
        f"{raw}"
    )


async def _repair_json_once(
    llm_service: LLMService,
    raw: str,
    error: str,
) -> dict | None:
    """Re-prompt the LLM with the broken JSON and attempt to re-parse.

    This is a **single** corrective call — we do not loop. Two malformed
    responses in a row means the LLM is stuck and the caller should degrade.

    Returns a parsed dict on success, None on a second failure. Logs a WARN
    on the attempt and an ERROR on persistent failure.
    """
    logger.warn(
        "react_executor: JSON parse failed, attempting repair",
        {"error": error[:200], "preview": raw[:200]},
    )
    repair_prompt = _build_repair_prompt(raw, error[:200])
    repair_messages = [
        SystemMessage(content="You fix broken JSON. Return ONLY the JSON object."),
        HumanMessage(content=repair_prompt),
    ]
    try:
        repaired = await asyncio.wait_for(
            llm_service.acall_llm_messages(repair_messages),
            timeout=settings.LLM_CALL_TIMEOUT_SECONDS,
        )
    except Exception as exc:
        logger.error(
            "react_executor: JSON repair LLM call failed",
            {"error": str(exc)},
        )
        return None

    # Strip markdown fences in case the repair response re-added them.
    repaired = re.sub(r"^```(?:json)?\s*\n?", "", repaired.strip())
    repaired = re.sub(r"\n?```\s*$", "", repaired)
    parsed = _parse_final_answer(repaired)
    if parsed is None:
        logger.error(
            "react_executor: JSON repair failed — second parse unsuccessful",
            {"preview": repaired[:200]},
        )
    else:
        logger.info("react_executor: JSON repair succeeded")
    return parsed


def _build_tool_descriptions(tool_names: list[str], tool_registry: dict) -> str:
    """Build the tool description block for the ReAct system prompt."""
    lines = []
    for name in tool_names:
        tool = tool_registry.get(name)
        if tool:
            lines.append(f"- **{name}**: {tool['description']}")
    return "\n".join(lines)


def _build_react_system_prompt(agent_instruction: str, tool_descriptions: str) -> str:
    """Build the full ReAct system prompt."""
    return f"""{agent_instruction}

You have access to the following tools:
{tool_descriptions}

To use a tool, respond EXACTLY in this format (no markdown fences around the action):
Thought: <your reasoning>
Action: <tool_name>
Action Input: <valid JSON object with the tool parameters>

After receiving an Observation, continue reasoning.

When you have gathered enough information, provide your final answer:
Thought: <your final reasoning>
Final Answer: <valid JSON object with your complete response>

IMPORTANT:
- Action Input must be a valid JSON object (use double quotes for keys and string values).
- Final Answer must be a valid JSON object.
- Never wrap Action Input or Final Answer in markdown code fences.
- You MUST use the tools to get real data. Do NOT invent prices, IATA codes, or weather data."""


def parse_react_output(llm_output: str) -> tuple[str, dict] | str:
    """Parse the ReAct output from the LLM.

    Returns:
        (tool_name, tool_input) if an Action is detected.
        final_answer_string if 'Final Answer:' is detected.
    """
    # Check for Final Answer first
    final_match = re.search(r"Final Answer:\s*(.+)", llm_output, re.DOTALL)
    if final_match:
        raw = final_match.group(1).strip()
        # Strip markdown fences if present
        raw = re.sub(r"^```(?:json)?\s*\n?", "", raw)
        raw = re.sub(r"\n?```\s*$", "", raw)
        return raw.strip()

    # Check for Action + Action Input
    action_match = re.search(r"Action:\s*(\S+)", llm_output)
    input_match = re.search(
        r"Action Input:\s*(.+?)(?:\n(?:Thought|Action|$)|\Z)", llm_output, re.DOTALL
    )

    if action_match and input_match:
        tool_name = action_match.group(1).strip()
        raw_input = input_match.group(1).strip()
        # Strip markdown fences if present
        raw_input = re.sub(r"^```(?:json)?\s*\n?", "", raw_input)
        raw_input = re.sub(r"\n?```\s*$", "", raw_input)
        try:
            tool_input = json.loads(raw_input)
        except json.JSONDecodeError:
            logger.warn(
                "Failed to parse Action Input JSON, attempting recovery", {"raw": raw_input}
            )
            # Try to extract JSON object from the string
            json_match = re.search(r"\{[^}]+\}", raw_input)
            if json_match:
                try:
                    tool_input = json.loads(json_match.group(0))
                except json.JSONDecodeError:
                    tool_input = {"raw": raw_input}
            else:
                tool_input = {"raw": raw_input}
        return (tool_name, tool_input)

    # Neither found — try to extract JSON object with "destinations" key
    # Some LLMs return raw JSON without the ReAct format
    stripped = llm_output.strip()
    stripped = re.sub(r"^```(?:json)?\s*\n?", "", stripped)
    stripped = re.sub(r"\n?```\s*$", "", stripped)

    # Try to find a JSON object in the output
    json_match = re.search(r"\{[\s\S]*\"destinations\"[\s\S]*\}", stripped)
    if json_match:
        try:
            parsed_json = json.loads(json_match.group(0))
            logger.info("ReAct parse: extracted JSON with destinations from raw output")
            return json.dumps(parsed_json)
        except json.JSONDecodeError:
            pass

    logger.warn(
        "ReAct parse: no Action or Final Answer found, treating as final answer",
        {"raw_output_preview": stripped[:300]},
    )
    return stripped


async def react_execute(
    agent_instruction: str,
    user_prompt: str,
    tool_names: list[str],
    tool_registry: dict,
    max_iterations: int = MAX_REACT_ITERATIONS,
) -> dict[str, Any]:
    """Run the ReAct loop: prompt LLM → parse → execute tool → repeat.

    Returns the parsed Final Answer as a dict, or a fallback dict on failure.
    """
    tool_descriptions = _build_tool_descriptions(tool_names, tool_registry)
    system_prompt = _build_react_system_prompt(agent_instruction, tool_descriptions)

    llm_service = LLMService()
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=user_prompt),
    ]

    for iteration in range(max_iterations):
        logger.info(f"ReAct iteration {iteration + 1}/{max_iterations}")

        # Call LLM (with per-call timeout)
        try:
            raw_response = await asyncio.wait_for(
                llm_service.acall_llm_messages(messages),
                timeout=settings.LLM_CALL_TIMEOUT_SECONDS,
            )
        except TimeoutError:
            logger.error(
                "ReAct LLM call timed out",
                {"iteration": iteration + 1, "timeout": settings.LLM_CALL_TIMEOUT_SECONDS},
            )
            return {"error": f"LLM call timed out after {settings.LLM_CALL_TIMEOUT_SECONDS}s"}
        except Exception as e:
            logger.error("ReAct LLM call failed", {"error": str(e)})
            return {"error": f"LLM call failed: {e}"}

        messages.append(AIMessage(content=raw_response))

        logger.info(
            f"ReAct LLM response (iter {iteration + 1})",
            {"preview": raw_response[:500]},
        )

        # Parse the output
        parsed = parse_react_output(raw_response)

        if isinstance(parsed, str):
            # Final Answer (string) — try to parse as JSON, with one repair
            # attempt on failure. The repair guard is gated by a config flag
            # so the team can disable it if double-billing ever becomes a
            # concern.
            final_dict = _parse_final_answer(parsed)
            if final_dict is not None:
                return final_dict
            if settings.REACT_JSON_REPAIR_ENABLED:
                repaired = await _repair_json_once(
                    llm_service,
                    parsed,
                    "Final Answer did not parse as JSON",
                )
                if repaired is not None:
                    return repaired
            logger.warn("Final Answer is not valid JSON, returning as-is")
            return {"raw_answer": parsed, "repair_failed": True}

        # It's a tool call: (tool_name, tool_input)
        tool_name, tool_input = parsed
        logger.info(f"ReAct tool call: {tool_name}", {"input": tool_input})

        # Execute the tool
        tool_def = tool_registry.get(tool_name)
        if not tool_def:
            observation = f"Error: Unknown tool '{tool_name}'. Available: {', '.join(tool_names)}"
        else:
            try:
                tool_fn = tool_def["fn"]
                observation_data = await tool_fn(**tool_input)
                observation = json.dumps(observation_data, default=str)
            except TypeError as e:
                observation = f"Error calling {tool_name}: invalid parameters — {e}"
                logger.error(
                    f"Tool call type error: {tool_name}", {"error": str(e), "input": tool_input}
                )
            except Exception as e:
                observation = f"Error calling {tool_name}: {e}"
                logger.error(f"Tool call failed: {tool_name}", {"error": str(e)})

        # Feed observation back
        messages.append(HumanMessage(content=f"Observation: {observation}"))

    # Max iterations reached — force a final answer
    logger.warn("ReAct max iterations reached, requesting final answer")
    messages.append(
        HumanMessage(
            content="You have reached the maximum number of tool calls. Please provide your Final Answer now based on the information gathered so far."
        )
    )

    try:
        raw_response = await asyncio.wait_for(
            llm_service.acall_llm_messages(messages),
            timeout=settings.LLM_CALL_TIMEOUT_SECONDS,
        )
        parsed = parse_react_output(raw_response)
        if isinstance(parsed, str):
            final_dict = _parse_final_answer(parsed)
            if final_dict is not None:
                return final_dict
            if settings.REACT_JSON_REPAIR_ENABLED:
                repaired = await _repair_json_once(
                    llm_service,
                    parsed,
                    "Forced Final Answer did not parse as JSON",
                )
                if repaired is not None:
                    return repaired
            return {"raw_answer": parsed, "repair_failed": True}
        return {"error": "Failed to get final answer after max iterations"}
    except TimeoutError:
        return {"error": f"Final LLM call timed out after {settings.LLM_CALL_TIMEOUT_SECONDS}s"}
    except Exception as e:
        return {"error": f"Final LLM call failed: {e}"}
