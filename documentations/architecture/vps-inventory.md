# BagTrip VPS — inventory snapshot

> Snapshot taken 2026-04-26, before Phase 1 of the M5 observability plan.
> This document captures the **as-is state** of the BagTrip-managed surface on the production VPS, so subsequent Ansible roles encode reality rather than guesses.

## 1. Host

| Field | Value |
|---|---|
| Provider | OVH VPS |
| Reachable via | SSH alias `yanis` (declared in `~/.ssh/config`) |
| OS | Ubuntu 25.04 |
| Kernel | 6.14.0-37-generic |
| CPUs | 8 vCPU (post-2026-04-26 upgrade; previously 4) |
| RAM | 31 GiB (post-2026-04-26 upgrade; previously 16) |
| Root filesystem | 193 GiB ext4 — usage at snapshot time: ~40 % (volume expanded during the 2026-04-26 maintenance window) |
| Swap | none |
| Hostname | OVH-generated UUID (treated as opaque) |

User accounts:

- `ubuntu` — sudoer, primary administration account.
- `deploy` — owns `/opt/<bagtrip-stack>` repos for the CI/CD deployment flow. **Not in the `docker` group**, so any Docker invocation from this account requires `sudo`.
- Root login over SSH is disabled.

## 2. Filesystem layout (BagTrip scope)

```
/opt/
├── bagtrip/             # Production stack repo (deploy:deploy)
├── bagtrip-preprod/     # Pre-production stack repo (deploy:deploy)
├── edge/                # Edge Caddy configuration + TLS certs (deploy:deploy)
└── monitoring/          # Netdata compose (deploy:deploy)
```

Notable system paths under management:

```
/etc/iptables/rules.v4                                   # 103 lines, includes incident-2026-04-26 C2 block
/etc/iptables/rules.v6                                   # IPv6 baseline rules
/etc/systemd/journald.conf.d/persistence.conf            # SystemMaxUse=2G, MaxRetentionSec=3month
/etc/docker/daemon.json                                  # log-driver json-file, max-size 50m, max-file 5
/usr/local/bin/shutdown-snapshot.sh                      # invoked by shutdown-snapshot.service
/var/log/incident/                                       # forensic artefacts (REPORT.md + XXEKdPOH.bin) — preserve
/var/log/shutdown-snapshots/                             # outputs of shutdown-snapshot.service
/opt/edge/logs/access.log                                # Caddy JSON access logs, 50 MB × 7 rotation
```

## 3. Edge & networking

Edge proxy: a single Caddy 2.11.2 container (`edge-caddy`) running with `network_mode: host`, listening on `:80` and `:443`.

Public listening sockets on the VPS:

| Port | Process | Purpose |
|---|---|---|
| 22/tcp | sshd | Operations access (key-only) |
| 80/tcp | edge-caddy | Cloudflare-fronted HTTP redirect |
| 443/tcp | edge-caddy | Cloudflare-fronted HTTPS |

All other listeners bind to `127.0.0.1`:

| Loopback port | Service |
|---|---|
| 127.0.0.1:8081 | bagtrip prod inner Caddy |
| 127.0.0.1:8082 | bagtrip preprod inner Caddy |
| 127.0.0.1:8085 | Netdata (proxied to `monitoring.bagtrip.fr` behind basic auth) |
| 127.0.0.1:8086 | CrowdSec LAPI |
| 127.0.0.1:2019 | Caddy admin API |
| 127.0.0.1:6060 | CrowdSec metrics endpoint |

Public domains routed by edge Caddy (BagTrip scope):

- `bagtrip.fr` → bagtrip prod admin
- `api.bagtrip.fr` → bagtrip prod API
- `dev.bagtrip.fr` → bagtrip preprod admin
- `api.dev.bagtrip.fr` → bagtrip preprod API
- `monitoring.bagtrip.fr` → Netdata (basic auth in edge Caddyfile)

TLS: Cloudflare-issued origin certificates in `/opt/edge/certs/`. Cloudflare in front of every public hostname.

## 4. Docker stacks (BagTrip scope)

Docker Engine 29.2.1, daemon configured for log rotation (`json-file`, 50 MB × 5).

### 4.1 `bagtrip` (production) — `/opt/bagtrip/compose.prod.yml`

