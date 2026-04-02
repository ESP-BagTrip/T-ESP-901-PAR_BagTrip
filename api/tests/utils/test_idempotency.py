"""Tests for IdempotencyCache — in-memory and Redis backends."""

from __future__ import annotations

import json
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest

from src.utils.idempotency import IdempotencyCache


@pytest.fixture
def memory_cache():
    """IdempotencyCache with no Redis (in-memory only)."""
    with patch("src.config.env.settings", MagicMock(REDIS_URL=None)):
        cache = IdempotencyCache(ttl_seconds=60)
    return cache


class TestIdempotencyCacheMemory:
    def test_get_returns_none_for_unknown_key(self, memory_cache):
        assert memory_cache.get("tool", {"k": "v"}) is None

    def test_set_then_get_returns_value(self, memory_cache):
        memory_cache.set("resolve_iata_code", {"city": "Paris"}, {"iata": "CDG"})
        result = memory_cache.get("resolve_iata_code", {"city": "Paris"})
        assert result == {"iata": "CDG"}

    def test_different_params_different_keys(self, memory_cache):
        memory_cache.set("tool", {"city": "Paris"}, "result_paris")
        memory_cache.set("tool", {"city": "Tokyo"}, "result_tokyo")
        assert memory_cache.get("tool", {"city": "Paris"}) == "result_paris"
        assert memory_cache.get("tool", {"city": "Tokyo"}) == "result_tokyo"

    def test_different_tools_different_keys(self, memory_cache):
        memory_cache.set("tool_a", {"k": "v"}, "a")
        memory_cache.set("tool_b", {"k": "v"}, "b")
        assert memory_cache.get("tool_a", {"k": "v"}) == "a"
        assert memory_cache.get("tool_b", {"k": "v"}) == "b"

    def test_param_order_does_not_matter(self, memory_cache):
        """Keys are normalized (sorted) so param order is irrelevant."""
        memory_cache.set("tool", {"b": 2, "a": 1}, "result")
        assert memory_cache.get("tool", {"a": 1, "b": 2}) == "result"

    def test_expired_entry_returns_none(self, memory_cache):
        memory_cache.set("tool", {"k": "v"}, "result")
        # Manually expire the entry
        for key in memory_cache._memory_cache:
            val, _ = memory_cache._memory_cache[key]
            memory_cache._memory_cache[key] = (val, datetime.utcnow() - timedelta(seconds=120))
        assert memory_cache.get("tool", {"k": "v"}) is None

    def test_cleanup_removes_expired(self, memory_cache):
        memory_cache.set("tool", {"k": "old"}, "old_result")
        # Expire it
        for key in list(memory_cache._memory_cache):
            val, _ = memory_cache._memory_cache[key]
            memory_cache._memory_cache[key] = (val, datetime.utcnow() - timedelta(seconds=120))
        # Setting a new key triggers cleanup
        memory_cache.set("tool", {"k": "new"}, "new_result")
        assert len(memory_cache._memory_cache) == 1

    def test_generate_key_is_deterministic(self, memory_cache):
        key1 = memory_cache._generate_key("tool", {"a": 1})
        key2 = memory_cache._generate_key("tool", {"a": 1})
        assert key1 == key2


class TestIdempotencyCacheRedis:
    def _make_redis_cache(self, mock_redis):
        """Create an IdempotencyCache with a mocked Redis backend."""
        with patch("src.config.env.settings", MagicMock(REDIS_URL="redis://localhost:6379/0")):
            with patch("redis.from_url", return_value=mock_redis):
                cache = IdempotencyCache(ttl_seconds=60)
        return cache

    def test_get_from_redis(self):
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True
        mock_redis.get.return_value = json.dumps({"iata": "CDG"})

        cache = self._make_redis_cache(mock_redis)
        result = cache.get("resolve_iata_code", {"city": "Paris"})

        assert result == {"iata": "CDG"}
        mock_redis.get.assert_called_once()
        call_key = mock_redis.get.call_args[0][0]
        assert call_key.startswith("idempotency:")

    def test_get_cache_miss_returns_none(self):
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True
        mock_redis.get.return_value = None

        cache = self._make_redis_cache(mock_redis)
        assert cache.get("tool", {"k": "v"}) is None

    def test_set_uses_setex_with_ttl(self):
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True

        cache = self._make_redis_cache(mock_redis)
        cache.set("tool", {"k": "v"}, {"result": True})

        mock_redis.setex.assert_called_once()
        args = mock_redis.setex.call_args
        assert args[0][0].startswith("idempotency:")
        assert args[0][1] == 60  # TTL
        assert json.loads(args[0][2]) == {"result": True}

    def test_redis_get_failure_falls_back_to_memory(self):
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True
        mock_redis.get.side_effect = ConnectionError("Redis down")

        cache = self._make_redis_cache(mock_redis)
        # Pre-populate memory cache
        cache._memory_set(
            cache._generate_key("tool", {"k": "v"}),
            "memory_result",
        )
        result = cache.get("tool", {"k": "v"})
        assert result == "memory_result"

    def test_redis_set_failure_falls_back_to_memory(self):
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True
        mock_redis.setex.side_effect = ConnectionError("Redis down")

        cache = self._make_redis_cache(mock_redis)
        cache.set("tool", {"k": "v"}, "result")

        # Value should be in memory cache
        key = cache._generate_key("tool", {"k": "v"})
        assert cache._memory_get(key, "tool") == "result"

    def test_redis_connection_failure_falls_back_to_memory(self):
        """If Redis ping fails at init, cache uses memory backend."""
        mock_redis = MagicMock()
        mock_redis.ping.side_effect = ConnectionError("Cannot connect")

        cache = self._make_redis_cache(mock_redis)
        assert cache._redis is None

        # Still works via memory
        cache.set("tool", {"k": "v"}, "result")
        assert cache.get("tool", {"k": "v"}) == "result"

    def test_roundtrip_redis(self):
        """set() then get() through mocked Redis."""
        stored = {}
        mock_redis = MagicMock()
        mock_redis.ping.return_value = True

        def fake_setex(key, ttl, value):
            stored[key] = value

        def fake_get(key):
            return stored.get(key)

        mock_redis.setex.side_effect = fake_setex
        mock_redis.get.side_effect = fake_get

        cache = self._make_redis_cache(mock_redis)
        cache.set("tool", {"city": "Paris"}, {"iata": "CDG"})
        result = cache.get("tool", {"city": "Paris"})
        assert result == {"iata": "CDG"}
