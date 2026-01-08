"""Unit tests for the trips routes."""

from datetime import date, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.trips.routes import router as trips_router
from src.models.user import User
from src.utils.errors import AppError
from src.api.auth.middleware import get_current_user
from src.config.database import get_db

# Setup the test app
app = FastAPI()
app.include_router(trips_router)

# Mock user
mock_user_id = uuid4()
mock_user = User(id=mock_user_id, email="test@example.com")

def override_get_current_user():
    return mock_user

def override_get_db():
    return MagicMock()

app.dependency_overrides[get_current_user] = override_get_current_user
app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client

@pytest.fixture
def mock_trip():
    return MagicMock(
        id=uuid4(),
        user_id=mock_user_id,
        title="Test Trip",
        origin_iata="PAR",
        destination_iata="NYC",
        start_date=date(2025, 12, 1),
        end_date=date(2025, 12, 10),
        status="DRAFT",
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )

@patch("src.api.trips.routes.TripsService")
class TestCreateTrip:
    def test_create_trip_success(self, mock_service, client, mock_trip):
        mock_service.create_trip.return_value = mock_trip
        
        payload = {
            "title": "Test Trip",
            "originIata": "PAR",
            "destinationIata": "NYC",
            "startDate": "2025-12-01",
            "endDate": "2025-12-10"
        }
        
        response = client.post("/v1/trips", json=payload)
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Trip"
        assert data["origin_iata"] == "PAR"
        mock_service.create_trip.assert_called_once()

    def test_create_trip_error(self, mock_service, client):
        mock_service.create_trip.side_effect = AppError("CREATE_ERROR", 400, "Failed to create trip")
        
        payload = {"title": "Test Trip"}
        response = client.post("/v1/trips", json=payload)
        
        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "CREATE_ERROR"


@patch("src.api.trips.routes.TripsService")
class TestListTrips:
    def test_list_trips_success(self, mock_service, client, mock_trip):
        mock_service.get_trips_by_user.return_value = [mock_trip]
        
        response = client.get("/v1/trips")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["id"] == str(mock_trip.id)
        mock_service.get_trips_by_user.assert_called_once()

    def test_list_trips_empty(self, mock_service, client):
        mock_service.get_trips_by_user.return_value = []
        
        response = client.get("/v1/trips")
        
        assert response.status_code == 200
        assert len(response.json()["items"]) == 0

    def test_list_trips_error(self, mock_service, client):
        mock_service.get_trips_by_user.side_effect = AppError("DB_ERROR", 500, "Database error")
        
        response = client.get("/v1/trips")
        
        assert response.status_code == 500


@patch("src.api.trips.routes.TripsService")
class TestGetTrip:
    def test_get_trip_success_no_details(self, mock_service, client, mock_trip):
        mock_service.get_trip_by_id.return_value = mock_trip
        
        # We need to mock the DB queries in the route handler for FlightOrder and HotelBooking
        # Since we can't easily patch the db session inside the route from here without more complex setup,
        # we relying on the dependency override returning a MagicMock which returns other MagicMocks.
        # db.query(FlightOrder).filter(...).first() -> defaults to MagicMock if not configured, which evaluates to truthy?
        # No, MagicMock() is truthy. But we want to simulate None or specific objects.
        
        # Let's customize the db override for this test if possible, or configure the mock returned by the global override.
        # Since 'client' fixture uses the global app which uses the global override.
        # But `override_get_db` returns a new MagicMock each time.
        # The route calls: db.query(FlightOrder).filter(...).first()
        
        # It's tricky to mock the chain of calls on a fresh MagicMock inside the function.
        # Instead, let's patch `get_db` in the router module context if possible, but FastAPI resolves dependencies at request time.
        
        # A better approach for the route logic test involving DB queries is to mock the `db` object passed to the function.
        # But we are using `client.get`, so FastAPI calls `get_db`.
        
        # We can update `app.dependency_overrides[get_db]` to return a configured mock.
        pass

    def test_get_trip_not_found(self, mock_service, client):
        mock_service.get_trip_by_id.return_value = None
        
        response = client.get(f"/v1/trips/{uuid4()}")
        
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "TRIP_NOT_FOUND"


