# Security Hardening Roadmap

This roadmap captures the remaining defence-in-depth work surfaced by the **2026-04-26 cryptominer incident** (`incident-2026-04-26-cryptominer.md`) and prior hardening passes.

It is the live source of truth for the M5 security deliverable. Items that are already done sit in §0 ("baseline"), so the document doubles as an inventory of *what protects the BagTrip infrastructure today*.

> Convention: ✅ = done and verified, 🚧 = in flight, ⏳ = planned, 🔁 = recurring.

---

## 0. Current baseline (already in place)

### 0.1 Edge / network

| Layer | Control |
|---|---|
| ✅ TLS termination | Caddy 2 (`edge-caddy`) with Cloudflare-issued origin certs (`/opt/edge/certs/`). HSTS preloaded. |
| ✅ Security headers | `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `-Server` — applied to all public sites via `(security_headers)` snippet. |
| ✅ Reverse proxy isolation | Each stack (`bagtrip`, `bagtrip-preprod`, `pokemon-ocr`) runs its own internal Caddy bound to `127.0.0.1:80XX`, never directly internet-facing. |
| ✅ Inbound firewall | iptables minimal stance (only 22, 80, 443 reachable). |
| ✅ C2 outbound block | `iptables -A OUTPUT/DOCKER-USER -d 51.81.51.221 -j DROP`, persisted via `iptables-persistent`. |
| ✅ SSH brute-force defence | CrowdSec agent + firewall bouncer + community blocklist (CAPI). Scenarios: `ssh-bf`, `ssh-slow-bf`, `ssh-cve-2024-6387`, `ssh-time-based-bf`, `ssh-refused-conn`, `ssh-generic-test`. |
| ✅ SSH user hygiene | Only `ubuntu` (sudoer) and `deploy` (deployment) accounts; root login disabled by `sshd_config`; key-based auth only. |
| ✅ Edge access logs | Caddy JSON logs to `/opt/edge/logs/access.log` (50 MB rotation × 7) for `bagtrip.fr`, `dev.bagtrip.fr`, `api.bagtrip.fr`, `api.dev.bagtrip.fr`. |

### 0.2 Application / container

| Layer | Control |
|---|---|
| ✅ Next.js admin patched | Both `bagtrip-admin-1` and `bagtrip-preprod-admin-1` on **16.2.4** (latest stable as of 2026-04-26). |
| ✅ Container hardening (admin) | `read_only: true`, `tmpfs:/tmp:rw,noexec,nosuid,size=64m`, `tmpfs:/app/.next/cache:rw,nosuid,size=256m`, `cap_drop: [ALL]` + minimal `cap_add`, `security_opt: [no-new-privileges:true]`. |
| ✅ Non-root container UIDs | Next.js admin runs as `nextjs` (UID 1001 → mapped to `dhcpcd` UID 100 on host, no shell, no privileges). |
| ✅ Stack network segmentation | Each compose stack has its own bridge network (no cross-traffic between bagtrip / bagtrip-preprod / pokemon-ocr without explicit setup). |

### 0.3 Observability / detection

| Layer | Control |
|---|---|
| ✅ Metrics | Netdata agent local + Netdata Cloud. CPU / memory / disk / network / per-container, with default sustained-CPU alerts. |
| ✅ Public dashboard | `https://monitoring.bagtrip.fr` behind HTTP basic auth on Caddy edge. |
| ✅ Persistent host logs | systemd-journald with `Storage=persistent`, `SystemMaxUse=2G`, `MaxRetentionSec=3month`. |
| ✅ Pre-shutdown snapshot | `/usr/local/bin/shutdown-snapshot.sh` invoked by `shutdown-snapshot.service` before poweroff — captures `top`, `docker ps`, `dmesg`, network state, recent journal. |
| ✅ Docker log rotation | `/etc/docker/daemon.json` configured for `json-file` driver, `max-size: 50m`, `max-file: 5`. |
| ✅ Edge access logs | (see §0.1) |

### 0.4 Process / governance

| Layer | Control |
|---|---|
| ✅ Forensic playbook | Documented in `incident-2026-04-26-cryptominer.md` §6.2 — extract binary from `/proc`, freeze container image, then kill. |
| ✅ Persistent IOC blocks | `iptables-persistent` ensures any C2 IP we add survives reboots. |

---

