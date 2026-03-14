"""Seed: création d'admins par défaut au démarrage."""

import os

import bcrypt
from sqlalchemy.orm import Session

from src.config.database import SessionLocal
from src.models.user import User
from src.utils.logger import logger

ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@bagtrip.com")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD")
ADMIN_FULL_NAME = os.environ.get("ADMIN_FULL_NAME", "Admin BagTrip")

DEV_ADMINS = [
    {"email": "yanis@bagtrip.com", "password": "yanis123", "full_name": "Yanis"},
    {"email": "mickael@bagtrip.com", "password": "mickael123", "full_name": "Mickael"},
    {"email": "jean@bagtrip.com", "password": "jean123", "full_name": "Jean"},
    {"email": "aurelien@bagtrip.com", "password": "aurelien123", "full_name": "Aurelien"},
    {"email": "adrien@bagtrip.com", "password": "adrien123", "full_name": "Adrien"},
]


def _upsert_admin(db: Session, email: str, password: str, full_name: str) -> None:
    """Crée ou met à jour un admin. Idempotent."""
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        if existing.plan != "ADMIN":
            existing.plan = "ADMIN"
            logger.info(f"Admin upgraded to ADMIN plan ({email})")
        else:
            logger.info(f"Admin already exists ({email})")
        return

    password_hash = bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    db.add(User(
        email=email,
        password_hash=password_hash,
        full_name=full_name,
        plan="ADMIN",
    ))
    logger.info(f"Admin created ({email})")


def _seed_dev_admins() -> None:
    """Seed les 5 admins dev (uniquement en développement)."""
    db: Session = SessionLocal()
    try:
        for admin in DEV_ADMINS:
            _upsert_admin(db, admin["email"], admin["password"], admin["full_name"])
        db.commit()
    except Exception as e:
        db.rollback()
        logger.warning(f"Failed to seed dev admins: {e}")
    finally:
        db.close()


def create_default_admin() -> None:
    """Crée les utilisateurs admin par défaut."""
    from src.config.env import settings

    # En dev, seed les 5 admins dev
    if settings.NODE_ENV == "development":
        _seed_dev_admins()

    # Logique env-var existante (backward compat, utile en prod)
    if not ADMIN_PASSWORD:
        if settings.NODE_ENV != "development":
            logger.info("ADMIN_PASSWORD not set, skipping admin seed")
        return

    db: Session = SessionLocal()
    try:
        _upsert_admin(db, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_FULL_NAME)
        db.commit()
    except Exception as e:
        db.rollback()
        logger.warning(f"Failed to create default admin: {e}")
    finally:
        db.close()
