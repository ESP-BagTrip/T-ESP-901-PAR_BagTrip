# Runbook — Redis down / memory pressure

> Triggered by: `RedisDown`, `RedisMemoryPressure`.

## Down

```bash
ssh yanis
sudo docker ps --filter "name=redis" --format "table {{.Names}}\t{{.Status}}"
sudo docker logs --tail 80 bagtrip-redis-1
```

The api degrades gracefully when Redis is unreachable (rate-limit
counters fall back to in-memory; sessions disappear but auth still
works thanks to JWT). So this is rarely an emergency, more an annoyance.

```bash
sudo docker compose -f /opt/<stack>/compose.prod.yml up -d --force-recreate redis
```

## Memory pressure

```bash
sudo docker exec bagtrip-redis-1 redis-cli info memory | grep -E "used_memory_human|maxmemory_human|maxmemory_policy"
sudo docker exec bagtrip-redis-1 redis-cli --bigkeys 2>&1 | tail -20
```

If `maxmemory_policy` is `noeviction` we'll start refusing writes. The
fix is to flip it to `allkeys-lru` for cache-only data:

```bash
sudo docker exec bagtrip-redis-1 redis-cli config set maxmemory-policy allkeys-lru
```

Persist by bumping the `command:` array in `compose.prod.yml`.

## Don't

- Don't `FLUSHALL` blindly — we have rate-limit counters and pending
  notification dispatch state in Redis. Use `--scan` + `--pattern` to
  target known prefixes if you need to clean up.
