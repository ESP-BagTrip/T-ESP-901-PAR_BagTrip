"""Unit tests for AI trip planning routes."""

import json
import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.ai.plan_trip_routes import router as ai_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User

app = FastAPI()
app.include_router(ai_router)

@pytest.fixture
def mock_user():
    user = User(id=uuid.uuid4(), email="ai@example.com")
    user.ai_generations_count = 0
    user.plan = "FREE"
    user.ai_generations_reset_at = None
    return user

@pytest.fixture
def client(mock_user):
    app.dependency_overrides[get_current_user] = lambda: mock_user
    app.dependency_overrides[get_db] = lambda: MagicMock()
    with TestClient(app) as c:
        yield c
    app.dependency_overrides = {}

class TestAIPlanTrip:
    """Tests for AI trip planning endpoints."""

    @patch("src.api.ai.plan_trip_routes._trip_plan_generator")
    def test_plan_trip_sse_success(self, mock_gen, client):
        """Test the SSE trip planning endpoint."""
        # Mock the generator to yield some SSE events
        async def fake_gen(*args, **kwargs):
            yield "event: progress\ndata: 50\n\n"
            yield "event: result\ndata: {}\n\n"
        
        mock_gen.return_value = fake_gen()

        payload = {
            "originIata": "PAR",
            "destinationIata": "NYC",
            "dateMode": "EXACT",
            "departureDate": "2025-12-25",
            "returnDate": "2026-01-01",
            "adults": 1
        }
        
        # Correct path: /v1/ai/plan-trip/stream
        with client.stream("POST", "/v1/ai/plan-trip/stream", json=payload) as response:
            assert response.status_code == 200
            lines = list(response.iter_lines())
            assert "event: progress" in lines[0]
            assert "data: 50" in lines[1]

    def test_accept_plan_success(self, client):
        """Test accepting a generated trip plan."""
        payload = {
            "suggestion": {
                "title": "My Trip",
                "originIata": "PAR",
                "destinationIata": "NYC",
                "destinations": [{"city": "NYC", "country": "USA", "iata": "NYC"}],
                "activities": [],
                "accommodations": [],
                "flight": {"route": "PAR-NYC", "price": 500}
            },
            "startDate": "2025-12-25",
            "endDate": "2026-01-01",
            "dateMode": "EXACT"
        }
        
        # Mock TripsService.create_trip
        with patch("src.api.ai.plan_trip_routes.TripsService.create_trip") as mock_create:
            mock_trip = MagicMock()
            mock_trip.id = uuid.uuid4()
            mock_trip.title = "My Trip"
            mock_trip.status = "DRAFT"
            mock_trip.destination_name = "New York"
            mock_trip.description = ""
            mock_trip.budget_total = 0
            mock_trip.origin = "AI"
            mock_trip.start_date = None
            mock_trip.end_date = None
            mock_create.return_value = mock_trip
            
            # Correct path: /v1/ai/plan-trip/accept
            response = client.post("/v1/ai/plan-trip/accept", json=payload)
            
            assert response.status_code == 200
            assert response.json()["id"] == str(mock_trip.id)
            assert mock_create.called
