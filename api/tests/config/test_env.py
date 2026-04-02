"""Unit tests for the environment configuration."""

import os
from unittest.mock import MagicMock, patch

import pytest
from pydantic import ValidationError

from src.config.env import Settings, _format_missing_env_error, _load_settings


@pytest.fixture
def mock_env_vars():
    """Set up valid environment variables for testing."""
    env_vars = {
        "AMADEUS_CLIENT_ID": "test_id",
        "AMADEUS_CLIENT_SECRET": "test_secret",
        "LLM_API_KEY": "test_llm_key",
        "DATABASE_URL": "postgresql://postgres:postgres@localhost:5432/postgres",
    }
    with patch.dict(os.environ, env_vars, clear=True):
        yield


class TestSettings:
    """Tests for the Settings class."""

    def test_settings_validation_success(self, mock_env_vars):
        """Test successful settings loading with valid env vars."""
        settings = Settings()
        assert settings.AMADEUS_CLIENT_ID == "test_id"
        assert settings.AMADEUS_CLIENT_SECRET == "test_secret"
        assert settings.LLM_API_KEY == "test_llm_key"
        assert settings.DATABASE_URL == "postgresql://postgres:postgres@localhost:5432/postgres"
        # Check defaults
        assert settings.NODE_ENV == "development"
        assert settings.PORT == 3000
        # Check new defaults (Redis + timeouts)
        assert settings.REDIS_URL is None
        assert settings.GRAPH_TIMEOUT_SECONDS == 300
        assert settings.LLM_CALL_TIMEOUT_SECONDS == 60
        assert settings.NODE_TIMEOUT_SECONDS == 120

    def test_settings_validation_missing_required(self):
        """Test validation fails when required vars are missing."""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(ValidationError) as exc_info:
                Settings()

            errors = exc_info.value.errors()
            missing_fields = [e["loc"][0] for e in errors if e["type"] == "missing"]
            assert "AMADEUS_CLIENT_ID" in missing_fields
            assert "AMADEUS_CLIENT_SECRET" in missing_fields
            assert "LLM_API_KEY" in missing_fields

    def test_settings_validation_empty_string(self, mock_env_vars):
        """Test validation fails for empty strings in required fields."""
        with patch.dict(os.environ, {"AMADEUS_CLIENT_ID": ""}):
            with pytest.raises(ValidationError) as exc_info:
                Settings()
            assert "This field cannot be empty" in str(exc_info.value)

    def test_settings_optional_fields(self, mock_env_vars):
        """Test optional fields logic."""
        with patch.dict(os.environ, {
            "STRIPE_SECRET_KEY": "sk_test_123",
            "LANGCHAIN_API_KEY": "lc_123"
        }):
            settings = Settings()
            assert settings.STRIPE_SECRET_KEY == "sk_test_123"
            assert settings.LANGCHAIN_API_KEY == "lc_123"

    def test_settings_redis_and_timeouts_overridable(self, mock_env_vars):
        """Test that Redis URL and timeout settings can be overridden."""
        with patch.dict(os.environ, {
            "REDIS_URL": "redis://myredis:6379/1",
            "GRAPH_TIMEOUT_SECONDS": "600",
            "LLM_CALL_TIMEOUT_SECONDS": "90",
            "NODE_TIMEOUT_SECONDS": "180",
        }):
            settings = Settings()
            assert settings.REDIS_URL == "redis://myredis:6379/1"
            assert settings.GRAPH_TIMEOUT_SECONDS == 600
            assert settings.LLM_CALL_TIMEOUT_SECONDS == 90
            assert settings.NODE_TIMEOUT_SECONDS == 180


class TestJwtSecretValidation:
    """Tests for JWT_SECRET production validation."""

    def test_jwt_secret_default_allowed_in_development(self, mock_env_vars):
        """Test that the default JWT_SECRET is allowed in development."""
        with patch.dict(os.environ, {"NODE_ENV": "development", "LLM_API_KEY": "test_key"}):
            settings = Settings()
            assert settings.JWT_SECRET == "dev-secret-key-change-in-production"

    def test_jwt_secret_default_blocked_in_production(self, mock_env_vars):
        """Test that the default JWT_SECRET is rejected in production."""
        with patch.dict(os.environ, {"NODE_ENV": "production", "LLM_API_KEY": "test_key"}):
            with pytest.raises(ValidationError) as exc_info:
                Settings()
            assert "JWT_SECRET must be changed" in str(exc_info.value)

    def test_jwt_secret_custom_allowed_in_production(self, mock_env_vars):
        """Test that a custom JWT_SECRET is allowed in production."""
        with patch.dict(os.environ, {
            "NODE_ENV": "production",
            "JWT_SECRET": "my-strong-production-secret-key-2026",
            "LLM_API_KEY": "test_key",
        }):
            settings = Settings()
            assert settings.JWT_SECRET == "my-strong-production-secret-key-2026"


class TestFormatError:
    """Tests for error formatting helper."""

    def test_format_missing_env_error(self):
        """Test formatting of missing variables error."""
        errors = [
            {"type": "missing", "loc": ("AMADEUS_CLIENT_ID",), "msg": "Field required"},
            {"type": "missing", "loc": ("LLM_API_KEY",), "msg": "Field required"},
        ]
        message = _format_missing_env_error(errors)
        assert "Missing required environment variables" in message
        assert "AMADEUS_CLIENT_ID" in message
        assert "LLM_API_KEY" in message

    def test_format_invalid_env_error(self):
        """Test formatting of invalid variables error."""
        errors = [
            {"type": "value_error", "loc": ("PORT",), "msg": "Input should be a valid integer"},
        ]
        message = _format_missing_env_error(errors)
        assert "Invalid environment variables" in message
        assert "PORT: Input should be a valid integer" in message

    def test_format_mixed_errors(self):
        """Test formatting of both missing and invalid variables."""
        errors = [
            {"type": "missing", "loc": ("AMADEUS_CLIENT_ID",), "msg": "Field required"},
            {"type": "value_error", "loc": ("PORT",), "msg": "Input should be a valid integer"},
        ]
        message = _format_missing_env_error(errors)
        assert "Missing required environment variables" in message
        assert "Invalid environment variables" in message


class TestLoadSettings:
    """Tests for _load_settings function."""

    @patch("src.config.env.Settings")
    def test_load_settings_success(self, mock_settings_cls):
        """Test successful loading."""
        mock_instance = MagicMock()
        mock_settings_cls.return_value = mock_instance
        
        result = _load_settings()
        assert result == mock_instance

    @patch("src.config.env.Settings")
    def test_load_settings_validation_error(self, mock_settings_cls):
        """Test loading with validation error exits the program."""
        mock_settings_cls.side_effect = ValidationError.from_exception_data("Settings", [])
        
        with pytest.raises(SystemExit) as exc_info:
            _load_settings()
        assert exc_info.value.code == 1

    @patch("src.config.env.Settings")
    def test_load_settings_generic_error(self, mock_settings_cls):
        """Test loading with generic error exits the program."""
        mock_settings_cls.side_effect = Exception("Unknown error")
        
        with pytest.raises(SystemExit) as exc_info:
            _load_settings()
        assert exc_info.value.code == 1
