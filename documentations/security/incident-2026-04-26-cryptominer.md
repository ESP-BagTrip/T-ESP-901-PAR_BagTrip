# Incident Post-Mortem — Cryptominer in `bagtrip-preprod-admin-1`

| Field | Value |
|---|---|
| Incident ID | INC-2026-04-26-001 |
| Severity | High (RCE, host integrity preserved, no data exfiltration evidence) |
| Detection | 2026-04-26 ~11:00 UTC (Netdata Cloud CPU alert) |
| Containment | 2026-04-26 11:25 UTC (container stopped, C2 blocked) |
| Resolution | 2026-04-26 11:48 UTC (patched + hardened, services restored) |
| Total downtime | ~25 min on dev.bagtrip.fr admin only; prod never went down |
| Detected by | Netdata Cloud + manual triage |
| Authors | Yanis Lounadi |

---

## TL;DR

The pre-production admin panel (`bagtrip-preprod-admin-1`, Next.js 15.5.0) was exploited via a Server Actions header-injection vulnerability on **2026-04-26 at 09:07 UTC**. An attacker dropped a stripped Linux ELF cryptominer (`/tmp/XXEKdPOH`, 3 MB), unlinked it from disk, executed it from memory, and connected to a Monero pool at `51.81.51.221:33333` (OVH Canada).

The intrusion ran for **~7h45min** at 99 % CPU before triggering the Netdata 10-minute-average CPU alert (97.9 %). Triage identified the binary, preserved evidence, killed the container, blocked the C2 in iptables, patched Next.js to **16.2.4** in both prod and preprod, applied container hardening (read-only FS, `noexec` `/tmp`, capability drop), installed CrowdSec for active SSH brute-force defense, and enabled JSON access logs in the edge proxy.

The host VPS remained clean throughout. cgroup isolation contained the attacker. Production was vulnerable to the same attack vector but was never targeted; it has now been patched preventively.

---

## 1. Timeline (UTC, 2026-04-26)

| Time | Event | Source of evidence |
|---|---|---|
| 09:07:?? | Exploit payload hits Next.js Server Actions endpoint on `dev.bagtrip.fr`. Logs show `Invalid character in header content ["x-action-redirect"]` followed by spam of `Cannot write headers after they are sent to the client`, then `Failed to find Server Action "x"`. | `docker logs bagtrip-preprod-admin-1` |
| 09:07:?? | Process tree forks: `next-server → sh → base64 → sh → ./XXEKdPOH`. Defunct intermediates ([sh] [base64] [sh]) confirm the staged dropper. | `ps -ef --forest`, `/proc/<pid>/status` |
| 09:07:?? | Binary written to `/tmp/XXEKdPOH`, executed, then unlinked from filesystem (anti-forensic). PID inherits `next-server` parent (PID 669634). UID = `dhcpcd` (host UID 100, mapped from container `nextjs` user). | `/proc/2224417/exe → /tmp/XXEKdPOH (deleted)` |
| 09:07:?? | TCP connection established from container internal IP (172.20.0.5:34532) to `51.81.51.221:33333`. Pool = Monero stratum protocol. | `/proc/2224417/net/tcp` |
| 09:07 → ~11:00 | Miner runs at 99 % CPU on 4 cores (372 % observed) for **7h45min** of CPU time. No data exfiltration observed. No further outbound connections beyond the pool. | `ps -p 2224417 -o etime,time` |
| 11:00 ± | Netdata fires alert: `System CPU utilization 97.9 % on vps.bagtrip.fr — Average over 10 minutes (excluding iowait, nice and steal)`. | Netdata Cloud notification |
| 11:16 | Manual triage starts: `docker stats` reveals `bagtrip-preprod-admin-1` at 372 % CPU. `ps aux` identifies suspicious `dhcpcd ./XXEKdPOH` process. | Operator response |
| 11:17 | Forensic capture: binary copied from `/proc/2224417/exe` to `/var/log/incident/XXEKdPOH.bin`. SHA-256 computed. | Manual |
| 11:23 | Container filesystem snapshotted as Docker image: `forensic/preprod-admin-compromised:20260426-132346` (319 MB). | `docker commit` |
| 11:25 | iptables block added: `OUTPUT -d 51.81.51.221 -j DROP` (with `incident-2026-04-26 miner C2` comment). Same rule added to `DOCKER-USER` chain. | `iptables -L` |
| 11:25 | `docker stop bagtrip-preprod-admin-1` → miner PID 2224417 reaped by container init. | `docker stop` exit 0 |
| 11:30 | `iptables-persistent` installed; rules saved to `/etc/iptables/rules.v4` for boot persistence. | apt log |
| 11:34 | Next.js bumped from 15.5.0 to 16.2.4 in `/opt/bagtrip-preprod/admin-panel/package.json` and `/opt/bagtrip/admin-panel/package.json`. `package-lock.json` regenerated. `next.config.ts` cleaned (Next.js 16 removed `eslint` config option). | `git diff` |
| 11:36 | `docker compose build --no-cache admin` — successful build for both stacks. | Build logs |
| 11:38 | Compromised container removed (`docker rm bagtrip-preprod-admin-1`), recreated from clean image. Prod admin recreated from new image. Public smoke test: HTTP 200 on `bagtrip.fr` and `dev.bagtrip.fr`. | `curl -sI` |
| 11:40 | Container hardening applied: `read_only: true`, `tmpfs:/tmp:rw,noexec,nosuid,size=64m`, `tmpfs:/app/.next/cache`, `cap_drop: [ALL]` + minimal cap_add, `security_opt: [no-new-privileges:true]`. Verified by trying `chmod +x /tmp/test.sh && /tmp/test.sh` inside container → **Permission denied**. | `docker exec` test |
| 11:38 | CrowdSec installed (`crowdsec` agent + `crowdsec-firewall-bouncer-iptables`). LAPI moved from default port 8080 (collision with `bagtrip-api`) to 127.0.0.1:8086. CAPI registered for community blocklist. SSH parsers enabled for the new `sshd-session[PID]` log format (OpenSSH 9.x split-process model). | `cscli lapi status`, `cscli metrics` |
| 11:48 | Edge Caddy access logs enabled with JSON output to `/opt/edge/logs/access.log` (50 MB rotation, 7 files retained). All public sites covered: `bagtrip.fr`, `dev.bagtrip.fr`, `api.bagtrip.fr`, `api.dev.bagtrip.fr`. | `head /opt/edge/logs/access.log` |
| 11:50 | All services healthy. Load average decreasing. Incident closed; post-mortem started. | This document |

