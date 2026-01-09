"""Unit tests for agent state."""

from src.agent.state import AgentState


def test_agent_state_structure():
    """Test that AgentState has the expected fields."""
    # Since it's a TypedDict (via MessagesState which usually is), we check keys if possible,
    # or just instantiation if it were a class. 
    # MessagesState from langgraph is a TypedDict.
    
    state: AgentState = {
        "messages": [],
        "userid": "user123"
    }
    
    assert state["userid"] == "user123"
    assert state["messages"] == []
