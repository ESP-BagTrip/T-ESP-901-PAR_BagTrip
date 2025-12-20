"""Configuration de l'environnement avec validation Pydantic."""

from typing import Literal

from dotenv import load_dotenv
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

    # Google GenAI
    GOOGLE_API_KEY: str

    # LangChain / LangSmith
    LANGCHAIN_TRACING_V2: bool = False
    LANGCHAIN_API_KEY: str | None = None
    LANGCHAIN_PROJECT: str = "default"

    # Stripe
    STRIPE_SECRET_KEY: str | None = Field(None, description="Stripe Secret Key")
    STRIPE_WEBHOOK_SECRET: str | None = Field(None, description="Stripe Webhook Secret")

    @field_validator("AMADEUS_CLIENT_ID", "AMADEUS_CLIENT_SECRET", "GOOGLE_API_KEY")
    @classmethod
    def validate_required_strings(cls, v: str) -> str:
        """Validate that required API keys are not empty."""
        return _validate_non_empty(v)


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