## 1. Top of backlog (priority P0 — by 2026-05-03)

### 1.1 Trivy scan in CI

**Goal**: never deploy an image with a known `HIGH` or `CRITICAL` CVE again.

**Acceptance**:

- A GitHub Actions step runs `aquasecurity/trivy-action` on `admin-panel`, `api`, and the final composed images.
- The job fails on `HIGH`/`CRITICAL` unless the CVE is in `.trivyignore` with a justification comment and an expiry date.
- The Trivy SARIF report is uploaded to GitHub code scanning so vulnerabilities show up in the Security tab.

**Scope of work**: ~half a day, scoped to one PR per repo.

### 1.2 Dependabot / Renovate

**Goal**: catch the next *Next.js 15.5.0 → 15.5.7* style patch automatically and have a PR opened with a green CI before a human even hears about the CVE.

**Acceptance**:

- `.github/dependabot.yml` enabled for `admin-panel/package.json`, `api/pyproject.toml`, `bagtrip/pubspec.yaml`. Daily for security, weekly for everything else.
- PRs auto-merge when CI is green for patch versions on dev dependencies.

### 1.3 Rotate preprod secrets

**Goal**: close the (low-likelihood, high-blast-radius) hypothesis that the miner pivoted internally.

**Plan**:

1. Generate a new strong password for `bagtrip` Postgres user inside the preprod compose.
2. Run `ALTER USER bagtrip WITH PASSWORD '<new>';` inside `bagtrip-preprod-postgres-1`.
3. Update `/opt/bagtrip-preprod/.env.production` with the new password.
4. Restart `api` (and any worker) so they pick up the new env. Admin doesn't need it.
5. Generate a new `JWT_SECRET` (32+ bytes, `openssl rand -hex 32`) and update env. This invalidates all preprod sessions, which is intended.
6. Stripe / Amadeus / LLM keys: only rotate if a usage anomaly is visible in the vendor dashboard for the 09:00–11:00 UTC window of 2026-04-26.

---

## 2. Mid-term (P1 — by 2026-05-10)

### 2.1 Container HIDS — Falco

**Why**: a 99 %-CPU miner is the loudest possible signal. Real attackers won't be that obvious. We need behavioural detection.

**Rules to ship on day 1**:

```yaml
- rule: Suspicious dropper from web server
  desc: Web server (Next.js / FastAPI) spawns base64-then-shell pattern.
  condition: >
    spawned_process and
    proc.pname in (next-server, node, uvicorn, gunicorn) and
    (proc.cmdline contains "base64 -d" or proc.cmdline contains "curl ... | sh")
  output: "Suspicious dropper (parent=%proc.pname cmd=%proc.cmdline)"
  priority: CRITICAL

- rule: Execute from /tmp inside container
  desc: Any process exec'd from /tmp, /var/tmp, /dev/shm.
  condition: spawned_process and proc.exepath startswith ("/tmp/", "/var/tmp/", "/dev/shm/")
  output: "Exec from temp dir (path=%proc.exepath cmd=%proc.cmdline)"
  priority: CRITICAL

- rule: Outbound to non-allowlisted host
  desc: Container connects to an IP that is not API/DNS/Stripe/etc.
  condition: outbound and not fd.sip in (allowed_egress)
  priority: WARNING
```

**Acceptance**: when we replay the incident on a sandbox container (with the exploit binary still in `/var/log/incident/`), Falco fires on all three rules within 1 second of `./XXEKdPOH` starting.

### 2.2 Egress filtering

**Why**: the miner reached the pool because nothing stopped it. A no-op egress allowlist would have made the binary worthless even after it ran.

**Plan**:

- Each stack already has its private bridge network.
- Mark networks `internal: true` for services that don't need internet (`postgres`, `redis`).
- Services that *do* need internet (`api`) get an explicit list of FQDNs or IP ranges via a sidecar (egress proxy or netfilter rules tied to cgroups).
- Admin (Next.js) has no legitimate outbound to the internet — block all egress at the network layer.

**Acceptance**: re-run the same compromised image with hardening from §1.4 of the incident report; confirm the miner's connect() to `51.81.51.221:33333` returns `EHOSTUNREACH`.

### 2.3 Caddy rate limiting on Server Action endpoints

**Why**: even patched, Server Actions are an attack surface. Throttle aggressive scanners.

