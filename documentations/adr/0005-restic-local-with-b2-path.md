# ADR-0005 — Restic backups, local repo with a documented B2 escape hatch

- **Status**: accepted
- **Date**: 2026-04-27
- **Authors**: Yanis Lounadi

## Context

The M5 rubric values **tested DR**, not just backups-on-paper. Three
axes drove the design:

1. **Where do backups live?** On-host vs off-site (B2 / S3 / Storage Box).
2. **How do we verify the recovery path works?** Drill cadence + scope.
3. **How does Prometheus know if backups are healthy?** Metric surface.

Constraints:
- The OVH VPS is the *only* host today. An on-VPS-only repo is a
  single failure away from total loss.
- The user has no funded cloud account beyond OVH; B2 / Hetzner Storage
  Box require a credit card we don't want to demand for the M5
  deliverable itself.
- We need the role to *deploy* and *verify* in this constrained
  state without the off-site account, while keeping the upgrade path
  to off-site as a one-line config flip.

## Decision

We ship **Restic with the local-repo path** as the default
configuration (`/var/backups/bagtrip-restic`, root:root 0700) and we
**document the B2 toggle** as variables that flip the deployment to
off-site without code changes:

```yaml
observability_restic_repository: "b2:<bucket>:bagtrip"
observability_restic_b2_account_id: <id>
observability_restic_b2_account_key: <key>
```

Three operational components ship together:

1. **Daily backup** (systemd timer, 02:00 UTC + jitter) — pg_dumps
   prod + preprod into a single restic snapshot per target, runs
   `forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune`.
2. **Weekly restore drill** (systemd timer, Sun 03:00 UTC + jitter) —
   spins a throwaway `postgres:15-alpine`, dumps the latest snapshot
   into it, runs `SELECT count(*) FROM users` as a sanity gate, tears
   the throwaway down.
3. **Prometheus metrics** via the node_exporter textfile collector
   (`/var/lib/node_exporter/textfile/restic-{backup,restore-test}.prom`).
   Both scripts emit `restic_last_backup_status`,
   `restic_last_successful_backup_timestamp`,
   `restic_last_restore_test_status`, etc. Three alert rules
   (`ResticBackupStale`, `ResticBackupFailed`,
   `ResticRestoreDrillFailed`) wire those into Alertmanager.

## Consequences

### Easier
- Demo cadence: a single `make -C infra restic-backup-now` produces a
  fresh snapshot in < 5 seconds; `make -C infra restic-restore-test-now`
  validates end-to-end in ~3 seconds per target.
- The restore-drill alert
  (`ResticRestoreDrillFailed`) is the cheapest "are backups real?"
  signal we can ship — it forces a real recovery every week and pages
  on the *first* failure, not after a real outage.
- Switching to B2 is a 3-line change in `group_vars/all.yml` once the
  account exists; the script logic, alerts, and runbook all stay
  identical.

### Harder
- The local repo is on the same physical host as the data it backs
  up. If that host's filesystem is destroyed, both go together. We
  accept this trade-off explicitly, and will fail an audit
  question on it; the answer is "B2 toggle one config away".
- Restic password lives in `/opt/observability/.env` (mode 0600
  deploy:deploy). If we lose that file *and* the off-site copy, the
  encrypted repo is unreadable. Documented in the
  `backup-stale.md` runbook.

### Now off-limits
- Backing up to a directory inside `/opt/observability` — that would
  share fate with the obs stack itself. The repo lives at
  `/var/backups/bagtrip-restic` precisely so a `docker compose down -v`
  on the obs stack can't take backups with it.
- Storing the restic password anywhere in git or in the role
  variables. Always generated on first deploy and persisted in
  `/opt/observability/.env`.

## Alternatives considered

| Alternative | Rejected because |
|---|---|
| **`pg_dump` to a daily cron, gzipped to disk** | No encryption, no incremental dedup, no retention policy automation. Restic gives all three for the same operational footprint. |
| **`borg` instead of `restic`** | Comparable feature set; Restic has nicer cloud-storage support out of the box (B2 / S3 / GCS / etc.) and a single binary, no python dependency. |
| **Backblaze B2 from day 1** | Requires a credit card on file. We document it as the one-flag escape hatch but don't make it a hard prerequisite for the deliverable. |
| **Pile snapshots into the OVH VPS snapshot feature** | Off-site, but tied to the single OVH provider account, not testable as a recovery (we'd have to spin a second VPS to verify), and not visible to Prometheus. |
| **Skip the weekly restore drill, just back up** | This is the most common DR failure mode in the wild — backups exist, restore is broken. The M5 rubric specifically credits *tested* recovery. |

## References

- `infra/ansible/roles/observability_stack/templates/restic_backup.sh.j2`
- `infra/ansible/roles/observability_stack/templates/restic_restore_test.sh.j2`
- `infra/ansible/roles/observability_stack/templates/alerts/datastores.yml.j2` (alert group `bagtrip_backups`)
- `infra/runbooks/backup-stale.md`
- `documentations/observability/slo.md` §4 (Reliability SLOs)
