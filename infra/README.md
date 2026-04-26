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

## Known carry-overs from Phase 1a → Phase 1b

- **Edge Caddy `/metrics`**: the admin endpoint binds `127.0.0.1:2019` via
  host networking. Prometheus in a bridge network can't reach it through
  `host.docker.internal:host-gateway`. Phase 1b rebinds admin to the
  docker0 IP and adds a `PREROUTING` DROP rule for `! -i lo` on dport 2019
  (matching the pattern already in place for inner Caddy ports 808X).
- **`/opt/edge` directory mount**: the Caddyfile is currently bind-mounted
  as a single file, which forces a `--force-recreate` of `edge-caddy` on
  every change. Phase 1c rebinds `/opt/edge` as a directory so a soft
  `caddy reload` suffices.

## Phase status

| Phase | Scope | Status |
|---|---|---|
| 0 | Cadrage, Ansible skeleton, baseline assertion, ADR-001, threat model, SLO | shipped |
| 1a | Prometheus + Grafana + node_exporter + cAdvisor + postgres + redis + blackbox + 4 dashboards + public exposure (`grafana.bagtrip.fr` behind basic_auth) | shipped |
| 1b | App instrumentation (FastAPI / Next.js → 2 RED dashboards), edge Caddy /metrics rebind | pending |
| 2 | Loki + Promtail | pending |
| 3 | OpenTelemetry → Tempo | pending |
| 4 | Alertmanager + runbooks | pending |
| 5 | Falco + CrowdSec rules + Trivy CI | pending |
| 6 | Restic backups + restore drill | pending |
| 7 | Blackbox + business metrics | pending |
| 8 | IaC polish + reproducibility demo | pending |
| 9 | Documentation finalisée + soutenance | pending |
