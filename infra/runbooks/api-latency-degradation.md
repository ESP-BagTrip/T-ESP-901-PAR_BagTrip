# Runbook — API latency degradation

> Triggered by: `ApiLatencyDegraded` (p95 > 1 s for 10 min).

## Triage path (≈ 3 minutes)

1. **Grafana → "BagTrip — API RED"** — is p95 elevated *across* endpoints
   or only one? Cross-check against the "Top 10 endpoints by traffic"
   panel.
2. **Grafana → Explore → Tempo**, query
   `{resource.service.name="bagtrip-api"} | duration > 1s`. Sort by duration.
3. Click the slowest trace → spans inside FastAPI handler highlight which
   downstream is slow:
   - `SELECT …` span > 500 ms → Postgres slow query → `make db-shell` and
     run `EXPLAIN` on the query.
   - `httpx.client GET …` span > 1 s → external API (amadeus, llm,
     stripe). Check the host in the span's `http.url` attribute.
   - `redis.GET …` span > 100 ms → Redis under pressure or network blip.

## Mitigations

| Cause | Quick action |
|---|---|
| Slow DB query | Add the missing index (Alembic migration) |
| Slow LLM | Lower `LLM_CALL_TIMEOUT_SECONDS` to fail fast — degrades user UX but unblocks SSE planner |
| Connection pool starvation (`asyncpg.PoolTimeout`) | Bump `pool_size` in `DATABASE_URL` |
| Slow Redis | Check `redis_blocked_clients` in Grafana — typically a single misbehaving worker |

## Escalation

- If p95 > 5 s for 10 min and no obvious upstream culprit: page on-call.
- If the SSE plan-trip endpoint specifically is slow, see the SSE-specific
  SLI in `documentations/observability/slo.md` §1.4.