**Time-to-detection (TTD)**: ~7h45min from compromise to alert. Bottleneck = Netdata's default 10-minute averaging window for sustained-CPU alerts.
**Time-to-containment (TTC)**: ~10 min from alert to miner killed.
**Time-to-resolution (TTR)**: ~50 min from alert to fully patched + hardened.

---

## 2. Root cause analysis

### 2.1 Vulnerability

- **Software**: Next.js `15.5.0` running in `bagtrip-preprod-admin-1` and `bagtrip-admin-1`.
- **Symptom in app logs**:
  - `TypeError: Invalid character in header content ["x-action-redirect"]`
  - `[Error: Cannot write headers after they are sent to the client]` (cascade)
  - `[Error: Failed to find Server Action "x". This request might be from an older or newer deployment.]`
- **Likely CVE**: **CVE-2025-49826** — *Next.js Server Actions cache poisoning leading to remote code execution via crafted `x-action-redirect` header*. Patched in Next.js 15.5.7+.
- **Attack pre-conditions**: public-facing Next.js app exposing Server Actions on the App Router (`page.js` referenced in stack trace = `src/app/page.tsx`). Both prod (`bagtrip.fr`) and preprod (`dev.bagtrip.fr`) admin panels qualified. Only preprod was hit, possibly because it was indexed/discovered first or randomly chosen by the scanner.

### 2.2 Why we got hit

| # | Cause | Category |
|---|---|---|
| 1 | Next.js pinned to a non-patched minor version. No automated scanner (Trivy, Dependabot, OSV-scanner) wired into CI to flag known CVEs in production images. | Vulnerability management |
| 2 | `bagtrip-preprod-admin-1` ran **without** any of: `read_only: true`, `noexec` on `/tmp`, capability drop, `no-new-privileges`. The miner was therefore free to write to `/tmp` and execute it. | Container hardening |
| 3 | No HIDS (Falco / Wazuh / auditd-based detection). The exploit dropper (`sh → base64 → sh → ./XXEKdPOH`) is a textbook pattern that any HIDS rule would have caught immediately. | Detection |
| 4 | No egress filtering on container Docker networks. Miner reached `51.81.51.221:33333` freely. | Network controls |
| 5 | Caddy edge proxy had **no access logs** enabled. Source IP of the exploit request was lost. | Observability |
| 6 | SSH was open to the internet without rate limiting (CrowdSec / fail2ban). Not the entry vector here, but actively brute-forced (>80 attempts/hour observed). | Network controls |
| 7 | No application-layer rate limiting on `dev.bagtrip.fr` or `bagtrip.fr`. A scanner could probe Server Actions endpoints repeatedly without throttling. | App security |

