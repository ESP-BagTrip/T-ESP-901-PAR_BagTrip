"""Firebase Admin SDK initialization (graceful degradation if not configured)."""

import firebase_admin
from firebase_admin import credentials

from src.config.env import settings
from src.utils.logger import logger

_app: firebase_admin.App | None = None


def get_firebase_app() -> firebase_admin.App | None:
    """Return the initialized Firebase app, or None if unavailable."""
    return _app


def _init_firebase() -> None:
    global _app
    path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
    if not path:
        logger.warn(
            "[FIREBASE] FIREBASE_SERVICE_ACCOUNT_PATH not set — push notifications disabled"
        )
        return
    try:
        cred = credentials.Certificate(path)
        _app = firebase_admin.initialize_app(cred)
        logger.info("[FIREBASE] Initialized successfully")
    except Exception as e:
        logger.error(f"[FIREBASE] Init failed: {e}")
        _app = None


_init_firebase()
