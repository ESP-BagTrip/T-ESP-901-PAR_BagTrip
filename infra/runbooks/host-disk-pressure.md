# Runbook — Host disk pressure

> Triggered by: `HostDiskPressure` (warn, < 15 % free), `HostDiskCritical` (page, < 5 % free).

## Symptoms

Root filesystem has less free space than the threshold. Loki / Tempo
retention will start shedding data; Postgres will refuse new writes once
the disk is full.

## Top consumers

```bash
ssh yanis
sudo du -h --max-depth=1 /var /opt /home 2>/dev/null | sort -h | tail
sudo docker system df
sudo du -sh /var/lib/docker/containers/*/*-json.log 2>/dev/null | sort -h | tail   # wide log producers
```

## Common culprits

- `/var/lib/docker/volumes/observability_loki_data/_data` — Loki blocks
  past their retention window. Check `limits_config.retention_period` in
  `loki.yaml`.
- `/var/lib/docker/volumes/observability_prometheus_data/_data` — TSDB
  retention drift. Adjust `--storage.tsdb.retention.size`.
- Old container json-file logs — `/etc/docker/daemon.json` already sets
  `max-size: 50m, max-file: 5`, but a runaway logger still bloats.

## Mitigation

```bash
# Reclaim un-used Docker layers / volumes / images
sudo docker system prune -af --volumes

# Truncate a noisy container log (does NOT lose past Loki data)
sudo truncate -s 0 /var/lib/docker/containers/<id>/<id>-json.log

# Last resort: shrink Loki retention temporarily (re-deploy the role to
# revert):
ssh yanis 'sudo sed -i "s/retention_period: 336h/retention_period: 168h/" /opt/observability/loki/local-config.yaml'
sudo docker compose -f /opt/observability/compose.yml restart loki
```

## Don't

- Don't `rm -rf /var/log/incident/` — those are forensic artefacts from
  prior incidents (cf. 26/04). Treat as immutable.
