"""Configuration de l'environnement avec validation Pydantic."""

import sys
from typing import Literal

from dotenv import load_dotenv
from pydantic import Field, ValidationError, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Charger les variables d'environnement depuis .env
load_dotenv()


class Settings(BaseSettings):
    """Configuration de l'application."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    NODE_ENV: Literal["development", "test", "production"] = "development"
    PORT: int = 3000
    REQUEST_TIMEOUT_MS: int = 3000

    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/postgres"

    AMADEUS_CLIENT_ID: str
    AMADEUS_CLIENT_SECRET: str
    AMADEUS_BASE_URL: str = "https://test.api.amadeus.com"

    # LLM (OpenAI-compatible)
    LLM_MODEL: str = "gpt-oss-120b"
    LLM_API_BASE: str = "https://oai.endpoints.kepler.ai.cloud.ovh.net/v1"
    LLM_API_KEY: str

    # LangChain / LangSmith
    LANGCHAIN_TRACING_V2: bool = False
    LANGCHAIN_API_KEY: str | None = None
    LANGCHAIN_PROJECT: str = "BagTrip"

    # Stripe
    STRIPE_SECRET_KEY: str | None = Field(None, description="Stripe Secret Key")
    STRIPE_WEBHOOK_SECRET: str | None = Field(None, description="Stripe Webhook Secret")

    # Auth / JWT
    JWT_SECRET: str = "dev-secret-key-change-in-production"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Firebase Admin (FCM push notifications)
    FIREBASE_SERVICE_ACCOUNT_PATH: str | None = None

    # Cookie / CORS
    ALLOWED_ORIGINS: str = "http://localhost:8000"
    COOKIE_DOMAIN: str | None = None
    COOKIE_SECURE: bool = False

    # OAuth verification
    GOOGLE_FIREBASE_PROJECT_ID: str = "bagtrip-7d2d8"
    GOOGLE_OAUTH_CLIENT_ID: str | None = None
    APPLE_BUNDLE_ID: str | None = None

    @field_validator("AMADEUS_CLIENT_ID", "AMADEUS_CLIENT_SECRET", "LLM_API_KEY")
    @classmethod
    def validate_required_strings(cls, v: str) -> str:
        """Validate that required API keys are not empty."""
        if not v or not v.strip():
            raise ValueError("This field cannot be empty")
        return v


def _format_missing_env_error(errors: list[dict]) -> str:
    """Format validation errors into a concise, user-friendly message."""
    missing_vars = []
    invalid_vars = []

    for error in errors:
        field = error.get("loc", [])[-1] if error.get("loc") else "unknown"
        error_type = error.get("type", "")
        error_msg = error.get("msg", "")

        if error_type == "missing":
            missing_vars.append(field.upper())
        else:
            invalid_vars.append(f"{field.upper()}: {error_msg}")

    message_parts = []

    if missing_vars:
        message_parts.append(
            f"❌ Missing required environment variables:\n   {', '.join(missing_vars)}"
        )

    if invalid_vars:
        message_parts.append("❌ Invalid environment variables:\n   " + "\n   ".join(invalid_vars))

    if message_parts:
        message_parts.append(
            "\n💡 Please check your .env file or set these variables in your environment."
        )
        message_parts.append(
            "   You can copy .env.example to .env and fill in the required values."
        )

    return "\n".join(message_parts)


def _load_settings() -> Settings:
    """Load and validate settings with improved error handling."""
    try:
        return Settings()
    except ValidationError as e:
        error_message = _format_missing_env_error(e.errors())
        print("\n" + "=" * 70, file=sys.stderr)
        print("ENVIRONMENT CONFIGURATION ERROR", file=sys.stderr)
        print("=" * 70, file=sys.stderr)
        print(error_message, file=sys.stderr)
        print("=" * 70 + "\n", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(
            f"\n❌ Failed to load environment configuration: {e}",
            file=sys.stderr,
        )
        sys.exit(1)


settings = _load_settings()