**Plan**:

- Use the [Caddy `rate_limit` plugin](https://github.com/mholt/caddy-ratelimit).
- Apply to `bagtrip.fr/api/*`, `dev.bagtrip.fr/api/*`, and the Next.js Server Action POST endpoints.
- Limits: 60 req/min per IP, 1000 req/min per /24, 10 req/min on `/api/auth/*` and any Server Action POST.

### 2.4 Threat model — admin panel (STRIDE)

**Goal**: explicit STRIDE walk-through for the admin app + edge proxy + auth flow. Output: `documentations/security/threat-model-admin.md`.

---

## 3. Long-term (P2 — by 2026-05-17)

### 3.1 Centralised log aggregation

- Stand up a single-node Loki instance (or use Grafana Cloud free tier).
- Ship: edge Caddy access logs, container stdout (already in `json-file`), CrowdSec decisions, journald sshd events.
- Goal: one place to query "every 4xx on `dev.bagtrip.fr` between 08:00 and 09:30 UTC of 2026-04-26".

### 3.2 Backup + restore drill

- `restic` daily snapshot of `bagtrip-postgres-1`, `bagtrip-preprod-postgres-1`, `pokemon-ocr-postgres-1` to off-VPS storage (Backblaze B2 or Hetzner Storage Box).
- Encrypted with a key not stored on the VPS (kept in 1Password / vault).
- Quarterly: restore a snapshot into a throwaway container, run `psql -c "SELECT count(*) FROM users"` as smoke test. Document RTO/RPO.

### 3.3 Status page & uptime monitoring

- External (independent of the VPS) monitoring on `bagtrip.fr`, `api.bagtrip.fr`, `dev.bagtrip.fr`, `api.dev.bagtrip.fr`, `admin.bagtrip.fr`, `monitoring.bagtrip.fr` — UptimeRobot or BetterStack free tier.
- Public status page (BetterStack, Statping-NG, or similar) — communicates incidents to users.

### 3.4 SLO / SLI baseline

- Define: "API 5xx rate < 0.5 % monthly", "edge p95 latency < 800 ms", "admin TLS valid > 7 d before expiry".
- Wire alerts into Netdata or Grafana on top of the metrics already collected.

---

## 4. Recurring chores (🔁)

| Cadence | Task | Where |
|---|---|---|
| 🔁 Weekly | Review CrowdSec decisions: `cscli decisions list` — make sure no false positive bans are eating legitimate traffic | VPS |
| 🔁 Weekly | Skim Netdata anomaly detection page for the past 7 days | Netdata Cloud |
| 🔁 Monthly | Run `lynis audit system` and diff against last month's baseline | VPS |
| 🔁 Monthly | Run Trivy against the *running* containers (not just CI images) — catches CVEs that landed after deploy | VPS or local |
| 🔁 Quarterly | Restore-from-backup drill (§3.2) — must succeed end-to-end | Throwaway VPS or local |
| 🔁 Quarterly | Update CrowdSec hub: `cscli hub upgrade` | VPS |

---

## 5. Out of scope for now (deliberate)

- **HSM / KMS for production secrets**. Current secrets are file-based (`.env.production`); good enough for a Master's project, would be replaced by a vault solution before serving real users.
- **Multi-region failover**. Single-VPS architecture is acceptable for the BagTrip pre-launch stage.
- **WAF (e.g. CrowdSec WAF, Coraza)**. Cloudflare in front of the edge already provides bot challenge + basic WAF. Adding our own would duplicate work for marginal gain at this scale.
- **Kubernetes / Nomad migration**. Docker Compose is sufficient and operationally familiar; Kubernetes would add attack surface (etcd, API server) without solving any current problem.

---

## 6. Mapping to M5 jury rubric

| Rubric criterion | Where this roadmap shows it |
|---|---|
| Operate a production environment | §0 (the running baseline) |
| Detect & respond to incidents | `incident-2026-04-26-cryptominer.md` (companion document) |
| Defence in depth | §0 + §1 + §2 + §3 (all four layers: edge, app, container, observability) |
| Industrialisation | §1.1 Trivy + §1.2 Dependabot + §3.2 backup automation |
| Continuous improvement | §4 recurring chores + §1–3 priorities + §6 self-assessment |
| Documentation deliverable | This file + the incident post-mortem + (planned) the threat model |
