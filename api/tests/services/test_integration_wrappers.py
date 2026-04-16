"""Unit tests for the thin integration service wrappers.

These services (`AmadeusService`, `StripeGatewayService`, `AirLabsService`)
exist solely to provide a layering seam between routes and the third-party
clients. The tests here are pure delegation checks: "when the facade method
is called, the underlying client method is called with the same arguments
and the result is returned unchanged." Any logic above "forward the call"
lives in the route handlers or higher-level services, not here.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest


class TestAmadeusService:
    @pytest.mark.asyncio
    async def test_search_flight_offers_delegates(self):
        from src.services.amadeus_service import AmadeusService

        query = MagicMock(name="FlightOfferSearchQuery")
        expected = MagicMock(name="response")
        with patch(
            "src.services.amadeus_service.amadeus_client.search_flight_offers",
            new_callable=AsyncMock,
            return_value=expected,
        ) as mock_client:
            result = await AmadeusService.search_flight_offers(query)
        mock_client.assert_awaited_once_with(query)
        assert result is expected

    @pytest.mark.asyncio
    async def test_search_flight_destinations_delegates(self):
        from src.services.amadeus_service import AmadeusService

        query = MagicMock()
        with patch(
            "src.services.amadeus_service.amadeus_client.search_flight_destinations",
            new_callable=AsyncMock,
            return_value={"data": []},
        ) as mock:
            result = await AmadeusService.search_flight_destinations(query)
        mock.assert_awaited_once_with(query)
        assert result == {"data": []}

    @pytest.mark.asyncio
    async def test_search_flight_cheapest_dates_delegates(self):
        from src.services.amadeus_service import AmadeusService

        query = MagicMock()
        with patch(
            "src.services.amadeus_service.amadeus_client.search_flight_cheapest_dates",
            new_callable=AsyncMock,
        ) as mock:
            await AmadeusService.search_flight_cheapest_dates(query)
        mock.assert_awaited_once_with(query)

    @pytest.mark.asyncio
    async def test_confirm_flight_price_delegates(self):
        from src.services.amadeus_service import AmadeusService

        offer = MagicMock()
        with patch(
            "src.services.amadeus_service.amadeus_client.confirm_flight_price",
            new_callable=AsyncMock,
        ) as mock:
            await AmadeusService.confirm_flight_price(offer)
        mock.assert_awaited_once_with(offer)

    @pytest.mark.asyncio
    async def test_create_flight_order_delegates(self):
        from src.services.amadeus_service import AmadeusService

        offer = MagicMock()
        travelers = [MagicMock(), MagicMock()]
        with patch(
            "src.services.amadeus_service.amadeus_client.create_flight_order",
            new_callable=AsyncMock,
        ) as mock:
            await AmadeusService.create_flight_order(offer, travelers)
        mock.assert_awaited_once_with(offer, travelers)

    @pytest.mark.asyncio
    async def test_search_hotel_list_delegates(self):
        from src.services.amadeus_service import AmadeusService

        query = MagicMock()
        with patch(
            "src.services.amadeus_service.amadeus_client.search_hotel_list",
            new_callable=AsyncMock,
        ) as mock:
            await AmadeusService.search_hotel_list(query)
        mock.assert_awaited_once_with(query)

    @pytest.mark.asyncio
    async def test_search_hotel_offers_delegates(self):
        from src.services.amadeus_service import AmadeusService

        query = MagicMock()
        with patch(
            "src.services.amadeus_service.amadeus_client.search_hotel_offers",
            new_callable=AsyncMock,
        ) as mock:
            await AmadeusService.search_hotel_offers(query)
        mock.assert_awaited_once_with(query)


class TestAirLabsService:
    def test_lookup_flight_delegates(self):
        from src.services.airlabs_service import AirLabsService

        with patch(
            "src.services.airlabs_service.airlabs_client.lookup_flight",
            return_value={"flight_iata": "AF1234"},
        ) as mock:
            result = AirLabsService.lookup_flight("AF1234")
        mock.assert_called_once_with("AF1234")
        assert result == {"flight_iata": "AF1234"}

    def test_lookup_flight_none_pass_through(self):
        from src.services.airlabs_service import AirLabsService

        with patch(
            "src.services.airlabs_service.airlabs_client.lookup_flight",
            return_value=None,
        ):
            result = AirLabsService.lookup_flight("XX9999")
        assert result is None


class TestStripeGatewayService:
    def test_delete_customer_delegates(self):
        from src.services.stripe_gateway_service import StripeGatewayService

        with patch(
            "src.services.stripe_gateway_service.StripeClient.delete_customer",
        ) as mock:
            StripeGatewayService.delete_customer("cus_test_123")
        mock.assert_called_once_with("cus_test_123")
