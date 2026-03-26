"""Cache d'idempotence pour éviter les appels dupliqués aux outils."""

import hashlib
import json
import threading
from datetime import datetime, timedelta
from typing import Any

from src.utils.logger import logger


class IdempotencyCache:
    """Cache simple pour éviter les appels dupliqués."""

    def __init__(self, ttl_seconds: int = 300):  # 5 minutes
        self.ttl_seconds = ttl_seconds
        self.cache: dict[str, tuple[Any, datetime]] = {}
        self._lock = threading.Lock()

    def _generate_key(self, tool_name: str, params: dict[str, Any]) -> str:
        """Génère une clé unique basée sur le nom de l'outil et ses paramètres."""
        # Normaliser les paramètres (trier les clés, convertir en JSON)
        normalized = json.dumps(params, sort_keys=True, default=str)
        key_string = f"{tool_name}:{normalized}"
        return hashlib.sha256(key_string.encode()).hexdigest()

    def get(self, tool_name: str, params: dict[str, Any]) -> Any | None:
        """Récupère le résultat d'un appel précédent."""
        key = self._generate_key(tool_name, params)

        with self._lock:
            if key in self.cache:
                result, timestamp = self.cache[key]
                # Vérifier TTL
                if datetime.utcnow() - timestamp < timedelta(seconds=self.ttl_seconds):
                    logger.info(f"Cache hit for {tool_name} with key {key[:8]}...")
                    return result
                else:
                    # Expiré, supprimer
                    del self.cache[key]

        return None

    def set(self, tool_name: str, params: dict[str, Any], result: Any):
        """Stocke le résultat d'un appel."""
        key = self._generate_key(tool_name, params)

        with self._lock:
            self.cache[key] = (result, datetime.utcnow())

            # Nettoyer les entrées expirées (simple cleanup)
            self._cleanup()

    def _cleanup(self):
        """Nettoie les entrées expirées."""
        now = datetime.utcnow()
        expired_keys = [
            key
            for key, (_, timestamp) in self.cache.items()
            if now - timestamp >= timedelta(seconds=self.ttl_seconds)
        ]
        for key in expired_keys:
            del self.cache[key]


# Instance globale (pour POC, en production utiliser Redis)
idempotency_cache = IdempotencyCache(ttl_seconds=300)
