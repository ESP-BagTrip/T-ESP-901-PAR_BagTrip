"""Unit tests for the agent routes."""

import json
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.agent.routes import router as agent_router

# Setup the test app
app = FastAPI()
app.include_router(agent_router)


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


def test_chat_endpoint_success(client):
    """Test successful chat interaction with streaming response."""
    mock_events = [
        {
            "event": "on_chat_model_stream",
            "data": {"chunk": MagicMock(content="Hello")},
            "name": "model",
        },
        {
            "event": "on_tool_start",
            "name": "search_locations",
            "data": {},
        },
        {
            "event": "on_tool_end",
            "name": "search_locations",
            "data": {"output": "result"},
        },
        {
            "event": "on_chat_model_stream",
            "data": {"chunk": MagicMock(content=" world")},
            "name": "model",
        },
    ]

    async def mock_astream_events(*args, **kwargs):
        for event in mock_events:
            yield event

    with patch("src.api.agent.routes.graph.astream_events", side_effect=mock_astream_events):
        response = client.post(
            "/v1/agent/agent/chat", json={"message": "hi", "userid": "user123"}
        )

        assert response.status_code == 200
        assert "text/event-stream" in response.headers["content-type"]

        # Check if expected data is in the streaming response
        lines = response.text.strip().split("\n\n")
        assert 'data: {"type": "token", "content": "Hello"}' in lines
        assert 'data: {"type": "tool_start", "tool": "search_locations"}' in lines
        assert 'data: {"type": "tool_end", "tool": "search_locations"}' in lines
        assert 'data: {"type": "token", "content": " world"}' in lines
        assert "data: [DONE]" in lines


def test_chat_endpoint_error(client):
    """Test chat endpoint when an error occurs during streaming."""

    async def mock_astream_events_error(*args, **kwargs):
        raise Exception("Stream error")
        # The following yield is needed to make this an async generator
        yield  # pragma: no cover

    with patch("src.api.agent.routes.graph.astream_events", side_effect=mock_astream_events_error):
        response = client.post(
            "/v1/agent/agent/chat", json={"message": "hi", "userid": "user123"}
        )

        assert response.status_code == 200
        assert 'data: {"type": "error", "message": "Stream error"}' in response.text


def test_chat_endpoint_invalid_request(client):
    """Test chat endpoint with invalid request body."""
    # Missing userid
    response = client.post("/v1/agent/agent/chat", json={"message": "hi"})
    assert response.status_code == 422

    # Missing message
    response = client.post("/v1/agent/agent/chat", json={"userid": "user123"})
    assert response.status_code == 422
