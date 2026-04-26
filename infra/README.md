# `infra/` — BagTrip observability & operations

Infrastructure-as-code for the BagTrip production VPS. Owns everything that lives outside the application repos: Ansible playbooks, Prometheus rules, Grafana dashboards, runbooks.

## Layout

```
infra/
├── ansible/              # IaC for the host: roles, inventory, playbooks
│   ├── ansible.cfg
│   ├── inventory/        # hosts.yml — vps_prod target
│   ├── group_vars/       # variables shared across hosts
│   ├── roles/            # one role per concern (common, prometheus, loki, …)
│   ├── playbooks/        # entry-points (site.yml at the top)
│   └── requirements.yml  # collections + roles to install
├── dashboards/           # Grafana JSON, version-controlled
├── alerts/               # Prometheus alert rules, Loki rules
├── runbooks/             # 1 markdown per actionable alert
└── README.md             # this file
```

## Scope

In scope:

- BagTrip production stack (`/opt/bagtrip`)
- BagTrip pre-production stack (`/opt/bagtrip-preprod`)
- Edge Caddy (`/opt/edge`)
- Monitoring stack (`/opt/monitoring`)
- Host-level concerns: kernel, systemd, iptables, journald, Docker daemon

Out of scope: any third-party project that happens to share the same VPS. Their resource consumption shows up in host-level metrics; they are not managed by these playbooks and are not enumerated here.

## How to run Ansible

From `infra/ansible/`:

```bash
ansible -i inventory/hosts.yml vps_prod -m ping            # connectivity check
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check   # dry-run
ansible-playbook -i inventory/hosts.yml playbooks/site.yml           # apply
```

The playbook is idempotent: re-running on a converged host should report `0 changed`.

## Phase status

This repo is built phase-by-phase as described in the M5 observability plan. See `documentations/adr/0001-observability-stack-strategy.md` for the full plan and rationale.

## Carry-overs resolved in Phase 1c

- **Edge Caddy `/metrics` scrape**: a dedicated `:8089 { metrics }` vhost
  exposes Caddy's full metric set without touching the admin endpoint
  (Caddy's origin enforcement on a non-localhost admin bind is too
  restrictive to fight cleanly). Public access blocked by an iptables
  INPUT DROP rule on the default-route NIC; Prometheus reaches it via
  `host.docker.internal:8089`. Job: `caddy_edge`.
- **`/opt/edge` directory mount**: switched from
  `./Caddyfile:/etc/caddy/Caddyfile:ro` to `./:/etc/caddy:ro`, so future
  Caddyfile content changes propagate without `--force-recreate`. The
  Reload edge Caddy handler now does a soft `caddy reload`.

## Phase status

| Phase | Scope | Status |
|---|---|---|
| 0 | Cadrage, Ansible skeleton, baseline assertion, ADR-001, threat model, SLO | shipped |
| 1a | Prometheus + Grafana + node_exporter + cAdvisor + postgres + redis + blackbox + 4 dashboards + public exposure (`grafana.bagtrip.fr` behind basic_auth) | shipped |
| 1b | App instrumentation (FastAPI / Next.js → 2 RED dashboards) | shipped |
| 1c | Edge Caddy /metrics scrape via dedicated vhost + /opt/edge dir mount | shipped |
| 2 | Loki + Promtail (centralised logs) | shipped |
| 3 | OpenTelemetry → Tempo (distributed tracing) | shipped |
| 4 | Alertmanager + 19 alert rules + 12 runbooks | shipped |
| 5a | Trivy supply-chain scan in CI | shipped |
| 5b | Falco runtime rules (config shipped, runtime deferred — see below) | shipped (config) |
| 6 | Restic backups + automated weekly restore drill | shipped |
| 7 | Business KPIs + Synthetic / DR dashboards | shipped |
| 2 | Loki + Promtail | pending |
| 3 | OpenTelemetry → Tempo | pending |
| 4 | Alertmanager + runbooks | pending |
| 5 | Falco + CrowdSec rules + Trivy CI | pending |
| 6 | Restic backups + restore drill | pending |
| 7 | Blackbox + business metrics | pending |
| 8 | IaC polish + reproducibility demo | pending |
| 9 | Documentation finalisée + soutenance | pending |
