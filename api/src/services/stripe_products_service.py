"""Service pour la gestion des produits Stripe."""

import stripe

from src.config.env import settings
from src.utils.logger import logger

# Cache des product IDs (initialisé au démarrage)
STRIPE_PRODUCT_IDS: dict[str, str] = {}


class StripeProductsService:
    """Service pour la gestion des produits Stripe."""

    @staticmethod
    def initialize_products() -> dict[str, str]:
        """
        Initialise les produits Stripe (flight) si ils n'existent pas.
        Retourne un dictionnaire avec les product IDs.
        """
        if not settings.STRIPE_SECRET_KEY:
            logger.warn("STRIPE_SECRET_KEY not set, skipping product initialization")
            return {}

        try:
            # Rechercher ou créer le produit Flight
            flight_product_id = StripeProductsService._get_or_create_product(
                name="Flight Booking",
                description="Flight booking service",
                metadata={"type": "flight"},
            )

            # Premium Subscription product + recurring price
            premium_price_id = StripeProductsService._get_or_create_subscription_price(
                product_name="BagTrip Premium",
                product_description="Premium subscription — unlimited AI, more viewers, offline notifications",
                product_metadata={"type": "premium_subscription"},
                unit_amount=999,  # 9.99 EUR/month
                currency="eur",
                interval="month",
            )

            product_ids = {
                "flight": flight_product_id,
                "premium_subscription": premium_price_id,
            }

            # Mettre à jour le cache global
            global STRIPE_PRODUCT_IDS
            STRIPE_PRODUCT_IDS = product_ids

            logger.info(f"Stripe products initialized: {product_ids}")
            return product_ids

        except Exception as e:
            logger.error(f"Failed to initialize Stripe products: {e}", exc_info=True)
            return {}

    @staticmethod
    def _get_or_create_product(name: str, description: str, metadata: dict) -> str:
        """
        Recherche un produit par metadata ou le crée s'il n'existe pas.
        """
        # Rechercher les produits existants avec le même type dans metadata
        product_type = metadata.get("type")
        if product_type:
            products = stripe.Product.list(limit=100, active=True)
            for product in products:
                if product.metadata.get("type") == product_type:
                    logger.info(f"Found existing Stripe product: {product.name} ({product.id})")
                    return product.id

        # Créer le produit s'il n'existe pas
        product = stripe.Product.create(
            name=name,
            description=description,
            metadata=metadata,
        )
        logger.info(f"Created new Stripe product: {product.name} ({product.id})")
        return product.id

    @staticmethod
    def _get_or_create_subscription_price(
        product_name: str,
        product_description: str,
        product_metadata: dict,
        unit_amount: int,
        currency: str,
        interval: str,
    ) -> str:
        """Get or create a recurring price for a subscription product."""
        product_id = StripeProductsService._get_or_create_product(
            name=product_name,
            description=product_description,
            metadata=product_metadata,
        )
        # Look for an existing recurring price on this product
        prices = stripe.Price.list(product=product_id, active=True, limit=10)
        for price in prices:
            if (
                price.recurring
                and price.recurring.interval == interval
                and price.unit_amount == unit_amount
                and price.currency == currency
            ):
                logger.info(f"Found existing price {price.id} for {product_name}")
                return price.id

        # Create a new recurring price
        price = stripe.Price.create(
            product=product_id,
            unit_amount=unit_amount,
            currency=currency,
            recurring={"interval": interval},
        )
        logger.info(f"Created new price {price.id} for {product_name}")
        return price.id

    @staticmethod
    def get_product_id(product_type: str) -> str | None:
        """
        Récupère le product ID depuis le cache.
        """
        return STRIPE_PRODUCT_IDS.get(product_type)
