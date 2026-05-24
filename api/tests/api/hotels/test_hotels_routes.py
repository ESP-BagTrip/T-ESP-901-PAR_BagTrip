"""Route tests for hotels/routes.py — thin forwarding to AmadeusService."""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.hotels.routes import router as hotels_router


@pytest.fixture
def app() -> FastAPI:
    app = FastAPI()
    app.include_router(hotels_router)
    app.dependency_overrides[get_current_user] = lambda: MagicMock(id="user-1")
    return app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


class TestSearchHotelsByCity:
    def test_success(self, client: TestClient) -> None:
        hotel = MagicMock()
        hotel.model_dump.return_value = {"hotelId": "H1", "name": "Le Grand"}
        amadeus_result = MagicMock(data=[hotel])

        with patch(
            "src.api.hotels.routes.AmadeusService.search_hotel_list",
            new_callable=AsyncMock,
            return_value=amadeus_result,
        ) as mocked:
            response = client.get("/v1/travel/hotels/by-city?cityCode=PAR")

        assert response.status_code == 200
        body = response.json()
        assert body["data"][0]["hotelId"] == "H1"
        mocked.assert_awaited_once()

    def test_passes_optional_filters(self, client: TestClient) -> None:
        amadeus_result = MagicMock(data=[])
        with patch(
            "src.api.hotels.routes.AmadeusService.search_hotel_list",
            new_callable=AsyncMock,
            return_value=amadeus_result,
        ) as mocked:
            response = client.get(
                "/v1/travel/hotels/by-city"
                "?cityCode=NYC&radius=10&radiusUnit=KM&ratings=4,5&hotelSource=ALL"
            )

        assert response.status_code == 200
        assert response.json()["data"] == []
        mocked.assert_awaited_once()

    def test_missing_city_code_returns_422(self, client: TestClient) -> None:
        response = client.get("/v1/travel/hotels/by-city")
        assert response.status_code == 422


class TestSearchHotelOffers:
    def test_success(self, client: TestClient) -> None:
        offer = MagicMock()
        offer.model_dump.return_value = {
            "type": "hotel-offers",
            "hotel": {"hotelId": "H1"},
            "available": True,
            "offers": [],
        }
        amadeus_result = MagicMock(data=[offer])

        with patch(
            "src.api.hotels.routes.AmadeusService.search_hotel_offers",
            new_callable=AsyncMock,
            return_value=amadeus_result,
        ) as mocked:
            response = client.get(
                "/v1/travel/hotels/offers"
                "?hotelIds=H1,H2&checkInDate=2026-05-01&checkOutDate=2026-05-05&adults=2"
            )

        assert response.status_code == 200
        assert response.json()["data"][0]["hotel"]["hotelId"] == "H1"
        mocked.assert_awaited_once()

    def test_empty_result(self, client: TestClient) -> None:
        with patch(
            "src.api.hotels.routes.AmadeusService.search_hotel_offers",
            new_callable=AsyncMock,
            return_value=MagicMock(data=[]),
        ):
            response = client.get("/v1/travel/hotels/offers?hotelIds=XYZ")

        assert response.status_code == 200
        assert response.json() == {"data": []}

    def test_missing_hotel_ids_returns_422(self, client: TestClient) -> None:
        response = client.get("/v1/travel/hotels/offers")
        assert response.status_code == 422
