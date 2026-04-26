# Runbooks

One markdown file per actionable Prometheus alert (Phase 4). Each runbook
follows the same shape: trigger, triage, recovery, escalation. Linked
from the alert rule via `runbook_url` so a Discord notification deep-links
into the right page.

| Alert(s) | Runbook |
|---|---|
| `HostCPUSaturated`, `HostMemoryPressure` | [host-cpu-saturation.md](./host-cpu-saturation.md) |
| `HostDiskPressure`, `HostDiskCritical` | [host-disk-pressure.md](./host-disk-pressure.md) |
| `ContainerRestartLoop`, `ContainerMemoryPressure` | [container-restart-loop.md](./container-restart-loop.md) |
| `ContainerCPUSustained` (incident-pattern: cryptominer-2026-04-26) | [cryptominer-suspect.md](./cryptominer-suspect.md) |
| `ApiDown` | [api-down.md](./api-down.md) |
| `ApiHighErrorRate` | [api-error-rate.md](./api-error-rate.md) |
| `ApiLatencyDegraded` | [api-latency-degradation.md](./api-latency-degradation.md) |
| `ApiAvailabilityFastBurn`, `ApiAvailabilitySlowBurn` | [slo-burn-rate.md](./slo-burn-rate.md) |
| `BlackboxProbeDown` | [blackbox-probe-failure.md](./blackbox-probe-failure.md) |
| `TlsCertificateExpiringSoon`, `TlsCertificateExpiringCritical` | [tls-cert-expiry.md](./tls-cert-expiry.md) |
| `PostgresDown`, `PostgresHighConnectionUtilisation` | [postgres-down.md](./postgres-down.md) |
| `RedisDown`, `RedisMemoryPressure` | [redis-down.md](./redis-down.md) |

## Adding a new runbook

1. Author the alert rule in `infra/ansible/roles/observability_stack/templates/alerts/<group>.yml.j2`
   with a `runbook_url` annotation pointing at this folder.
2. Drop a new markdown here with the same triage / recovery / escalation
   structure.
3. Reference the runbook in the table above.
4. Re-run the playbook (`ansible-playbook ... --tags observability`) so
   the rules + Alertmanager pick up the change.

## On-call ergonomics

When triaging an alert from Discord:

1. Click the runbook link in the message.
2. Open Grafana via the link in the runbook (most jump straight to the
   relevant dashboard with the right env / time window).
3. Use Grafana **Explore** to pivot between the three pillars:
   metrics → logs → traces. The Loki datasource adds a `View trace`
   button on every log line that carries a `trace_id`.
