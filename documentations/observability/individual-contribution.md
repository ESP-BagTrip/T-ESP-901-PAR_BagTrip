# Observability + security stack — individual contribution fiche

> **Scope caveat.** The M5 deliverable graded by the jury is the BagTrip
> SaaS itself — the team's ability to ship a multi-stack product
> (Flutter / FastAPI / Next.js / CI-CD / quality gates / etc.). The
> work documented here is an **individual investigation pass** that
> sits alongside the team build: an observability + security +
> reliability layer wrapped around the existing services. Mention
> sparingly during the team defence; this fiche is here for any
> reviewer who wants to dig in afterwards.

## Origin (the fun fact)

On **2026-04-26 09:07 UTC**, our pre-prod admin panel was compromised
through a Server-Actions header-injection bug in Next.js 15.5.0
(CVE-2025-49826). A staged dropper landed an XMRig-style cryptominer
in `/tmp/XXEKdPOH` and ran for **7h 45min** at 99 % CPU before our
default Netdata sustained-CPU alert finally fired. Containment took
10 minutes once detected.

Full post-mortem (timeline, IOCs, RCA, lessons learned, M5 mapping):
[`security/incident-2026-04-26-cryptominer.md`](../security/incident-2026-04-26-cryptominer.md)

That incident is what motivated the rest of this folder. The infra
work below was sequenced explicitly to close each of the seven gaps
the post-mortem identified.

## What got built

| Layer | Deliverable | Reference |
|---|---|---|
| Foundations | Ansible scaffold, baseline assertions, umbrella ADR, STRIDE before, SLO baseline | [`adr/0001`](../adr/0001-observability-stack-strategy.md) · [`security/threat-model.md`](../security/threat-model.md) · [`observability/slo.md`](./slo.md) |
| Metrics | Prometheus + Grafana + 5 exporters + 4 baseline dashboards + public Grafana on `grafana.bagtrip.fr` | [`adr/0002`](../adr/0002-three-pillars-grafana.md) |
| App instrumentation | FastAPI + Next.js (`prometheus-fastapi-instrumentator`, `prom-client`) + 2 RED dashboards | `api/src/main.py`, `admin-panel/src/instrumentation.ts` |
| Edge metrics | Caddy `/metrics` scrape via dedicated vhost, `/opt/edge` directory mount | `infra/ansible/roles/observability_stack/` |
| Logs | Loki + Promtail (allowlist-filtered to BagTrip-managed containers) + Logs dashboard | — |
| Traces | OpenTelemetry → Tempo distributed tracing, with `trace_id` correlation back to Loki | — |
| Alerting | Alertmanager + 19 alert rules + 12 runbooks + Discord webhook + multi-window SLO burn-rate alerts | [`infra/runbooks/`](../../infra/runbooks/) |
| Supply chain | Trivy scan in CI (already paid off — 5 HIGH CVEs patched) | [`adr/0003`](../adr/0003-defense-in-depth-incident-driven.md) |
| Runtime detection | Falco rules (config shipped, runtime deferred — Linux 6.14 kernel-probe issue) | — |
| DR | Restic encrypted backups + **automated weekly restore drill** + 3 alerts on backup health | [`adr/0005`](../adr/0005-restic-local-with-b2-path.md) |
| Business KPIs | KPI dashboard + Synthetic / DR dashboard | — |
| IaC polish | Idempotence, Makefile, destroy & redeploy demo | [`adr/0004`](../adr/0004-iac-with-ansible.md) |
| Docs | 5 ADRs, threat model after-state, C4 diagrams, RGPD data flow | [`adr/`](../adr/) · [`architecture/`](../architecture/) |

10 dashboards in Grafana, 19 alert rules, 12 runbooks, 5 ADRs, one
post-mortem, one threat model with before / after columns, one cost
study, one tested DR drill running weekly.

## Where to dig deeper, by interest

| If you care about… | Read |
|---|---|
| Why each architecture choice | [`adr/`](../adr/) |
| Security posture before / after | [`security/threat-model.md`](../security/threat-model.md) |
| The incident itself | [`security/incident-2026-04-26-cryptominer.md`](../security/incident-2026-04-26-cryptominer.md) |
| What's still on the backlog | [`security/hardening-roadmap.md`](../security/hardening-roadmap.md) |
| Service-level objectives | [`observability/slo.md`](./slo.md) |
| Architecture diagrams | [`architecture/c4-context.md`](../architecture/c4-context.md) · [`architecture/c4-containers.md`](../architecture/c4-containers.md) |
| RGPD data flow | [`architecture/data-flow-rgpd.md`](../architecture/data-flow-rgpd.md) |
| Self-host vs managed cost analysis | [`architecture/cost-self-host-vs-managed.md`](../architecture/cost-self-host-vs-managed.md) |
| Operational entry points | [`infra/Makefile`](../../infra/Makefile) · [`infra/runbooks/`](../../infra/runbooks/) |

## Operating it (5-line cheat sheet)

```bash
# Smoke test SSH/sudo plumbing
make -C infra ping

# Dry-run the playbook (never modifies the host)
make -C infra check

# Apply (idempotent — converged host reports ok=N changed=0)
make -C infra deploy

# Trigger a restic backup or restore-drill ad hoc
make -C infra restic-backup-now
make -C infra restic-restore-test-now

# Full destroy + ansible-rebuild — proves IaC reproducibility (~50s)
make -C infra redeploy-demo
```

Local secrets (Discord webhook, etc.) live in `infra/ansible/secrets.yml`
which is `.gitignore`'d. Production-grade alternative is
`ansible-vault encrypt secrets.yml`.
