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
        extra="ignore",
    )

    NODE_ENV: Literal["development", "test", "production"] = "development"
    PORT: int = 3000
    REQUEST_TIMEOUT_MS: int = 3000

    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/postgres"

    AMADEUS_CLIENT_ID: str
    AMADEUS_CLIENT_SECRET: str
    AMADEUS_BASE_URL: str = "https://test.api.amadeus.com"

    # LLM (OpenAI-compatible — default targets OVHcloud AI Endpoints)
    LLM_API_BASE: str = "https://oai.endpoints.kepler.ai.cloud.ovh.net/v1"
    LLM_API_KEY: str

    # Primary model + fallback chain. The router walks the chain on each
    # call and on transient errors (5xx / network / timeout). A model that
    # raises a non-retryable error (4xx other than 429, schema rejection)
    # is skipped to the next candidate in the chain. ``LLM_MODEL`` is kept
    # as a legacy alias for ``LLM_MODEL_PRIMARY``.
    LLM_MODEL_PRIMARY: str = "Mistral-Small-3.2-24B-Instruct-2506"
    LLM_MODEL_FALLBACKS: str = "Qwen3-32B,Meta-Llama-3_3-70B-Instruct"
    LLM_MODEL: str = "Mistral-Small-3.2-24B-Instruct-2506"  # legacy alias

    # Embedding model used by W3 RAG (post-trip suggestion).
    LLM_EMBEDDING_MODEL: str = "bge-m3"

    # In-process router knobs. The semaphore caps concurrent in-flight
    # calls per process so we stay under OVH's 400 RPM / project / model.
    # Retries use exponential backoff with jitter via tenacity.
    LLM_MAX_CONCURRENCY: int = 24
    LLM_RETRY_MAX_ATTEMPTS: int = 3
    LLM_RETRY_BACKOFF_BASE_S: float = 0.5
    LLM_RETRY_BACKOFF_MAX_S: float = 8.0

    # LangChain / LangSmith
    LANGCHAIN_TRACING_V2: bool = False
    LANGCHAIN_API_KEY: str | None = None
    LANGCHAIN_PROJECT: str = "BagTrip"

    # Stripe
    STRIPE_SECRET_KEY: str | None = Field(None, description="Stripe Secret Key")
    STRIPE_WEBHOOK_SECRET: str | None = Field(None, description="Stripe Webhook Secret")
    STRIPE_SUCCESS_URL: str = "bagtrip://subscription/success?session-id={CHECKOUT_SESSION_ID}"
    STRIPE_CANCEL_URL: str = "bagtrip://subscription/cancel"
    STRIPE_PORTAL_RETURN_URL: str = "bagtrip://profile"

    # Background jobs — disable per-job in test/dev when not needed.
    ENABLE_PLAN_EXPIRATION_JOB: bool = True
    ENABLE_ZOMBIE_PI_JOB: bool = True
    ENABLE_REFRESH_TOKEN_CLEANUP_JOB: bool = True

    # OpenTelemetry — distributed tracing.
    # When OTEL_EXPORTER_OTLP_ENDPOINT is set (e.g. `http://tempo:4317` in
    # production) the FastAPI / SQLAlchemy / Redis / HTTPX integrations export
    # spans to the configured collector. Leaving it empty disables tracing
    # (default for dev / test — keeps the test suite hermetic).
    OTEL_EXPORTER_OTLP_ENDPOINT: str | None = None
    OTEL_SERVICE_NAME: str = "bagtrip-api"
    OTEL_TRACES_SAMPLER_ARG: float = 1.0  # 0.0–1.0 ratio

    @field_validator("STRIPE_WEBHOOK_SECRET")
    @classmethod
    def validate_stripe_webhook_secret_in_prod(cls, v: str | None, info) -> str | None:
        """Block startup if Stripe webhook secret is missing in production."""
        node_env = info.data.get("NODE_ENV", "development")
        if node_env == "production" and (not v or not v.strip()):
            raise ValueError(
                "STRIPE_WEBHOOK_SECRET is required in production. "
                "Webhook signature verification cannot be disabled on live environments."
            )
        return v

    # Auth / JWT
    JWT_SECRET: str = "dev-secret-key-change-in-production"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    @field_validator("JWT_SECRET")
    @classmethod
    def validate_jwt_secret_not_default_in_prod(cls, v: str, info) -> str:
        """Block startup if JWT_SECRET is the default value in production."""
        node_env = info.data.get("NODE_ENV", "development")
        if node_env == "production" and v == "dev-secret-key-change-in-production":
            raise ValueError(
                "JWT_SECRET must be changed from the default value in production. "
                "Set a strong, unique secret in your environment variables."
            )
        return v

    # Firebase Admin (FCM push notifications)
    FIREBASE_SERVICE_ACCOUNT_PATH: str | None = None

    # Email (SMTP) — transactional mail (password reset). Disabled gracefully
    # when SMTP_HOST is unset: in dev the forgot-password route still exposes a
    # debug token, in prod the request succeeds silently (no leak) but no mail
    # is sent. Configure with any provider's SMTP credentials.
    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USERNAME: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str = "no-reply@bagtrip.fr"
    SMTP_USE_TLS: bool = True
    # Deep link the mobile app handles to open the reset-password screen.
    PASSWORD_RESET_URL_BASE: str = "bagtrip://reset-password"
    # Deep link the mobile app handles to confirm an email verification.
    EMAIL_VERIFICATION_URL_BASE: str = "bagtrip://verify-email"
    # Deep link the mobile app handles to accept a trip-share invitation.
    TRIP_INVITE_URL_BASE: str = "bagtrip://invite"

    # Cookie / CORS
    ALLOWED_ORIGINS: str = "http://localhost:8000"
    COOKIE_DOMAIN: str | None = None
    COOKIE_SECURE: bool = True
    # Prefix applied to auth cookie names so environments sharing a parent
    # domain (e.g. prod on bagtrip.fr + preprod on dev.bagtrip.fr) don't leak
    # each other's session cookies across JWT_SECRET boundaries.
    COOKIE_NAME_PREFIX: str = ""

    @field_validator("COOKIE_SECURE")
    @classmethod
    def validate_cookie_secure_in_prod(cls, v: bool, info) -> bool:
        """Block startup if cookies are not secure in production."""
        node_env = info.data.get("NODE_ENV", "development")
        if node_env == "production" and not v:
            raise ValueError(
                "COOKIE_SECURE must be True in production. "
                "Override only allowed in development/test environments."
            )
        return v

    # OAuth verification
    GOOGLE_FIREBASE_PROJECT_ID: str = "bagtrip-7d2d8"
    GOOGLE_OAUTH_CLIENT_ID: str | None = None
    APPLE_BUNDLE_ID: str | None = None

    # AirLabs (flight info)
    AIRLABS_API_KEY: str | None = None

    # Unsplash (cover images — legacy, kept for backward compat with old trips)
    UNSPLASH_ACCESS_KEY: str | None = None

    # SMP-330 — no-API-key cover images stored on local disk and re-served
    # via Caddy. Default dir is the docker volume mount point used in
    # ``compose.prod.yml``; the base URL is the Caddy-exposed path. Both are
    # overridable for local dev where the API runs outside docker.
    COVERS_STORAGE_DIR: str = "/var/lib/bagtrip/covers"
    COVERS_PUBLIC_URL_BASE: str = "https://bagtrip.fr/covers"
    # 7 days — destination cover images change rarely; the rehosted files
    # are content-addressed so re-picking is idempotent on the same source.
    COVERS_CACHE_TTL_SECONDS: int = 604_800

    # Open-Meteo (weather — free, no key required)
    OPEN_METEO_BASE_URL: str = "https://api.open-meteo.com"

    # Redis (optional — falls back to in-memory if not set)
    REDIS_URL: str | None = None

    # Open-Meteo geocoding (multilingual city → coords). Distinct host from
    # the weather API. Free, no API key. Used by LocationResolver as the
    # multilingual fallback when ``airportsdata`` (English-only) misses.
    OPEN_METEO_GEOCODING_BASE_URL: str = "https://geocoding-api.open-meteo.com"

    # AI graph timeouts (seconds)
    GRAPH_TIMEOUT_SECONDS: int = 300  # Global timeout for the trip planning graph
    # SMP-324 — bumped from 60 to 120s after measuring the OVH gpt-oss-120b
    # endpoint at ~50–60s on a cold ``destination_quick`` prompt; the
    # previous ceiling timed out at the slightest latency spike. Still well
    # under ``GRAPH_TIMEOUT_SECONDS`` so a stuck LLM cannot wedge the graph.
    LLM_CALL_TIMEOUT_SECONDS: int = 120  # Per-LLM-call timeout
    NODE_TIMEOUT_SECONDS: int = 180  # Per-node timeout in retry wrapper

    # ReAct JSON repair — when the LLM returns malformed JSON for a Final
    # Answer, the executor can fire one corrective re-prompt instead of
    # silently degrading to `{"raw_answer": ...}`. The budget guard
    # (`src.agent.runtime_budget`) still caps the cumulative wall time so a stuck LLM
    # can never double the total cost.
    REACT_JSON_REPAIR_ENABLED: bool = True
    REACT_JSON_REPAIR_MAX_ATTEMPTS: int = 1

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
        # Pydantic Settings pulls required fields from environment variables at
        # instantiation time; the explicit `call-arg` silence reflects that.
        return Settings()  # type: ignore[call-arg]
    except ValidationError as e:
        # `e.errors()` returns Pydantic v2 `ErrorDetails` which mypy types as
        # `list[ErrorDetails]`; our formatter accepts the same dict-shaped rows.
        error_message = _format_missing_env_error(e.errors())  # type: ignore[arg-type]
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