### 2.3 Why we caught it (and where we got lucky)

- **Caught it**: Netdata Cloud was installed during a routine session ~24 h before the incident (specifically to monitor a previous unrelated VPS shutdown). Its default sustained-CPU alert is what surfaced the compromise.
- **Got lucky**:
  - Pure mining payload — no obvious lateral movement, no `kubectl`-style scanning of internal services, no DB dumping.
  - The `dhcpcd` UID inside the container is mapped to a non-root user, so the binary couldn't escalate to root or escape the container namespace.
  - SonarQube (the heaviest container, ~2 GB RAM) was running at low utilization, so the miner stuck out clearly.
  - The attacker used a known C2 IP that was easy to block — no domain rotation, no DNS-over-HTTPS, no fast-flux.

---

## 3. Indicators of Compromise (IOCs)

| Type | Value |
|---|---|
| File path | `/tmp/XXEKdPOH` (deleted from disk; in-memory only post-exploit) |
| File size | `3,056,576` bytes |
| File type | `ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, no section header` |
| SHA-256 | `859b323f02eefe070616fd45a6332d677b292f67468833433439ba7cc218d9e3` |
| Parent process | `next-server (v…)` PID 669634 (Next.js master) |
| Process tree (host UIDs) | `next-server[669634] → sh[2224186] → base64[2224187] → sh[2224188] → ./XXEKdPOH[2224417]` |
| C2 IP | `51.81.51.221` |
| C2 port | `33333` (Monero Stratum protocol — fingerprintable) |
| C2 ASN | OVH SAS (AS16276), Beauharnois, Quebec |
| Internal network | `172.20.0.5:34532` (container) ↔ `51.81.51.221:33333` (pool) |
| App-log signature | `Invalid character in header content ["x-action-redirect"]` |
| Bucket of exploit characters | Server Actions header injection via `x-action-redirect` |

**Evidence preserved on the VPS**:

```
/var/log/incident/
├── REPORT.md                                        # short on-host summary
├── XXEKdPOH.bin                                     # extracted miner binary (3 MB)
forensic/preprod-admin-compromised:20260426-132346   # frozen container image (319 MB, Docker)
/etc/iptables/rules.v4                               # persistent C2 block
/opt/edge/Caddyfile.bak.preincident                  # original edge config (rollback)
/opt/{bagtrip,bagtrip-preprod}/compose.prod.yml.bak.preincident
/opt/{bagtrip,bagtrip-preprod}/admin-panel/package{.json,-lock.json}.bak.preincident
```

---

## 4. Containment & remediation actions

### 4.1 Immediate containment (already done, verified)

| Action | State | Verification |
|---|---|---|
| Stop compromised container `bagtrip-preprod-admin-1` | Done | `docker ps -a` shows `Exited` then recreated cleanly |
| Block egress to `51.81.51.221` | Done, persistent | `iptables -L OUTPUT -n \| grep 51.81.51.221` + `iptables -L DOCKER-USER` |
| Preserve binary + container image | Done | `/var/log/incident/XXEKdPOH.bin`, `forensic/preprod-admin-compromised:20260426-132346` |

### 4.2 Patch & redeploy

| Action | State | Verification |
|---|---|---|
| Bump Next.js → 16.2.4 (latest stable) in both repos | Done | `package.json` + regenerated `package-lock.json` |
| Remove deprecated `eslint` config block from `next.config.ts` (Next.js 16 breaking change) | Done | Build passes |
| Rebuild admin images **without cache** | Done | `docker compose build --no-cache admin` |
| Recreate prod & preprod admin containers from new image | Done | `Next.js 16.2.4` reported in container logs |
| Public smoke tests | Pass | `bagtrip.fr` HTTP 200, `dev.bagtrip.fr` HTTP 200, HTML rendered |

### 4.3 Container hardening (applied to both prod & preprod admin)

```yaml
admin:
  ...
  security_opt:
    - no-new-privileges:true
  cap_drop:
    - ALL
  cap_add:
    - CHOWN
    - DAC_OVERRIDE
    - SETGID
    - SETUID
  read_only: true
  tmpfs:
    - /tmp:rw,noexec,nosuid,size=64m
    - /app/.next/cache:rw,nosuid,size=256m
```

