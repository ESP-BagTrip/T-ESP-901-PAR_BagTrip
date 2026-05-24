# Runbook — Host CPU / memory saturation

> Triggered by: `HostCPUSaturated`, `HostMemoryPressure`.

## Symptoms

VPS aggregate CPU > 90 % or available memory < 10 %, sustained 5–10 minutes.
The OOM killer is approaching; under disk-backed swap=0 (our case) Linux
will start killing the largest cgroup once memory is exhausted.

## Triage

```bash
ssh yanis
sudo docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
ps aux --sort=-%cpu | head -10
free -h
```

Open Grafana → "BagTrip — Containers" with `var-container=All`. The top
panel sorts by CPU; the heaviest container is the entry point.

## Decide

| If the heavy container is… | Action |
|---|---|
| `bagtrip-api-*` | Check API RED dashboard for a request-rate spike; if real traffic, scale the LLM rate-limit middleware. If no traffic, jump to `cryptominer-suspect.md`. |
| `bagtrip-postgres-*` | Look at `pg_stat_activity` for runaway queries (`make db-shell`). |
| `observability-prometheus` / `observability-loki` | A wide query (no time bound) is being run; check Grafana audit log. |
| Anything unexpected | Treat as suspicious — `cryptominer-suspect.md`. |

## Mitigation

- **Restart** the heaviest container if it's safe to drop in-flight work
  (api / admin acceptable; postgres NOT — pause queries instead).
- **Resize** the VPS (OVH dashboard) if this is sustained legitimate load
  — recurring saturation is not a problem to solve at runtime.

## Don't

- Don't `docker compose down` the whole stack — CrowdSec & edge logs go
  with it and you lose attack-surface visibility during recovery.
