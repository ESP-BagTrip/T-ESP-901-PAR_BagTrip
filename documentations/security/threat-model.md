# Threat model — BagTrip infrastructure (STRIDE)

> Status: **after-state (2026-04-27)**, updated once the observability
> deliverables landed. The "Before" column captures the 2026-04-26
> baseline (immediately after the incident). The "After" column reflects
> what is shipped today; deferred items are explicitly tagged.

## 0. Scope and trust boundaries

This model covers the BagTrip-managed surface on the production VPS:

```
[Internet]                                                      Trust boundary 0 (public)
   │
   ▼
[Cloudflare]                                                    Trust boundary 1 (CDN/WAF)
   │  (Origin TLS to VPS)
   ▼
[Caddy edge :443]  ──────────────────────────────────────────── Trust boundary 2 (edge)
   │
   ├── /opt/edge/Caddyfile  ──► HTTP routing by Host header
   ▼
[Inner Caddies on 127.0.0.1:80XX]                               Trust boundary 3 (per-stack)
   │
   ├── bagtrip prod        ──►  Next.js admin   +   FastAPI api   +   Postgres   +   Redis
   ├── bagtrip preprod     ──►  Next.js admin   +   FastAPI api   +   Postgres   +   Redis
   ▼
[Host VPS]                                                      Trust boundary 4 (kernel)
   │
   ├── systemd (CrowdSec, journald, shutdown-snapshot, Docker)
   └── /etc, /var/log, /opt
```

Out of scope for this document:

- Cloudflare WAF rules, account security (handled in the Cloudflare console).
- DNS hijacking (covered by registrar 2FA + Cloudflare).
- Any non-BagTrip workload colocated on the VPS.
- Mobile client (Flutter app) and its own threat surface.

## 1. STRIDE walk-through

For each STRIDE category we list the **threat**, **what mitigates it before** the work tracked in this repo, and **what will mitigate it after** the relevant control ships.

### S — Spoofing

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| S1 | Attacker impersonates a legitimate API client (steals JWT) | JWT signed (HS256), refresh-token rotation, 401 single-flight refresh | Same + RED metrics on `/v1/auth/refresh` exposed in API RED dashboard so a token-reuse storm shows up as a 401 spike. Falco rule on JWT signing key file access — config shipped, runtime deferred. | ✅ / 🟡 |
| S2 | Attacker impersonates the admin user via session theft | Cookies `Secure; HttpOnly; SameSite=Lax` | Same + Caddy edge access logs (JSON, 50 MB × 7 rotation) shipped to Loki via Promtail with structured `client_ip` / `host` labels — login attempts from new ASN are queryable in `BagTrip — Logs` dashboard. | ✅ |
| S3 | Phishing page on look-alike domain | Cloudflare DMARC/SPF | Out of scope (registrar / Cloudflare) | — |

### T — Tampering

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| T1 | Attacker writes a binary to a container's filesystem | Admin hardened post-26/04: `read_only: true`, `tmpfs:/tmp:noexec,nosuid`, `cap_drop:[ALL]`, `no-new-privileges:true` | Same hardening, **asserted by the `common` Ansible role on every deploy** (drift detection). Falco rule `BagTrip — Exec from temp directory` (rule committed, runtime deferred) catches the same pattern at the kernel level. | ✅ / 🟡 |
| T2 | Attacker modifies code or config on the host | `deploy` user owns `/opt/<stack>`, sudoers limited, SSH key-only | Same + Falco rule `BagTrip — Write to sensitive system path` (`/etc/cron`, `/etc/systemd`, `/usr/bin`, `/usr/local/bin`, `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`). Runtime deferred but rule is committed. | 🟡 |
| T3 | Supply-chain compromise via npm / pip / Docker image | None | **Trivy `fs` scan in CI**, fail-build on HIGH/CRITICAL with fixed versions; SARIF uploaded to GitHub code-scanning. Already paid off: 5 HIGH CVEs in `cryptography` / `langchain-core` / `orjson` / `pyasn1` / `urllib3` patched as a forcing-function effect of the gate landing. | ✅ |
| T4 | Attacker mutates DB rows via internal Postgres access | Postgres reachable only from within docker network; preprod password rotated post-incident | Same + Postgres metrics (`postgres_exporter` ×2) surface unexpected `tup_inserted` / `tup_updated` rates per database. Daily encrypted Restic backups. Egress allowlist (Falco / per-stack `internal: true` networks) is the deferred F6 item. | ✅ / 🟡 |