| Container | Image | Notes |
|---|---|---|
| `bagtrip-caddy-1` | `caddy:2-alpine` | Inner reverse proxy, binds 127.0.0.1:8081 |
| `bagtrip-admin-1` | `bagtrip-admin` | Next.js 16.2.4. Hardened: `read_only`, `tmpfs:/tmp:noexec,nosuid`, `cap_drop:[ALL]` + minimal cap_add, `no-new-privileges:true` |
| `bagtrip-api-1` | `bagtrip-api` | FastAPI + Uvicorn, healthcheck on `/health` |
| `bagtrip-postgres-1` | `postgres:15-alpine` | Primary DB |
| `bagtrip-redis-1` | `redis:7-alpine` | Sessions + rate-limit counters |

### 4.2 `bagtrip-preprod` (preprod) — `/opt/bagtrip-preprod/compose.prod.yml`

Same five-service shape as prod, with the same hardening on `bagtrip-preprod-admin-1`. Inner Caddy binds 127.0.0.1:8082.

### 4.3 `monitoring` — `/opt/monitoring/compose.yml`

| Container | Image | Notes |
|---|---|---|
| `netdata` | `netdata/netdata:stable` | Linked to Netdata Cloud; binds 127.0.0.1:8085 |

### 4.4 `edge` — `/opt/edge/compose.yml`

| Container | Image | Notes |
|---|---|---|
| `edge-caddy` | `caddy:2-alpine` | `network_mode: host`, configures all public hostnames listed in §3 |

## 5. systemd units in scope

Unit files BagTrip operations depends on:

| Unit | State | Purpose |
|---|---|---|
| `ssh.service` | active (running) | Operations access |
| `docker.service` | active (running) | Container engine |
| `containerd.service` | active (running) | Container runtime |
| `crowdsec.service` | active (running) | IDS agent (LAPI on 127.0.0.1:8086) |
| `crowdsec-firewall-bouncer.service` | active (running) | Iptables driver for CrowdSec decisions |
| `systemd-journald.service` | active (running) | Persistent journald per `persistence.conf` |
| `unattended-upgrades.service` | active (running) | Security updates auto-applied |
| `netfilter-persistent.service` | enabled (loads on boot) | Restores `/etc/iptables/rules.v4` after reboot |
| `shutdown-snapshot.service` | enabled (runs at shutdown) | Captures system state before poweroff |

## 6. Defence-in-depth controls (snapshot)

- **Inbound**: only `:22`, `:80`, `:443` reachable from outside the VPS. Everything else binds loopback.
- **iptables-persistent**: `/etc/iptables/rules.v4` (103 lines) restored on every boot. Includes the `OUTPUT -d 51.81.51.221 -j DROP` block from incident-2026-04-26.
- **CrowdSec**: SSH brute-force scenarios + community CAPI blocklist; firewall bouncer applies decisions. Active decisions count visible via `cscli decisions list`.
- **journald**: persistent storage, 2 GB cap, 3-month retention.
- **Docker logs**: rotated at 50 MB × 5 per container.
- **Edge access logs**: JSON to `/opt/edge/logs/access.log`, 50 MB × 7 rotation.
- **Container hardening (admin only)**: applied 2026-04-26 — see post-mortem §4.3.

## 7. Known constraints

- **Disk**: root at ~40 % on a 193 GiB volume — comfortable headroom for Phase 1 (Loki / Tempo retention).
- **No swap**: memory is hard-capped at 31 GiB. Phase 1+ stack additions must respect this budget, but the headroom is now substantial.
- **Docker socket**: not exposed to any container. Future phases must keep this property (asserted in the `common` Ansible role).
- **`ubuntu` not in `docker` group**: every Docker call goes through sudo. Ansible playbooks `become: true` to handle this transparently.

## 8. What will change in Phase 1+

The following will be added on top of this baseline:

- A new `monitoring/` compose stack containing Prometheus, Grafana, Alertmanager, Loki, Promtail, Tempo, and the dedicated exporters. Deployed by Ansible.
- Additional public hostname `grafana.bagtrip.fr` (or `obs.bagtrip.fr`) routed by edge Caddy with basic auth.
- New `infra/dashboards/` and `infra/alerts/` shipped to Grafana / Prometheus by Ansible.

This document will be re-snapshotted at the end of Phase 8, to capture the post-rollout reality.
