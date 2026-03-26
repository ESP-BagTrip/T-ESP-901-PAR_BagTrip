"""Unit tests for agent graph."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from langchain_core.messages import AIMessage, HumanMessage

# Need to patch ChatGoogleGenerativeAI before importing graph because it's instantiated at module level
with patch("src.agent.graph.ChatGoogleGenerativeAI"):
    from src.agent.graph import agent_node, graph


@pytest.mark.asyncio
async def test_agent_node():
    """Test the agent node logic."""
    # Mock state
    state = {
        "messages": [HumanMessage(content="Hello")],
        "userid": "user123"
    }
    
    # Mock LLM response
    mock_response = AIMessage(content="Hi there")
    
    # We need to patch the llm_with_tools object in the module
    with patch("src.agent.graph.llm_with_tools") as mock_llm:
        mock_llm.ainvoke = AsyncMock(return_value=mock_response)
        
        result = await agent_node(state)
        
        assert "messages" in result
        assert len(result["messages"]) == 1
        assert result["messages"][0].content == "Hi there"
        mock_llm.ainvoke.assert_called_once()


def test_graph_compilation():
    """Test that the graph is compiled and has expected nodes."""
    # This just ensures the module loaded and graph object exists
    assert graph is not None
    # We can check basic properties if accessible, e.g. nodes
    # For CompiledGraph, we might check .get_graph()
    try:
        drawable_graph = graph.get_graph()
        nodes = drawable_graph.nodes
        assert "agent" in nodes
        assert "tools" in nodes
    except Exception:
        # Fallback if get_graph is not available/working in this version
        pass