# To properly test get_trip with DB queries, we'll define a configured mock db fixture
@pytest.fixture
def mock_db_session():
    return MagicMock()

@pytest.fixture
def client_with_mock_db(mock_db_session):
    app.dependency_overrides[get_db] = lambda: mock_db_session
    with TestClient(app) as client:
        yield client
    # Restore default override
    app.dependency_overrides[get_db] = override_get_db

@patch("src.api.trips.routes.TripsService")
class TestGetTripDetails:
    def test_get_trip_full_details(self, mock_service, client_with_mock_db, mock_db_session, mock_trip):
        mock_service.get_trip_by_id.return_value = mock_trip
        
        # Configure DB mocks
        mock_flight_order = MagicMock()
        mock_flight_order.id = uuid4()
        mock_flight_order.amadeus_flight_order_id = "FO123"
        mock_flight_order.status = "CONFIRMED"
        
        mock_hotel_booking = MagicMock()
        mock_hotel_booking.id = uuid4()
        mock_hotel_booking.amadeus_booking_id = "HB123"
        mock_hotel_booking.status = "CONFIRMED"
        
        # db.query(Model) -> mock_query
        # mock_query.filter(...) -> mock_filter
        # mock_filter.first() -> result
        
        # We need to distinguish between calls for FlightOrder and HotelBooking.
        # Side effect for query()
        def query_side_effect(model):
            mock_query = MagicMock()
            if model.__name__ == "FlightOrder":
                mock_query.filter.return_value.first.return_value = mock_flight_order
            elif model.__name__ == "HotelBooking":
                mock_query.filter.return_value.first.return_value = mock_hotel_booking
            return mock_query

        mock_db_session.query.side_effect = query_side_effect
        
        response = client_with_mock_db.get(f"/v1/trips/{mock_trip.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["flightOrder"]["amadeusFlightOrderId"] == "FO123"
        assert data["hotelBooking"]["amadeusBookingId"] == "HB123"

    def test_get_trip_no_details(self, mock_service, client_with_mock_db, mock_db_session, mock_trip):
        mock_service.get_trip_by_id.return_value = mock_trip
        
        # Return None for associated records
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        response = client_with_mock_db.get(f"/v1/trips/{mock_trip.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["flightOrder"] is None
        assert data["hotelBooking"] is None


@patch("src.api.trips.routes.TripsService")
class TestUpdateTrip:
    def test_update_trip_success(self, mock_service, client, mock_trip):
        mock_trip.title = "Updated Title"
        mock_service.update_trip.return_value = mock_trip
        
        payload = {"title": "Updated Title", "status": "CONFIRMED"}
        response = client.patch(f"/v1/trips/{mock_trip.id}", json=payload)
        
        assert response.status_code == 200
        assert response.json()["title"] == "Updated Title"
        mock_service.update_trip.assert_called_once()

    def test_update_trip_not_found(self, mock_service, client):
        mock_service.update_trip.side_effect = AppError("TRIP_NOT_FOUND", 404, "Trip not found")
        
        response = client.patch(f"/v1/trips/{uuid4()}", json={})
        
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "TRIP_NOT_FOUND"


@patch("src.api.trips.routes.TripsService")
class TestDeleteTrip:
    def test_delete_trip_success(self, mock_service, client):
        mock_service.delete_trip.return_value = None
        
        response = client.delete(f"/v1/trips/{uuid4()}")
        
        assert response.status_code == 204
        mock_service.delete_trip.assert_called_once()

    def test_delete_trip_not_found(self, mock_service, client):
        mock_service.delete_trip.side_effect = AppError("TRIP_NOT_FOUND", 404, "Trip not found")
        
        response = client.delete(f"/v1/trips/{uuid4()}")
        
        assert response.status_code == 404
