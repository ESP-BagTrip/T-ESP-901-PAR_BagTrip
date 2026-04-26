# Runbook — Container restart loop

> Triggered by: `ContainerRestartLoop` (>2 restarts in 15 min) or
> `ContainerMemoryPressure` (RSS > 90 % of memory limit).

## Triage

```bash
ssh yanis
sudo docker ps --filter "name=bagtrip-" --format "table {{.Names}}\t{{.Status}}"
sudo docker logs --tail 200 <container>
```

In Grafana → "BagTrip — Logs" select `service=<service>` and look at the
last 30 minutes for the panic / unhandled exception that precedes the
restart.

## Common patterns

| Log pattern | Cause | Fix |
|---|---|---|
| `OOMKilled` in `docker inspect <c> --format '{{ .State.OOMKilled }}'` | Memory limit too low | Bump `mem_limit` in compose.prod.yml or fix the leak |
| `database "bagtrip" does not exist` | Postgres init failed before api started | Inspect `bagtrip-postgres-*` first |
| `ERR Redis is loading the dataset in memory` | Redis was restarted, api started too fast | The `depends_on: condition: service_healthy` should prevent this — verify in compose |
| `address already in use` | Port collision (only on same Docker network) | Check sibling services |

## Recovery

```bash
sudo docker compose -f /opt/<stack>/compose.prod.yml up -d --force-recreate <service>
```

If the loop persists for > 10 minutes after recovery, escalate to a
post-mortem.
