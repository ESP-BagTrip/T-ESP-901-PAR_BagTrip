"""Unit tests for the shared DistributedCache helper."""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

from src.integrations.distributed_cache import DistributedCache

MODULE = "src.integrations.distributed_cache.get_redis_client"


class TestMemoryFallback:
    """When Redis is unavailable the per-process TTLCache backs the cache."""

    def test_miss_returns_none(self) -> None:
        with patch(MODULE, return_value=None):
            cache = DistributedCache("t", ttl_seconds=60)
            assert cache.get("missing") is None

    def test_set_then_get_roundtrip_string(self) -> None:
        with patch(MODULE, return_value=None):
            cache = DistributedCache("t", ttl_seconds=60)
            cache.set("k", "https://img")
            assert cache.get("k") == "https://img"

    def test_set_then_get_roundtrip_dict(self) -> None:
        with patch(MODULE, return_value=None):
            cache = DistributedCache("t", ttl_seconds=60)
            cache.set("k", {"flight": "AF123", "gate": "B12"})
            assert cache.get("k") == {"flight": "AF123", "gate": "B12"}

    def test_clear_empties_memory(self) -> None:
        with patch(MODULE, return_value=None):
            cache = DistributedCache("t", ttl_seconds=60)
            cache.set("k", "v")
            cache.clear()
            assert cache.get("k") is None


class TestRedisBackend:
    def test_set_writes_to_redis_with_ttl(self) -> None:
        redis = MagicMock()
        with patch(MODULE, return_value=redis):
            cache = DistributedCache("unsplash", ttl_seconds=3600)
            cache.set("paris", "https://img/paris")
        redis.setex.assert_called_once()
        args = redis.setex.call_args.args
        assert args[0] == "cache:unsplash:paris"
        assert args[1] == 3600
        assert json.loads(args[2]) == "https://img/paris"

    def test_get_reads_and_decodes_from_redis(self) -> None:
        redis = MagicMock()
        redis.get.return_value = json.dumps({"a": 1})
        with patch(MODULE, return_value=redis):
            cache = DistributedCache("airlabs", ttl_seconds=300)
            assert cache.get("AF1") == {"a": 1}
        redis.get.assert_called_once_with("cache:airlabs:AF1")

    def test_get_redis_failure_falls_back_to_memory(self) -> None:
        redis = MagicMock()
        redis.get.side_effect = RuntimeError("down")
        with patch(MODULE, return_value=redis):
            cache = DistributedCache("t", ttl_seconds=60)
            cache._memory["k"] = "from-memory"
            assert cache.get("k") == "from-memory"

    def test_clear_scans_and_deletes_namespace(self) -> None:
        redis = MagicMock()
        redis.scan_iter.return_value = ["cache:t:a", "cache:t:b"]
        with patch(MODULE, return_value=redis):
            cache = DistributedCache("t", ttl_seconds=60)
            cache.clear()
        redis.scan_iter.assert_called_once_with("cache:t:*")
        assert redis.delete.call_count == 2
