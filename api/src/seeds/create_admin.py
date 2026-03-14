"""Seed: création d'un admin par défaut au démarrage."""

import os

import bcrypt
from sqlalchemy.orm import Session

from src.config.database import SessionLocal
from src.models.user import User
from src.utils.logger import logger

ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@bagtrip.com")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD")
ADMIN_FULL_NAME = os.environ.get("ADMIN_FULL_NAME", "Admin BagTrip")


def create_default_admin() -> None:
    """Crée un utilisateur admin par défaut s'il n'existe pas encore."""
    if not ADMIN_PASSWORD:
        logger.info("ADMIN_PASSWORD not set, skipping admin seed")
        return

    db: Session = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == ADMIN_EMAIL).first()
        if existing:
            if existing.plan != "ADMIN":
                existing.plan = "ADMIN"
                db.commit()
                logger.info(f"Default admin upgraded to ADMIN plan ({ADMIN_EMAIL})")
            else:
                logger.info(f"Default admin already exists ({ADMIN_EMAIL})")
            return

        password_hash = bcrypt.hashpw(
            ADMIN_PASSWORD.encode("utf-8"),
            bcrypt.gensalt(),
        ).decode("utf-8")

        admin = User(
            email=ADMIN_EMAIL,
            password_hash=password_hash,
            full_name=ADMIN_FULL_NAME,
            plan="ADMIN",
        )
        db.add(admin)
        db.commit()
        logger.info(f"Default admin created ({ADMIN_EMAIL})")
    except Exception as e:
        db.rollback()
        logger.warn(f"Failed to create default admin: {e}")
    finally:
        db.close()
