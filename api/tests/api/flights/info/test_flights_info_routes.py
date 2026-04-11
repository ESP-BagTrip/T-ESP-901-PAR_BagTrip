"""Route tests for flights/info/routes.py — AirLabs forwarding + validation."""

from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.flights.info.routes import router as flight_info_router
from src.utils.errors import AppError


@pytest.fixture
def app() -> FastAPI:
    app = FastAPI()
    app.include_router(flight_info_router)
    app.dependency_overrides[get_current_user] = lambda: MagicMock(id="user-1")

    # The real app exposes a global AppError handler — replicate it here so
    # routes that raise via `create_http_exception` are mapped correctly.
    @app.exception_handler(AppError)
    async def _handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": {"error": exc.message, "code": exc.code}},
        )

    return app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


class TestGetFlightInfo:
    def test_success(self, client: TestClient) -> None:
        payload = {
            "flight_iata": "AF1234",
            "airline_iata": "AF",
            "airline_name": "Air France",
            "status": "en-route",
            "dep_iata": "CDG",
            "dep_terminal": "2E",
            "dep_gate": "K30",
            "dep_time": "2026-05-01 10:00",
            "dep_actual": None,
            "dep_delayed": None,
            "arr_iata": "JFK",
            "arr_terminal": "1",
            "arr_gate": "A5",
            "arr_time": "2026-05-01 13:00",
            "arr_actual": None,
            "arr_delayed": None,
        }
        with (
            patch("src.api.flights.info.routes.settings.AIRLABS_API_KEY", "fake-key"),
            patch(
                "src.api.flights.info.routes.AirLabsService.lookup_flight",
                return_value=payload,
            ),
        ):
            response = client.get("/v1/travel/flights/AF1234/info")

        assert response.status_code == 200
        body = response.json()
        assert body["flightIata"] == "AF1234"
        assert body["airlineName"] == "Air France"

    def test_service_not_configured(self, client: TestClient) -> None:
        with patch("src.api.flights.info.routes.settings.AIRLABS_API_KEY", None):
            response = client.get("/v1/travel/flights/AF1234/info")
        assert response.status_code == 503
        assert response.json()["detail"]["code"] == "AIRLABS_NOT_CONFIGURED"

    def test_invalid_flight_number(self, client: TestClient) -> None:
        with patch("src.api.flights.info.routes.settings.AIRLABS_API_KEY", "fake-key"):
            response = client.get("/v1/travel/flights/not-a-flight/info")
        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "INVALID_FLIGHT_NUMBER"

    def test_flight_not_found(self, client: TestClient) -> None:
        with (
            patch("src.api.flights.info.routes.settings.AIRLABS_API_KEY", "fake-key"),
            patch(
                "src.api.flights.info.routes.AirLabsService.lookup_flight",
                return_value=None,
            ),
        ):
            response = client.get("/v1/travel/flights/AF1234/info")
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "FLIGHT_NOT_FOUND"

    def test_flight_number_is_uppercased(self, client: TestClient) -> None:
        with (
            patch("src.api.flights.info.routes.settings.AIRLABS_API_KEY", "fake-key"),
            patch(
                "src.api.flights.info.routes.AirLabsService.lookup_flight",
                return_value={"flight_iata": "AF1234"},
            ) as lookup,
        ):
            response = client.get("/v1/travel/flights/af1234/info")
        assert response.status_code == 200
        lookup.assert_called_once_with("AF1234")
