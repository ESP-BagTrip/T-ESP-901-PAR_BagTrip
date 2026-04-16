"""Unit tests for StripeProductsService."""

from unittest.mock import MagicMock, patch

from src.services.stripe_products_service import StripeProductsService


class TestStripeProductsService:
    """Tests for StripeProductsService."""

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Price")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_success(self, mock_product, mock_price, mock_settings):
        """Test successful product initialization — creates flight + premium_subscription."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        # No existing products
        mock_product.list.return_value = []
        mock_product.create.side_effect = [
            MagicMock(id="prod_flight"),
            MagicMock(id="prod_premium"),
        ]

        # No existing prices for the premium subscription product
        mock_price.list.return_value = []
        mock_price.create.return_value = MagicMock(id="price_premium_monthly")

        products = StripeProductsService.initialize_products()

        assert products["flight"] == "prod_flight"
        assert products["premium_subscription"] == "price_premium_monthly"
        assert StripeProductsService.get_product_id("flight") == "prod_flight"
        assert (
            StripeProductsService.get_product_id("premium_subscription") == "price_premium_monthly"
        )

    @patch("src.services.stripe_products_service.settings")
    def test_initialize_products_no_key(self, mock_settings):
        """Test initialization skipped without key."""
        mock_settings.STRIPE_SECRET_KEY = None

        products = StripeProductsService.initialize_products()
        assert products == {}

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Price")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_existing(self, mock_product, mock_price, mock_settings):
        """Test finding existing products and prices."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"

        existing_flight = MagicMock(id="prod_flight_old")
        existing_flight.metadata = {"type": "flight"}

        existing_premium = MagicMock(id="prod_premium_old")
        existing_premium.metadata = {"type": "premium_subscription"}

        # Both product searches return the existing ones
        mock_product.list.return_value = [existing_flight, existing_premium]

        # An existing recurring price for the premium product
        existing_price = MagicMock(id="price_premium_old")
        existing_price.recurring = MagicMock(interval="month")
        existing_price.unit_amount = 999
        existing_price.currency = "eur"
        mock_price.list.return_value = [existing_price]

        products = StripeProductsService.initialize_products()

        assert products["flight"] == "prod_flight_old"
        assert products["premium_subscription"] == "price_premium_old"

    @patch("src.services.stripe_products_service.settings")
    @patch("src.services.stripe_products_service.stripe.Product")
    def test_initialize_products_error(self, mock_product, mock_settings):
        """Test error handling during initialization."""
        mock_settings.STRIPE_SECRET_KEY = "sk_test"
        mock_product.list.side_effect = Exception("Stripe down")

        products = StripeProductsService.initialize_products()
        assert products == {}
