"""Configuration SQLAlchemy pour PostgreSQL."""

from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from sqlalchemy import create_engine, text
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


# Nettoyer l'URL de connexion
database_url = clean_database_url(settings.DATABASE_URL)

# Création du moteur SQLAlchemy
engine = create_engine(
    database_url,
    pool_pre_ping=True,
    echo=False,  # Mettre à True pour voir les requêtes SQL en développement
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base pour les modèles
Base = declarative_base()


def check_database_connection():
    """Vérifie la connexion à la base de données."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as e:
        raise ConnectionError(f"Failed to connect to database: {e}") from e


def get_db():
    """Dépendance FastAPI pour obtenir une session DB."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
