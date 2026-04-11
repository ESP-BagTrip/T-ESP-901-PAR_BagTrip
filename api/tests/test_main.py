"""Unit tests for the main application entry point."""

import contextlib
import sys
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

# Mock StripeProductsService before importing main
with patch("src.services.stripe_products_service.StripeProductsService") as mock_stripe_service:
    from src.main import app, lifespan
    from src.utils.errors import AppError
    from src.utils.logger import LogLevel, logger


@pytest.fixture(autouse=True)
def mock_db_connection():
    """Mock database connection check to prevent real connection attempts."""
    with patch("src.main.check_database_connection"):
        yield


@pytest.fixture
def client():
    """Provide a test client for the app."""
    # We need to mock lifespan migrations as they run on startup
    with (
        patch("src.migrations.migrate_trips_table.migrate_trips_table"),
        patch("src.services.stripe_products_service.StripeProductsService.initialize_products"),
        patch("src.seeds.create_admin.create_default_admin"),
        TestClient(app, raise_server_exceptions=False) as client,
    ):
        # raise_server_exceptions=False allows testing 500 responses
        yield client


class TestMainEndpoints:
    """Tests for main endpoints."""

    def test_root(self, client):
        """Test root endpoint."""
        response = client.get("/")
        assert response.status_code == 200
        assert response.json() == {"message": "BagTrip API", "version": "1.0.0"}

    def test_health(self, client):
        """Test health endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


class TestExceptionHandlers:
    """Tests for exception handlers."""

    def test_app_error_handler(self, client):
        """Test handling of AppError."""

        # Define a route that raises AppError
        @app.get("/test-app-error")
        def raise_app_error():
            raise AppError("TEST_ERROR", 400, "Test error message", {"foo": "bar"})

        response = client.get("/test-app-error")
        assert response.status_code == 400
        data = response.json()
        assert data["detail"]["code"] == "TEST_ERROR"
        assert data["detail"]["error"] == "Test error message"
        assert data["detail"]["foo"] == "bar"

    def test_app_error_handler_debug_logging(self, client):
        """Test AppError logging in DEBUG mode."""
        original_level = logger.level
        logger.level = LogLevel.DEBUG

        try:
            with patch.object(logger, "error") as mock_log:

                @app.get("/test-app-error-debug")
                def raise_app_error_debug():
                    raise AppError("TEST_ERROR", 400, "Test error message")

                client.get("/test-app-error-debug")
                mock_log.assert_called()
                args, _ = mock_log.call_args
                assert "AppError: TEST_ERROR" in args[0]
        finally:
            logger.level = original_level

    def test_general_exception_handler(self, client):
        """Test handling of generic Exception."""

        @app.get("/test-general-error")
        def raise_general_error():
            raise ValueError("Something went wrong")

        # In non-debug mode (default for tests usually unless set otherwise)
        with patch.object(logger, "level", LogLevel.INFO):
            response = client.get("/test-general-error")
            assert response.status_code == 500
            assert response.json() == {
                "error": "Internal server error",
                "detail": "Something went wrong",
            }

    def test_general_exception_handler_debug(self, client):
        """Test handling of generic Exception in DEBUG mode."""
        original_level = logger.level
        logger.level = LogLevel.DEBUG

        try:

            @app.get("/test-general-error-debug")
            def raise_general_error_debug():
                raise ValueError("Debug error")

            response = client.get("/test-general-error-debug")
            assert response.status_code == 500
            data = response.json()
            assert data["error"] == "Internal server error"
            assert isinstance(data["detail"], dict)
            assert data["detail"]["error"] == "Debug error"
            assert "traceback" in data["detail"]
        finally:
            logger.level = original_level


class TestLifespan:
    """Tests for application lifespan events."""

    @pytest.mark.asyncio
    async def test_lifespan_success(self):
        """Test successful startup and shutdown."""
        app_mock = MagicMock()

        with (
            patch("src.main.check_database_connection") as mock_check_db,
            patch("src.migrations.migrate_trips_table.migrate_trips_table") as mock_migrate_trips,
            patch(
                "src.services.stripe_products_service.StripeProductsService.initialize_products"
            ) as mock_stripe_init,
            patch("src.seeds.create_admin.create_default_admin") as mock_create_admin,
        ):
            async with lifespan(app_mock):
                pass

            mock_check_db.assert_called_once()
            mock_migrate_trips.assert_called_once()
            mock_stripe_init.assert_called_once()
            mock_create_admin.assert_called_once()

    @pytest.mark.asyncio
    async def test_lifespan_migration_errors(self):
        """Test lifespan handles migration errors gracefully."""
        app_mock = MagicMock()

        with (
            patch("src.main.check_database_connection"),
            patch(
                "src.migrations.migrate_trips_table.migrate_trips_table",
                side_effect=Exception("Trips migration failed"),
            ),
            patch(
                "src.services.stripe_products_service.StripeProductsService.initialize_products",
                side_effect=Exception("Stripe init failed"),
            ),
            patch(
                "src.seeds.create_admin.create_default_admin",
                side_effect=Exception("Admin seed failed"),
            ),
        ):
            # Should not raise exception
            async with lifespan(app_mock):
                pass


class TestMainBlock:
    """Tests for the main execution block."""

    def test_main_execution(self):
        """Test execution when run as script."""
        with patch("uvicorn.run") as mock_run:
            import runpy

            from src.config.env import settings

            with (
                patch.object(sys, "argv", ["main.py"]),
                patch("src.main.app", MagicMock()),
                contextlib.suppress(SystemExit),
            ):
                # Mock app to avoid side effects during re-import
                runpy.run_module("src.main", run_name="__main__")

            mock_run.assert_called_once()
            args, kwargs = mock_run.call_args
            assert args[0] == "src.main:app"
            assert kwargs["host"] == "0.0.0.0"
            assert kwargs["port"] == settings.PORT