### R — Repudiation

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| R1 | Attacker actions on edge are not logged | Caddy access logs JSON to `/opt/edge/logs/access.log`, 50 MB × 7 (added 2026-04-26) | Promtail ships them to Loki, **queryable for 14 days** alongside container logs. A dedicated Caddy `/metrics` vhost surfaces request rate / 4xx / 5xx in Prom too. | ✅ |
| R2 | Inside-container actions are not logged | Docker `json-file` driver (already), journald for systemd | Promtail tails every BagTrip-managed container's stdout into Loki with extracted `service` / `env` / `level` / `trace_id` labels. Falco rules for `exec from tmp` / `dropper` / `shell from web server` ship as config; runtime deferred. | ✅ / 🟡 |
| R3 | Backup deletion goes unnoticed | None — backups don't exist yet | **Restic snapshots + restore drill** with three Prom alerts: `ResticBackupStale` (>26h), `ResticBackupFailed` (last attempt non-zero), `ResticRestoreDrillFailed` (drill itself failed). The drill alert is the strongest "are backups real?" signal. | ✅ |

### I — Information disclosure

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| I1 | Secrets leak via app logs | Pydantic `Settings` masks secrets, structlog JSON | Same. Log aggregation in Loki ships the structured JSON, making a future Loki-rule lint feasible. | ✅ |
| I2 | Secrets leak via Docker image layers | `.dockerignore`, multi-stage builds, secrets via env not COPY | Same + Trivy `fs` scan catches secret-shaped strings in any of the package files / Dockerfiles / compose files. | ✅ |
| I3 | Backup leaks if restic password is exposed | Backups don't exist yet | Restic password generated on first deploy, **persisted in `/opt/observability/.env` mode 0600 deploy:deploy**, never in git. The backup files themselves are encrypted by restic (AES-256). B2 escape hatch documented in ADR-0005. | ✅ |
| I4 | Attacker reads `/proc/<pid>/environ` of a peer container | Containers run as non-root with `cap_drop ALL` | Same. `userns-remap` on Docker daemon is the next step (post-M5). | — |

### D — Denial of service

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| D1 | Volumetric DDoS on edge | Cloudflare in front (DDoS L3/L4 absorbed) | Same. Caddy `rate_limit` plugin is the deferred F7 item (application-side work). | — |
| D2 | Slow-loris / connection exhaustion | Caddy default timeouts, FastAPI Uvicorn defaults | Same + alert `ApiLatencyDegraded` (p95 > 1 s for 10 min) catches the symptom. | ✅ |
| D3 | LLM cost exhaustion via SSE plan-trip endpoint | Auth-gated, no per-user rate limit | Business KPI panel (`SSE plan-trip — success vs error`) surfaces the rate; per-user limit is application work tracked in the hardening roadmap. | ✅ |
| D4 | Disk exhaustion via log ingestion | Docker log rotation (50 m × 5), journald `SystemMaxUse=2G`, Caddy access log rotation | **Loki retention 14 d**, **Tempo retention 14 d**, **Prom retention 30 d / 20 GB cap**. `HostDiskPressure` (warn < 15 %) and `HostDiskCritical` (page < 5 %) alert before anything fills. | ✅ |

### E — Elevation of privilege

| # | Threat | Before (2026-04-26) | After (2026-04-27) | Status |
|---|---|---|---|---|
| E1 | Container escape via kernel CVE | `cap_drop: [ALL]` + minimal `cap_add`, `no-new-privileges:true`, `read_only` fs | Same. `unattended-upgrades` enabled on the host. Trivy CI gate catches CVEs in package layers before deploy. | ✅ |
| E2 | Sudo escalation by a compromised host user | Only `ubuntu` (sudoer) and `deploy` (no sudo) accounts; root login disabled. CrowdSec ssh-bf scenarios already block scanning. | Same. The baseline Ansible role asserts these conditions on every deploy (drift detection). Auditd rules deferred. | ✅ |
| E3 | Docker socket access via a compromised container | Containers do not mount `/var/run/docker.sock` | Same. Promtail intentionally mounts the socket read-only for Docker SD; Falco mounts it for container metadata only. No application container does. | ✅ |
| E4 | Crontab / systemd timer hijack | Cron is minimal (`e2scrub_all`, `sysstat`); systemd timers vetted manually | Same + the DR layer adds two BagTrip-managed timers (`restic-backup.timer`, `restic-restore-test.timer`) — both rendered by Ansible, idempotent, file mode 0644 root:root. | ✅ |

