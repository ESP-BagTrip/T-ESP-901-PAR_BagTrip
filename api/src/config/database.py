"""Configuration SQLAlchemy pour PostgreSQL."""

from urllib.parse import parse_qs, urlencode, urlparse, urlunparse

from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker

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

# Création du moteur SQLAlchemy.
#
# Pool tuning:
#  - pool_size=20        → 20 persistent connections per worker (SQLAlchemy default 5
#                          is too low for the fan-out we do on home/trip detail endpoints).
#  - max_overflow=10     → up to 10 extra connections under burst before blocking.
#  - pool_timeout=30     → block at most 30s waiting for a free connection.
#  - pool_recycle=1800   → recycle connections every 30 minutes to dodge upstream
#                          idle-timeout kills (NAT, PGBouncer, RDS, …).
#  - pool_pre_ping=True  → `SELECT 1` before handing out a connection so we fail
#                          fast on broken sockets instead of serving 500s.
engine = create_engine(
    database_url,
    pool_size=20,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,
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
