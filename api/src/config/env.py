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


settings = Settings()
