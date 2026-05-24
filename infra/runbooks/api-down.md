# Runbook — API down

> Triggered by: `ApiDown` (`up{job="bagtrip-api"} == 0` for 2 min).

## Quick checks

```bash
ssh yanis
sudo docker ps --filter "name=bagtrip-api" --format "table {{.Names}}\t{{.Status}}"
sudo docker logs --tail 80 bagtrip-api-1            # or bagtrip-preprod-api-1
curl -s http://127.0.0.1:9090/api/v1/query?query=up{job=\"bagtrip-api\"}
```

## Likely causes

1. **Container crashed** — see `container-restart-loop.md`.
2. **Postgres down** — api healthcheck probably also failed; chain runbook `postgres-down.md`.
3. **Network partition** — Prometheus can't reach the api container even
   though the api is up. Check that the obs stack is multi-homed on
   `bagtrip_default` / `bagtrip-preprod_default` (cf. compose.yml.j2).
4. **/metrics endpoint regression** — see `documentations/observability/`
   gotchas (the app instrumentation work hit two of these). Verify
   `bagtrip-api-1:3000/metrics` returns Prometheus text from inside the
   docker network.

## Recovery

If the container is unhealthy and the latest logs show an error during
startup, the safest move is to roll back to the previous image:

```bash
ssh yanis
cd /opt/bagtrip            # or /opt/bagtrip-preprod
git log --oneline -3       # find the last green commit
git reset --hard <sha>
sudo docker compose -f compose.prod.yml up -d --build
```

## Escalation

- 5xx storm during recovery → page on-call.
- Still down after 15 minutes → declare incident, post-mortem.
