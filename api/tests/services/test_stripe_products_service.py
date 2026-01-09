"""Unit tests for StripeProductsService."""

from unittest.mock import MagicMock, patch

from src.services.stripe_products_service import StripeProductsService


class TestStripeProductsService:
    """Tests for StripeProductsService."""

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_success(self, mock_product, mock_settings):
        """Test successful product initialization."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        
        # Mock product creation
        mock_product.list.return_value = []
        mock_product.create.side_effect = [
            MagicMock(id="prod_flight"),
            MagicMock(id="prod_hotel")
        ]
        
        products = StripeProductsService.initialize_products()
        
        assert products["flight"] == "prod_flight"
        assert products["hotel"] == "prod_hotel"
        assert StripeProductsService.get_product_id("flight") == "prod_flight"

    @patch("src.services.stripe_products_service.settings")
    def test_initialize_products_no_key(self, mock_settings):
        """Test initialization skipped without key."""
        mock_settings.STRIPE_SECRET_KEY = None
        
        products = StripeProductsService.initialize_products()
        assert products == {}

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_existing(self, mock_product, mock_settings):
        """Test finding existing products."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        
        existing_flight = MagicMock(id="prod_flight_old")
        existing_flight.metadata = {"type": "flight"}
        
        mock_product.list.return_value = [existing_flight]
        mock_product.create.return_value = MagicMock(id="prod_hotel_new")
        
        products = StripeProductsService.initialize_products()
        
        assert products["flight"] == "prod_flight_old"
        assert products["hotel"] == "prod_hotel_new"

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_error(self, mock_product, mock_settings):
        """Test error handling during initialization."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_product.list.side_effect = Exception("Stripe down")
        
        products = StripeProductsService.initialize_products()
        assert products == {}
