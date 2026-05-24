# Runbook — API 5xx rate elevated

> Triggered by: `ApiHighErrorRate` (> 5 % 5xx for 10 min).

## Where to look first

1. **Grafana → "BagTrip — API RED"**, env=`prod` or `preprod`. The "Top 10
   endpoints by traffic" panel + the error rate panel tell you whether
   it's a single endpoint or fleet-wide.
2. **Grafana → "BagTrip — Logs"**, `service=api, env=<env>, level=error`.
   Look at the most repeated error message; that's the failing dependency
   (DB, LLM, Stripe, Amadeus).
3. **Grafana → Explore → Tempo**, search
   `{resource.service.name="bagtrip-api" && status=error}`. Click into a
   trace to see which span fails (DB query? external HTTP?).

## Common causes

| Symptom | Likely cause | Action |
|---|---|---|
| `Connection refused` to `postgres:5432` in logs | Postgres container restart | `postgres-down.md` |
| `httpx.RemoteProtocolError` to amadeus / stripe / openai | Upstream provider issue | Check vendor status pages; degrade gracefully if possible |
| `RateLimitExceeded` in our logs | Our own middleware is firing too aggressively | Inspect `src/middleware/rate_limit.py` thresholds |
| LLM-specific (`gpt-oss-120b`) timeouts | Provider issue | `LLM_CALL_TIMEOUT_SECONDS` in env — temporary bump if provider is slow |

## Mitigation while debugging

- If a single endpoint is at fault, you can disable it via Caddy:
  ```caddyfile
  @broken path /v1/<broken-route>
  respond @broken 503 "Temporarily unavailable"
  ```
- For a fleet-wide DB issue, scale Postgres connection pool down so api
  stops hammering it: edit `DATABASE_URL` query string to lower
  `pool_size`.

## Don't

- Don't bump `OTEL_TRACES_SAMPLER_ARG` mid-incident — high-cardinality
  trace export is exactly what makes Tempo storage fall over during a
  storm.
