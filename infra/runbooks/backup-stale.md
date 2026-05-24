# Runbook — Restic backup / restore drill failure

> Triggered by: `ResticBackupStale` (page, > 26 h since last success),
> `ResticBackupFailed` (warn, last attempt non-zero exit),
> `ResticRestoreDrillFailed` (page, weekly drill failed).

## Triage

```bash
ssh yanis
sudo systemctl status restic-backup.service restic-backup.timer
sudo journalctl -u restic-backup.service --since "24 hours ago" | tail -60
sudo systemctl status restic-restore-test.service restic-restore-test.timer
sudo journalctl -u restic-restore-test.service --since "8 days ago" | tail -60
```

## Likely causes

| Symptom | Cause | Action |
|---|---|---|
| `pg_dump: connection refused` | The bagtrip postgres container was down at backup time | Check the postgres-down runbook; rerun the backup with `sudo systemctl start restic-backup.service` |
| `restic: Fatal: unable to open repo` | Repository path missing or corrupt | `restic check --read-data-subset=10%` from `/opt/observability/scripts/`; if invalid, rotate to a clean repo and restore from off-VPS copies (B2) |
| `disk full` (anywhere in the script) | `/var/backups/bagtrip-restic` filled the host filesystem | Combine with `host-disk-pressure.md`; restic forget+prune should be running but maybe got stuck — `restic prune` manually |
| Restore drill says `0 rows in users` | Restore appeared to succeed but the SQL was empty | Inspect the latest snapshot: `restic dump latest bagtrip-prod.sql \| head -50`. If empty, the upstream pg_dump is broken. |

## Manual backup

```bash
sudo systemctl start restic-backup.service
sudo journalctl -u restic-backup.service -f
```

## Manual restore (real, into a fresh container)

```bash
ssh yanis
sudo bash
source /opt/observability/.env
export RESTIC_REPOSITORY=/var/backups/bagtrip-restic
export RESTIC_PASSWORD

# Find the snapshot
restic snapshots --tag bagtrip-prod --latest 1

# Spin a throwaway pg
docker run -d --rm --name pg-recover -e POSTGRES_PASSWORD=tmp postgres:15-alpine
sleep 5

# Restore + sanity check
restic dump latest bagtrip-prod.sql \
  | docker exec -i -e PGPASSWORD=tmp pg-recover psql -U postgres -d postgres
docker exec -e PGPASSWORD=tmp pg-recover psql -U postgres -d bagtrip -c 'SELECT count(*) FROM users;'
docker stop pg-recover
```

## Escalation

- A `ResticRestoreDrillFailed` is more urgent than `ResticBackupStale`:
  it means the recovery path itself is broken. Page on-call. Open a
  post-mortem regardless of whether the cause is one-shot or systemic.
- If both fire simultaneously and the on-VPS restic repo is corrupt,
  treat as a data-availability incident — check the off-site copy on
  Backblaze B2 first thing.
