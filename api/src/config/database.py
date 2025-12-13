"""Configuration SQLAlchemy pour PostgreSQL."""

import sys
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError, SQLAlchemyError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from src.config.env import settings


def clean_database_url(url: str) -> str:
    """
    Nettoie l'URL de base de données en retirant les paramètres non supportés par psycopg2.
    Retire notamment le paramètre 'schema' qui est utilisé par Prisma mais pas par psycopg2.
    """
    parsed = urlparse(url)
    query_params = parse_qs(parsed.query)

    # Retirer le paramètre 'schema' s'il existe
    if "schema" in query_params:
        del query_params["schema"]

    # Reconstruire l'URL sans le paramètre schema
    new_query = urlencode(query_params, doseq=True)
    cleaned_url = urlunparse(
        (parsed.scheme, parsed.netloc, parsed.path, parsed.params, new_query, parsed.fragment)
    )

    return cleaned_url


def _format_database_error(error: Exception, database_url: str) -> str:
    """Format database connection errors into a concise, user-friendly message."""
    error_msg = str(error).lower()

    # Parse database URL to extract connection info (without password)
    parsed = urlparse(database_url)
    host = parsed.hostname or "unknown"
    port = parsed.port or 5432
    database = parsed.path.lstrip("/") or "unknown"

    message_parts = []

    if "connection refused" in error_msg or "could not connect" in error_msg:
        message_parts.append("❌ Cannot connect to PostgreSQL database")
        message_parts.append(f"   Host: {host}:{port}")
        message_parts.append(f"   Database: {database}")
        message_parts.append("")
        message_parts.append("💡 Possible solutions:")
        message_parts.append("   1. Make sure PostgreSQL is running")
        message_parts.append("   2. Check if the database container is started: make db")
        message_parts.append("   3. Verify DATABASE_URL in your .env file")
        message_parts.append("   4. Check firewall/network settings")
    elif "authentication failed" in error_msg or "password" in error_msg:
        message_parts.append("❌ Database authentication failed")
        message_parts.append(f"   Host: {host}:{port}")
        message_parts.append(f"   Database: {database}")
        message_parts.append("")
        message_parts.append("💡 Check your DATABASE_URL credentials in .env file")
    elif "does not exist" in error_msg or "database" in error_msg:
        message_parts.append("❌ Database does not exist")
        message_parts.append(f"   Database: {database}")
        message_parts.append("")
        message_parts.append("💡 Create the database or update DATABASE_URL in .env")
    else:
        message_parts.append("❌ Database connection error")
        message_parts.append(f"   Error: {str(error)}")
        message_parts.append("")
        message_parts.append("💡 Check your DATABASE_URL configuration in .env file")

    return "\n".join(message_parts)


def _test_database_connection(engine) -> None:
    """Test database connectivity and raise a user-friendly error if it fails."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except OperationalError as e:
        error_message = _format_database_error(e, str(engine.url))
        print("\n" + "=" * 70, file=sys.stderr)
        print("DATABASE CONNECTION ERROR", file=sys.stderr)
        print("=" * 70, file=sys.stderr)
        print(error_message, file=sys.stderr)
        print("=" * 70 + "\n", file=sys.stderr)
        sys.exit(1)
    except SQLAlchemyError as e:
        error_message = _format_database_error(e, str(engine.url))
        print("\n" + "=" * 70, file=sys.stderr)
        print("DATABASE CONFIGURATION ERROR", file=sys.stderr)
        print("=" * 70, file=sys.stderr)
        print(error_message, file=sys.stderr)
        print("=" * 70 + "\n", file=sys.stderr)
        sys.exit(1)


# Nettoyer l'URL de connexion
database_url = clean_database_url(settings.DATABASE_URL)

# Création du moteur SQLAlchemy
engine = create_engine(
    database_url,
    pool_pre_ping=True,
    echo=False,  # Mettre à True pour voir les requêtes SQL en développement
    connect_args={"connect_timeout": 5},  # 5 secondes timeout
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base pour les modèles
Base = declarative_base()


def get_db():
    """Dépendance FastAPI pour obtenir une session DB."""
    db = SessionLocal()
    try:
        yield db
    except OperationalError as e:
        db.rollback()
        raise RuntimeError(
            "Database connection error. Please check if the database is running and accessible."
        ) from e
    finally:
        db.close()


def check_database_connection() -> None:
    """Check database connectivity at startup."""
    _test_database_connection(engine)
