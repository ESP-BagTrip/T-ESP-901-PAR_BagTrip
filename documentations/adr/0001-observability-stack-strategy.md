# ADR-0001 — Observability stack strategy

- **Status**: accepted
- **Date**: 2026-04-26
- **Authors**: Yanis Lounadi
- **Supersedes**: —

## Context

The BagTrip production VPS runs three application stacks behind a single Caddy edge proxy, plus a few baseline controls (CrowdSec, iptables-persistent, journald persistent storage, Netdata). The 2026-04-26 cryptominer incident (`documentations/security/incident-2026-04-26-cryptominer.md`) made three observability gaps painfully concrete:

1. **No supply-chain control** — a known CVE in Next.js 15.5.0 reached production because nothing in CI flagged it.
2. **No runtime detection** — an exec from `/tmp` and an outbound connection to a Monero pool both went unnoticed; only sustained CPU eventually triggered Netdata.
3. **No correlation across signals** — by the time we triaged, edge logs were absent, Netdata gave no per-request context, and journald was the only thing tying events to wall time.

The Master M5 deliverable also requires demonstrable competence across observability, security, IaC, and incident response. Choices made here therefore have to satisfy two audiences: the operational reality of running BagTrip, and the M5 jury reading the rubric.

A plan covering metrics + logs + traces + alerting + security runtime + DR + IaC + business KPIs has been agreed (see `infra/README.md` for the deliverable status table).

## Decision

We adopt a **single observability stack unified under Grafana**, deployed and managed via **Ansible**, with scope **strictly limited to BagTrip-managed paths**:

| Pillar | Tool | Backend on VPS |
|---|---|---|
| Metrics | Prometheus | scrapes node-exporter, cAdvisor, postgres-exporter, redis-exporter, blackbox, app `/metrics` |
| Logs | Loki + Promtail | journald + Docker container logs + Caddy access logs (parsed structured JSON) |
| Traces | OpenTelemetry SDK + Tempo | FastAPI (`api/`) and Next.js (`admin-panel/`) auto-instrumentation, OTLP export |
| Alerting | Alertmanager | routes to Discord (warn) and email (critical), runbooks in `infra/runbooks/` |

Grafana is the single user-facing pane of glass; PromQL, LogQL, and TraceQL are queryable side-by-side, correlated by `trace_id` and time window.

The whole stack is deployed by Ansible roles under `infra/ansible/roles/`. No tool is installed by hand. The inventory targets exactly one host (`vps_prod`, accessed via the `yanis` SSH alias), with all variables and secrets versioned (vault-encrypted where sensitive).

## Consequences

### Easier
- One UI to learn, one auth to maintain (Grafana basic auth via Caddy in early phases, SSO later if time permits).
- Adding a new exporter or dashboard is a one-PR change with a clear review surface.
- The "redeploy from scratch" demo for the jury is `ansible-playbook site.yml` against a clean snapshot.
- The 26/04 incident becomes a concrete acceptance test: each deliverable ships a control that would have detected/prevented one specific gap.

### Harder
- Total RAM budget for the obs stack will sit around 2–3 GB. The VPS has 31 GB total (after the 2026-04-26 upgrade) — comfortable headroom. Disk is also comfortable (~40 % used on a 193 GiB volume after the 2026-04-26 expansion), unlocking Loki / Tempo retention without juggling.
- Loki + Tempo each add their own retention/storage knobs to maintain. We accept that overhead in exchange for the single-pane-of-glass benefit.
- Ansible-first means every infrastructure change goes through a playbook, which has a small overhead per task vs. SSH-and-edit. The trade-off is reproducibility — non-negotiable for the jury demo.

### Now off-limits
- Ad-hoc Docker run / SSH-and-edit operations on managed paths. If it isn't in Ansible, it isn't on the VPS.
- Mixing UIs (Kibana for logs, Jaeger for traces, etc.). One Grafana, one query language family, one auth boundary.
- Touching paths outside BagTrip scope. Any non-BagTrip workload that shares the host is treated as out of scope: not managed by Ansible, not enumerated in our inventory, never named in dashboards or alert rules. Its resource consumption is visible only at the host level, which is sufficient for capacity planning.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| **ELK (Elasticsearch + Logstash + Kibana) for logs** | Heavier (Elasticsearch alone wants 2+ GB heap). Splits UI across Kibana and Grafana. Loki's index-by-label model fits container log volumes at our scale much better. |
| **Datadog / Grafana Cloud / New Relic (managed)** | Faster to set up, but the jury rubric explicitly values self-hosted operations. Also: hides the configuration that we want to demonstrate. |
| **Jaeger as the trace UI** | Strong UI for traces alone, but reintroduces the multi-pane problem. Tempo+Grafana is good enough and keeps everything correlated through one product. |
| **Terraform for IaC** | OVH provider is thin and most of our state is on-host (systemd, packages, files). Ansible is the right tool for configuration management; Terraform earns its place when we add managed cloud resources. |
| **Kubernetes / k3s** | Adds etcd, an API server, and a learning curve, all to solve scheduling problems we don't have on a single VPS. Pure operational overhead. |
| **GitOps via ArgoCD/Flux** | Same reason — it's a Kubernetes pattern. Nothing prevents us from running the Ansible playbook in CI on merge to `main`, which gives us most of the GitOps benefit at zero infra cost. |
| **Wazuh or Falco *and* auditd as overlapping HIDS** | Coverage overlap, three places to maintain rules. We pick **Falco** (containers-first, Prometheus-native, modern rule syntax) and lean on journald + auditd-light for host events. Wazuh is a fine alternative SIEM but is overkill for one host. |
| **Authentik / Authelia SSO from day 1** | High setup cost for four internal dashboards. We start with Caddy basic auth (already in place for Netdata) and revisit SSO if there is slack later. |

## References

- `documentations/security/incident-2026-04-26-cryptominer.md` — the trigger incident
- `documentations/security/hardening-roadmap.md` — companion backlog this plan resolves
- `infra/README.md` — deliverable status board
- `documentations/observability/slo.md` — SLO/SLI targets that drive alert rule thresholds
- `documentations/security/threat-model.md` — STRIDE model whose "after" column this plan fills in