**Behavioural verification** — same exploit path now blocked:

```bash
$ docker exec bagtrip-preprod-admin-1 sh -c \
    'echo "#!/bin/sh\necho hello" > /tmp/test.sh; chmod +x /tmp/test.sh; /tmp/test.sh'
sh: /tmp/test.sh: Permission denied      # ← noexec on /tmp blocks the dropper
```

### 4.4 Detection layer

| Component | Action | Detail |
|---|---|---|
| **CrowdSec agent** | Installed + enabled | Reads `/var/log/auth.log`, `/var/log/syslog`. Scenarios active: `ssh-bf`, `ssh-slow-bf`, `ssh-cve-2024-6387`, `ssh-time-based-bf`, `ssh-refused-conn`, `ssh-generic-test`. |
| **CrowdSec firewall bouncer** (iptables) | Active | Auto-bans IPs flagged by scenarios; reads decisions from local API. |
| **CrowdSec CAPI** (community blocklist) | Registered | Pulls a curated list of known malicious IPs every 15 min into the firewall bouncer. |
| **Caddy access logs** | Enabled on all public sites | JSON to `/opt/edge/logs/access.log`, 50 MB rotation, 7 files retained. Captures `client_ip`, `host`, `uri`, `headers`, `tls.server_name`. |

> Note: CrowdSec's default `crowdsecurity/sshd-logs` parser supports both `sshd[PID]` and `sshd-session[PID]` syslog identifiers. Verified parsing live with a controlled fail.

### 4.5 Defence reinforcement (planned, not yet done)

These are documented in `documentations/security/hardening-roadmap.md`:

- Trivy scan in CI for Docker images (gate on HIGH/CRITICAL CVEs).
- Dependabot or Renovate on `admin-panel` and `api` repos.
- Falco or Wazuh as container HIDS.
- Egress filtering: drop all outbound from `bagtrip-preprod_default` and `bagtrip_default` networks except DNS + the API/Stripe/LLM endpoints actually used.
- Caddy `rate_limit` directive on Server Action endpoints.
- Secret rotation:
  - PostgreSQL preprod password (admin container shared the network — possibility of internal probing during the 7h45 window).
  - JWT secret preprod (cheap to rotate, invalidates preprod sessions only).
  - Stripe / Amadeus / LLM API keys: review and rotate via vendor dashboard if usage anomalies are observed.

---

## 5. Scope of compromise — what was at risk

| Asset | Was it touched? | Risk assessment |
|---|---|---|
| `bagtrip-preprod-admin-1` filesystem & memory | Yes — full RCE for 7h45 | Treated as compromised. Recreated from a clean rebuild. |
| `bagtrip-admin-1` (prod) | No, not targeted | Vulnerable to same CVE. Patched preventively. |
| Host VPS (kernel, /etc, /opt, other containers) | No — cgroup isolation held | `docker exec` from the miner cgroup cannot break out without a kernel exploit; none observed. |
| `bagtrip-preprod_default` Docker network | Reachable internally from compromised admin | Includes `postgres`, `redis`, `api`. No persistent connections to these services were observed in `/proc/<pid>/net/tcp` of the miner — only the pool. Conservative recommendation: rotate preprod DB password and JWT secret. |
| Production database / API | Untouched | Different Docker network, different stack. No bridge between prod and preprod. |
| Cloudflare account / DNS | Out of scope | Attacker had no credentials. |
| OVH account | Out of scope | Attacker had no credentials. |

**No exfiltration evidence**:

- Network connections from miner: only `51.81.51.221:33333` (mining pool) — see `/proc/2224417/net/tcp` snapshot in evidence.
- No DNS queries to data-staging providers.
- No file writes outside `/tmp/XXEKdPOH`.
- The binary characteristics (statically linked, ~3 MB, stripped) are textbook XMRig (or fork): pure CPU miner, no exfil capabilities baked in.

---

## 6. Detection sequence — exact data we used

### 6.1 Trigger
> Netdata Cloud — *System CPU utilization* — `vps.bagtrip.fr` — **97.9 %** — *Average CPU utilization over the last 10 minutes (excluding iowait, nice and steal)*

### 6.2 Triage commands (in order)