## 2. Highlights from incident-2026-04-26

The post-mortem identified seven concrete gaps. The shipped controls
close all but two; the remaining items (F6 egress allowlist, F7
application rate limit) are tracked in the hardening roadmap.

| Gap from §2.2 of the post-mortem | STRIDE | Closing control | Status |
|---|---|---|---|
| F1 / F2 — No CVE scanner in CI | T3 | Trivy `fs` scan, fail on HIGH/CRITICAL with fixed version | ✅ shipped, 5 HIGH CVEs already patched |
| 2. Container without `read_only`, `noexec`, cap drop | T1, E1 | Done 26/04, asserted by the baseline Ansible role | ✅ shipped |
| 3. No HIDS catching dropper pattern | R2, T1 | Falco rules `Exec from temp dir`, `Suspicious dropper from web server` | ✅ rules; 🟡 runtime deferred |
| 4. No egress filtering | T4, D3 | Falco outbound rule + per-stack `internal: true` | 🟡 deferred |
| 5. No edge access logs | R1 | Promtail → Loki, dashboards 07 + 10 | ✅ shipped |
| 6. SSH un-rate-limited | E2 | Done 26/04 — CrowdSec | ✅ shipped |
| 7. No app-layer rate limit | D1, D3 | Application work — `api/src/middleware/rate_limit.py` exists; Caddy `rate_limit` plugin TBD | 🟡 partially shipped |

**Defense-in-depth at a glance**:

- **Edge** (Trust boundary 2): Cloudflare DDoS + Caddy access logs + iptables (only 22/80/443 public + the dedicated 8089 metrics vhost protected) + CrowdSec ssh-bf
- **Per-stack** (Trust boundary 3): inner Caddies on 127.0.0.1:80XX with PREROUTING DROP from non-lo, Postgres / Redis on private docker networks
- **Container** (Trust boundary 3 inner): `read_only` admin, `noexec` /tmp, `cap_drop:[ALL]`, `no-new-privileges:true`, asserted by Ansible
- **Supply chain** (CI): Trivy `fs` HIGH/CRITICAL gate, SARIF to GitHub code-scanning
- **Runtime** (Trust boundary 4): Falco rules committed (runtime deferred), audit fallback via journald + Promtail
- **DR** (orthogonal): Restic daily, restore drill weekly, three alerts

## 3. Residual risks accepted

| Risk | Why we accept it (for now) |
|---|---|
| Single-VPS architecture (no multi-region failover) | BagTrip pre-launch stage; Cloudflare cache softens user impact during downtime; out of M5 scope. |
| File-based secrets (`.env.production`) instead of HSM/KMS | Documented in `documentations/security/hardening-roadmap.md` §5; would be replaced before serving real users at scale. |
| Cloudflare is a single point of trust for DDoS / WAF | Industry-standard trade-off; offset by Cloudflare's own resilience. |

## 4. Update protocol

This document is updated when:

- A new STRIDE threat is identified (e.g. via incident, new feature, new external dependency).
- A control listed in "After" actually ships — flip the entry from "target" to "in place" with a date and a link to the Ansible role / dashboard / alert that proves it.
- The annual / semestral threat-model review concludes (target: every 6 months).

The "before" column is **historical** — it represents the 2026-04-26 baseline and should not be edited except to fix factual errors. New evolutions go into the "After" column with their landing date.

## 5. References

- `documentations/security/incident-2026-04-26-cryptominer.md`
- `documentations/security/hardening-roadmap.md`
- `documentations/adr/0001-observability-stack-strategy.md` — umbrella plan
- `documentations/adr/0003-defense-in-depth-incident-driven.md` — sequencing rationale
- `documentations/adr/0005-restic-local-with-b2-path.md` — DR strategy
- `infra/ansible/roles/observability_stack/templates/alerts/` — alert rules
- `infra/runbooks/` — runbooks linked from each alert
- STRIDE: Microsoft Threat Modeling: Designing for Security, Adam Shostack
