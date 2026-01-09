"""Unit tests for the agent routes."""

import json
import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from src.api.agent.routes import router as agent_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User

# Setup the test app
app = FastAPI()
app.include_router(agent_router)


@pytest.fixture
def mock_user():
    return User(id=uuid.uuid4(), email="test@example.com")


@pytest.fixture
def mock_db_session():
    return MagicMock(spec=Session)


@pytest.fixture
def client(mock_user, mock_db_session):
    """Provide a test client for the app."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    app.dependency_overrides[get_db] = lambda: mock_db_session

    with TestClient(app) as client:
        yield client

    app.dependency_overrides = {}


@patch("src.api.agent.routes.verify_trip_ownership")
@patch("src.api.agent.routes.verify_conversation_ownership")
@patch("src.api.agent.routes.ContextService")
@patch("src.api.agent.routes.MessageService")
def test_chat_endpoint_success(
    mock_message_service,
    mock_context_service,
    mock_verify_conv,
    mock_verify_trip,
    client,
    mock_user,
):
    """Test successful chat interaction with streaming response."""
    # Setup mocks
    trip_id = uuid.uuid4()
    mock_verify_trip.return_value = True
    mock_verify_conv.return_value = MagicMock(trip_id=trip_id)

    mock_context_service.get_context.return_value = MagicMock(
        version=1, id=uuid.uuid4(), state={}, ui={}
    )
    mock_message_service.get_messages_by_conversation.return_value = []

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

    with patch(
        "src.api.agent.routes.graph.astream_events", side_effect=mock_astream_events
    ):
        response = client.post(
            "/v1/agent/chat",
            json={
                "message": "hi",
                "trip_id": str(trip_id),
                "conversation_id": str(uuid.uuid4()),
                "context_version": 1,
            },
        )

        assert response.status_code == 200
        assert "text/event-stream" in response.headers["content-type"]

        text = response.text
        # Check for events in the stream
        assert "event: message.delta" in text
        assert 'data: {"text": "Hello"}' in text
        assert "event: tool.start" in text
        assert 'data: {"tool": "search_locations"}' in text
        assert "event: tool.end" in text
        assert 'data: {"text": " world"}' in text


@patch("src.api.agent.routes.verify_trip_ownership")
@patch("src.api.agent.routes.verify_conversation_ownership")
@patch("src.api.agent.routes.ContextService")
@patch("src.api.agent.routes.MessageService")
def test_chat_endpoint_error(
    mock_message_service,
    mock_context_service,
    mock_verify_conv,
    mock_verify_trip,
    client,
):
    """Test chat endpoint when an error occurs during streaming."""

    # Setup minimal mocks for validation pass
    trip_id = uuid.uuid4()
    mock_verify_trip.return_value = True
    mock_verify_conv.return_value = MagicMock(trip_id=trip_id)
    mock_context_service.get_context.return_value = MagicMock(version=1)
    mock_message_service.get_messages_by_conversation.return_value = []

    async def mock_astream_events_error(*args, **kwargs):
        raise Exception("Stream error")
        yield  # Make it generator

    with patch(
        "src.api.agent.routes.graph.astream_events",
        side_effect=mock_astream_events_error,
    ):
        response = client.post(
            "/v1/agent/chat",
            json={
                "message": "hi",
                "trip_id": str(trip_id),
                "conversation_id": str(uuid.uuid4()),
            },
        )

        assert response.status_code == 200
        assert "event: error" in response.text
        assert 'data: {"message": "Stream error"}' in response.text


def test_chat_endpoint_invalid_request(client):
    """Test chat endpoint with invalid request body."""
    # Missing parameters
    response = client.post("/v1/agent/chat", json={"message": "hi"})
    assert response.status_code == 422