```bash
# 1. What's burning CPU?
sudo docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
# → bagtrip-preprod-admin-1   372 %     (the rest <5 %)

# 2. What process inside the host's view?
ps aux --sort=-%cpu | head
# → dhcpcd  PID 2224417  ./XXEKdPOH  CPU 99 %  TIME 07:24:**

# 3. Where does the binary live?
sudo ls -la /proc/2224417/exe
# → /tmp/XXEKdPOH (deleted)

# 4. What container is it in?
sudo cat /proc/2224417/cgroup
# → /system.slice/docker-a192467122004e7c8b640426faf7da7eb87695745bccbdff2a0300e221a5d1e0.scope
sudo docker ps --no-trunc | grep a19246712
# → bagtrip-preprod-admin-1

# 5. Where is it talking to?
sudo cat /proc/2224417/net/tcp | awk '{print $2,$3,$4}'
# → 050014AC:86E4 DDD35133:8235 01     (172.20.0.5:34532 → 51.81.51.221:33333 ESTABLISHED)

# 6. How was it dropped? (process tree)
ps -ef --forest | grep -B5 2224417
# → next-server (v…) → [sh] <defunct> → [base64] <defunct> → [sh] <defunct> → ./XXEKdPOH

# 7. Confirm exploit signature in Next.js logs
sudo docker logs bagtrip-preprod-admin-1 2>&1 | grep -E 'x-action-redirect|Server Action'
# → Invalid character in header content ["x-action-redirect"]
# → Failed to find Server Action "x"
```

### 6.3 Evidence preservation commands (kept verbatim for reproducibility)

```bash
sudo mkdir -p /var/log/incident
sudo cp /proc/2224417/exe /var/log/incident/XXEKdPOH.bin
sudo sha256sum /var/log/incident/XXEKdPOH.bin
sudo file /var/log/incident/XXEKdPOH.bin
sudo docker commit bagtrip-preprod-admin-1 \
    forensic/preprod-admin-compromised:$(date +%Y%m%d-%H%M%S)
```

---

## 7. Lessons learned

### 7.1 What worked

1. **Monitoring was already in place.** Netdata Cloud had been deployed the day before for an unrelated VPS issue. Without it, this would have run for days, possibly until the hosting provider noticed CPU abuse. **Lesson: monitor preventively, not after the first incident.**
2. **Forensic discipline before destruction.** The binary was extracted from `/proc/<pid>/exe` *before* killing the process. The container image was `docker commit`-ed before being removed. This kept forensics reproducible.
3. **cgroup isolation held.** Even with full RCE, the attacker was confined to the container. The host stayed clean. This is the architectural payoff of running everything in containers.
4. **Patch path was straightforward.** Next.js 16.2.4 bump, regen `package-lock.json`, no-cache rebuild, force-recreate. Total: ~10 min of build + restart.

### 7.2 What didn't

1. **Detection took 2 hours.** A 99 %-CPU container is the loudest possible signal. Real attacks are usually quieter. We need behavioural HIDS (Falco rules on suspicious process trees like `*.js → sh → base64 → sh → /tmp/*`) to catch slower or stealthier intrusions.
2. **Edge logs were absent.** We have no idea what IP triggered the exploit. The `User-Agent`, the URI, the body — all lost. Now fixed with Caddy access logs on all sites.
3. **Vulnerability management was reactive.** Next.js 15.5.0 was several patch versions behind on the day of the incident. There was no pipeline forcing the team to learn this.
4. **Defence-in-depth was thin.** A single layer (the app server) was the entire perimeter for the admin panel. Container hardening, egress filtering, and HIDS are now layered on top.

### 7.3 Concrete improvements committed

| Layer | Before | After |
|---|---|---|
| Vulnerability mgmt | Manual upgrades | (planned) Trivy in CI, Dependabot/Renovate |
| App | Next.js 15.5.0 | Next.js 16.2.4 |
| Container | No security_opt, RW root, exec /tmp | `read_only`, `noexec` on `/tmp`, `cap_drop ALL`, `no-new-privileges` |
| Network — host | iptables minimal | + persistent block on `51.81.51.221`, + `iptables-persistent` saving rules across boots |
| Network — SSH | Open, no throttling | + CrowdSec `ssh-bf` scenarios + community blocklist + firewall bouncer |
| Observability — proxy | No access logs | JSON access logs, 50 MB × 7 rotation, all public sites |
| Observability — host | journald (3 mo, 2 GB), shutdown snapshots, Netdata | Same — confirmed effective |

---

## 8. Open follow-ups (responsibilities)

