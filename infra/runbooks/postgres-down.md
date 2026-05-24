# Runbook — Postgres down / connection saturation

> Triggered by: `PostgresDown`, `PostgresHighConnectionUtilisation`.

## Down

```bash
ssh yanis
sudo docker ps --filter "name=postgres" --format "table {{.Names}}\t{{.Status}}"
sudo docker logs --tail 80 bagtrip-postgres-1            # or bagtrip-preprod-postgres-1
```

Recovery:

```bash
sudo docker compose -f /opt/<stack>/compose.prod.yml up -d --force-recreate postgres
# wait for healthcheck to go green
until sudo docker exec bagtrip-postgres-1 pg_isready -U bagtrip; do sleep 1; done
# then bring back api so it can re-establish the pool
sudo docker compose -f /opt/<stack>/compose.prod.yml up -d api
```

## Connection saturation

If `numbackends > 80% of max_connections`, the api / a worker is leaking
connections.

```bash
# Open a psql shell
ssh yanis
sudo docker exec -it bagtrip-postgres-1 psql -U bagtrip
```

```sql
SELECT pid, usename, application_name, state, age(now(), state_change), query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY age(now(), state_change) DESC
LIMIT 20;
```

Long-running idle-in-transaction connections from `bagtrip-api` indicate
a code path that opens a transaction and never commits/rollbacks. Cancel
them with `SELECT pg_terminate_backend(<pid>);` and file a follow-up.

## Don't

- Don't change `max_connections` without restarting Postgres — and that
  takes seconds of pg-down. Plan it.
