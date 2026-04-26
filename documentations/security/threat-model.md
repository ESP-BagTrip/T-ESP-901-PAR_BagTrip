# Threat model — BagTrip infrastructure (STRIDE)

> Status: **before-state baseline (2026-04-26)**, written immediately after the cryptominer incident.
> The "After" column is filled in progressively as Phases 1–7 of the M5 observability plan land.

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

For each STRIDE category we list the **threat**, **what mitigates it before** the work tracked in this repo, and **what will mitigate it after** the relevant phase ships.

### S — Spoofing

| # | Threat | Before (2026-04-26) | After (target) | Phase |
|---|---|---|---|---|
| S1 | Attacker impersonates a legitimate API client (steals JWT) | JWT signed (HS256), refresh-token rotation, 401 single-flight refresh | Same + Falco rule on JWT signing key access (file `read` on the secret outside `api` container) | 5 |
| S2 | Attacker impersonates the admin user via session theft | Cookies `Secure; HttpOnly; SameSite=Lax` (in app code) | Same + alerting on admin login from new ASN (Loki rule on Caddy access logs) | 4 |
| S3 | Phishing page on look-alike domain | Cloudflare DMARC/SPF on `bagtrip.fr` | Out of scope (handled at registrar/Cloudflare) | — |

### T — Tampering

| # | Threat | Before | After | Phase |
|---|---|---|---|---|
| T1 | Attacker writes a binary to a container's filesystem | **No protection on `bagtrip-preprod-admin` until 2026-04-26**; admin is now `read_only: true`, `tmpfs:/tmp:noexec,nosuid` | Same + Falco rule "exec from tmpfs" + Trivy scan in CI to block vulnerable images at the supply-chain level | 5 |
| T2 | Attacker modifies code or config on the host | `deploy` user owns `/opt/<stack>`, sudoers limited, SSH key-only | Same + auditd rules on `/etc`, `/opt/edge`, `/opt/bagtrip*`, alerts in Loki when a `write` event fires | 5 |
| T3 | Supply-chain compromise via an upstream npm/pip/Docker image | None | Trivy + Dependabot/Renovate (CI gate) + image digest pinning in `compose.prod.yml` | 5 |
| T4 | Attacker mutates DB rows directly via internal Postgres access | Postgres reachable only from within Docker network; password-protected; preprod password rotated post-incident | Same + egress filtering on each service network so a compromised admin cannot reach the DB without going through `api` | 5 |

### R — Repudiation

| # | Threat | Before | After | Phase |
|---|---|---|---|---|
| R1 | Attacker actions on edge are not logged | Caddy access logs JSON to `/opt/edge/logs/access.log`, 50 MB × 7 (added 2026-04-26) | Same + Promtail ships them to Loki, queryable for 14 days | 2 |
| R2 | Inside-container actions are not logged | Docker `json-file` driver (already), journald for systemd, no per-process trail | Same + Falco emits a structured event for every "interesting" syscall (exec from /tmp, write to /etc, outbound to non-allowlisted) → Promtail → Loki | 5 |
| R3 | Backup deletion goes unnoticed | None (backups don't exist yet) | Restic snapshots are append-only on B2 + `restic_last_successful_backup_timestamp` exporter alerts on freshness | 6 |

### I — Information disclosure

| # | Threat | Before | After | Phase |
|---|---|---|---|---|
| I1 | Secrets leak via app logs | Pydantic `Settings` masks secrets, structlog JSON, no f-strings on secret fields | Same + Loki query lints (`bandit`-style scan over recent 24 h of logs once a week) | 4 |
| I2 | Secrets leak via Docker image layers | `.dockerignore`, multi-stage builds, secrets via env not COPY | Trivy "secrets scan" enabled on every image build | 5 |
| I3 | Backup leaks if restic password is on the same host | Backups don't exist yet | Restic encryption key kept off-VPS (1Password / vault); B2 bucket public-write disabled | 6 |
| I4 | Attacker reads `/proc/<pid>/environ` of a peer container | Containers run as non-root with `cap_drop ALL`, but admin and api share host kernel namespace | Same + future: tighten admin network isolation; consider `userns-remap` on Docker daemon | 5+ |

### D — Denial of service

| # | Threat | Before | After | Phase |
|---|---|---|---|---|
| D1 | Volumetric DDoS on edge | Cloudflare in front (DDoS L3/L4 absorbed) | Same + Caddy rate-limit plugin on `/api/*` and Server Action endpoints | 5 |
| D2 | Slow-loris / connection exhaustion | Caddy default timeouts, FastAPI Uvicorn defaults | Same + per-IP connection caps in Caddy | 5 |
| D3 | LLM cost exhaustion via SSE plan-trip endpoint | Auth-gated, but no per-user rate limit | Per-user + per-IP limit in FastAPI middleware (Redis token bucket) + alert when error budget burn rate spikes | 4 |
| D4 | Disk exhaustion via log ingestion | Docker log rotation (50 m × 5), journald `SystemMaxUse=2G`, Caddy access log rotation | Same + Loki retention 14 d + `disk_used_percent` alert | 1 |

### E — Elevation of privilege

| # | Threat | Before | After | Phase |
|---|---|---|---|---|
| E1 | Container escape via kernel CVE | `cap_drop: [ALL]` + minimal `cap_add` on admin (post-2026-04-26); `no-new-privileges:true`; `read_only` fs | Same + auto-applied unattended-upgrades on the host (already on) + alert when kernel reboot needed | 5 |
| E2 | Sudo escalation by a compromised host user | Only `ubuntu` (sudoer) and `deploy` (no sudo) accounts; root login disabled | Same + auditd rule on `sudo` invocations not from `ubuntu`'s SSH session | 5 |
| E3 | Docker socket access via a compromised container | Containers do not mount `/var/run/docker.sock` | Same — verify per-stack via Ansible assertion in the `common` role (added Phase 0) | 0 / 5 |
| E4 | Crontab / systemd timer hijack | Cron is minimal (`e2scrub_all`, `sysstat`); systemd timers vetted manually | Same + Ansible role `common` enumerates expected timers and asserts no extras | 5 |

## 2. Highlights from incident-2026-04-26

The post-mortem identified seven concrete gaps. Mapping them onto STRIDE makes it explicit how each phase of the observability plan closes them:

| Gap from §2.2 of the post-mortem | STRIDE | Closing phase |
|---|---|---|
| 1. No CVE scanner in CI | T3 | Phase 5 (Trivy + Dependabot) |
| 2. Container without `read_only`, `noexec`, cap drop | T1, E1 | Done 2026-04-26 (assertion in Phase 0 role, kept honest by Ansible) |
| 3. No HIDS catching `*.js → sh → base64 → sh → /tmp/*` | R2, T1 | Phase 5 (Falco) |
| 4. No egress filtering | T4, D3 | Phase 5 (network policy) |
| 5. No edge access logs | R1 | Done 2026-04-26 (shipped to Loki in Phase 2) |
| 6. SSH unrate-limited | E2 | Done 2026-04-26 (CrowdSec) |
| 7. No app-layer rate limit | D1, D3 | Phase 5 (Caddy rate_limit + FastAPI middleware) |

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
- `documentations/adr/0001-observability-stack-strategy.md`
- STRIDE: Microsoft Threat Modeling: Designing for Security, Adam Shostack