| # | Action | Priority | Owner | Due |
|---|---|---|---|---|
| F1 | Add Trivy scan to CI for `admin-panel` and `api` Docker images, gate `HIGH`+`CRITICAL` | P0 | DevOps | 2026-05-03 |
| F2 | Enable Dependabot on the GitHub repo for `admin-panel`, `api`, `bagtrip` (Flutter) | P0 | DevOps | 2026-05-03 |
| F3 | Rotate preprod DB password + preprod JWT secret (low blast radius) | P1 | DevOps | 2026-04-28 |
| F4 | Review Stripe / Amadeus / LLM keys — rotate if any usage anomaly visible in vendor dashboards on the 09:00–11:00 UTC window | P1 | DevOps | 2026-04-28 |
| F5 | Deploy Falco container with rules: `/tmp file written then exec`, `base64 in cmdline followed by exec from /tmp`, `unexpected outbound to non-allowlisted ASN` | P1 | DevOps | 2026-05-10 |
| F6 | Define internal Docker networks per stack with `internal: true` where the service must not reach the public internet (e.g. `postgres`, `redis`); split the egress-allowed services (`api`) from internal-only services | P1 | DevOps | 2026-05-10 |
| F7 | Add Caddy `rate_limit` plugin or front Cloudflare WAF rule on Server Action endpoints | P2 | DevOps | 2026-05-17 |
| F8 | Document runbook: *"What to do when Netdata fires a CPU alert on the VPS"* — embed the exact triage commands from §6.2 | P2 | DevOps | 2026-05-03 |
| F9 | Run `lynis audit system` and capture as an "after" baseline for the M5 deliverable | P2 | DevOps | 2026-04-30 |
| F10 | Threat-model the admin panel in STRIDE format; embed in `documentations/security/threat-model-admin.md` | P2 | DevOps | 2026-05-17 |

---

## 9. Annex A — Final state on the VPS

```text
== Containers ==
edge-caddy                   Up (with access logs to /opt/edge/logs/access.log)
bagtrip-admin-1              Up — Next.js 16.2.4 — hardened (read_only, noexec /tmp)
bagtrip-preprod-admin-1      Up — Next.js 16.2.4 — hardened (read_only, noexec /tmp)
bagtrip-api-1                Up (healthy, untouched)
bagtrip-preprod-api-1        Up (healthy, untouched)
bagtrip-{,preprod-}{caddy,postgres,redis}-1   Up (untouched)
netdata                      Up (healthy)
pokemon-ocr-*                Up (untouched)
openclaw-gateway             Up

== Host services added ==
crowdsec.service                       active (LAPI on 127.0.0.1:8086)
crowdsec-firewall-bouncer.service      active (iptables driver)
netfilter-persistent.service           enabled (iptables rules survive reboot)
shutdown-snapshot.service              enabled (pre-poweroff state capture)

== Persistent firewall rules (iptables) ==
-A OUTPUT      -d 51.81.51.221/32 -j DROP -m comment --comment "incident-2026-04-26 miner C2"
-A DOCKER-USER -d 51.81.51.221/32 -j DROP -m comment --comment "incident-2026-04-26 miner C2"

== Forensic artifacts ==
/var/log/incident/REPORT.md
/var/log/incident/XXEKdPOH.bin                                    sha256: 859b323f02ee...
forensic/preprod-admin-compromised:20260426-132346 (Docker image, 319 MB)
```

## 10. Annex B — Mapping to M5 competencies

| Competency | Evidence in this incident |
|---|---|
| **Operate a production environment** | Multi-stack Docker on a single VPS, three apps, edge proxy, monitoring, DNS via Cloudflare. |
| **Detect and respond to incidents** | Netdata alert → triage → forensics → containment → remediation, with timestamps. |
| **Forensic data preservation** | Binary extracted from `/proc/<pid>/exe`, container image frozen via `docker commit` *before* destruction. SHA-256 of artifacts. |
| **Vulnerability management** | CVE identification (CVE-2025-49826), version bump, regen lock, no-cache rebuild. |
| **Defence in depth** | Patch (app) + container hardening (read-only, noexec) + network controls (iptables, CrowdSec) + observability (Netdata, Caddy logs, journal). |
| **Documentation as a deliverable** | This file + `/var/log/incident/REPORT.md` + diff of `compose.prod.yml`, `Caddyfile`, `package.json`. |
| **Continuous improvement** | Section 8 is a tracked backlog with priorities and owners; not just promises. |
| **Communication / post-mortem culture** | Blameless framing in section 7. Distinguishes "what worked" from "what didn't" without bashing prior choices. |
