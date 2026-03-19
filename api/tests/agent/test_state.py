"""Unit tests for agent state."""

from src.agent.state import AgentState


def test_agent_state_structure():
    """Test that AgentState has the expected fields."""
    
    state: AgentState = {
        "messages": [],
        "userid": "user123"
    }
    
    assert state["userid"] == "user123"
    assert state["messages"] == []
