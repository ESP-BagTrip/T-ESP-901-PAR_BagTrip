"""Cache d'idempotence pour éviter les appels dupliqués aux outils.

Uses Redis when REDIS_URL is configured, with automatic fallback to in-memory.
"""

import hashlib
import json
import threading
from datetime import datetime, timedelta
from typing import Any

from src.utils.logger import logger


class IdempotencyCache:
    """Cache pour éviter les appels dupliqués. Redis si disponible, sinon mémoire."""

    def __init__(self, ttl_seconds: int = 300):
        self.ttl_seconds = ttl_seconds
        self._redis = None
        self._memory_cache: dict[str, tuple[Any, datetime]] = {}
        self._lock = threading.Lock()
        self._init_backend()

    def _init_backend(self):
        """Try to connect to Redis; fall back to in-memory on failure."""
        from src.config.env import settings

        if not settings.REDIS_URL:
            logger.info("IdempotencyCache using in-memory backend (REDIS_URL not set)")
            return

        try:
            import redis as redis_lib

            self._redis = redis_lib.from_url(
                settings.REDIS_URL,
                decode_responses=True,
            )
            self._redis.ping()
            logger.info("IdempotencyCache using Redis backend")
        except Exception as e:
            logger.warn(f"Redis unavailable, falling back to in-memory: {e}")
            self._redis = None

    def _generate_key(self, tool_name: str, params: dict[str, Any]) -> str:
        """Génère une clé unique basée sur le nom de l'outil et ses paramètres."""
        normalized = json.dumps(params, sort_keys=True, default=str)
        key_string = f"{tool_name}:{normalized}"
        return hashlib.sha256(key_string.encode()).hexdigest()

    def get(self, tool_name: str, params: dict[str, Any]) -> Any | None:
        """Récupère le résultat d'un appel précédent."""
        key = self._generate_key(tool_name, params)

        if self._redis:
            try:
                raw = self._redis.get(f"idempotency:{key}")
                if raw is not None:
                    logger.info(f"Cache hit (Redis) for {tool_name} with key {key[:8]}...")
                    return json.loads(raw)
                return None
            except Exception:
                return self._memory_get(key, tool_name)

        return self._memory_get(key, tool_name)

    def set(self, tool_name: str, params: dict[str, Any], result: Any):
        """Stocke le résultat d'un appel."""
        key = self._generate_key(tool_name, params)

        if self._redis:
            try:
                self._redis.setex(
                    f"idempotency:{key}",
                    self.ttl_seconds,
                    json.dumps(result, default=str),
                )
                return
            except Exception:
                pass  # Fallback to memory

        self._memory_set(key, result)

    def _memory_get(self, key: str, tool_name: str) -> Any | None:
        """In-memory cache lookup."""
        with self._lock:
            if key in self._memory_cache:
                result, timestamp = self._memory_cache[key]
                if datetime.utcnow() - timestamp < timedelta(seconds=self.ttl_seconds):
                    logger.info(f"Cache hit (memory) for {tool_name} with key {key[:8]}...")
                    return result
                del self._memory_cache[key]
        return None

    def _memory_set(self, key: str, result: Any):
        """In-memory cache store."""
        with self._lock:
            self._memory_cache[key] = (result, datetime.utcnow())
            self._cleanup()

    def _cleanup(self):
        """Nettoie les entrées expirées (in-memory only)."""
        now = datetime.utcnow()
        expired_keys = [
            key
            for key, (_, timestamp) in self._memory_cache.items()
            if now - timestamp >= timedelta(seconds=self.ttl_seconds)
        ]
        for key in expired_keys:
            del self._memory_cache[key]


# Instance globale — utilise Redis si REDIS_URL est configuré, sinon mémoire
idempotency_cache = IdempotencyCache(ttl_seconds=300)
