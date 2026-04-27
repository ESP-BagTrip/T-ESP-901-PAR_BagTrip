# M5 rubric mapping — what we ship vs what's graded

> Author: Yanis Lounadi · 2026-04-27 · cross-check this when
> preparing the soutenance Q&A.

The Master M5 (Epitech, "Architect & Lead Developer") rubric weighs
seven competency families. The table below maps each to the concrete
artefact in this repository.

| Rubric family | Sub-criterion | Where it lives |
|---|---|---|
| **Operate a production environment** | Multi-service stack | `compose.prod.yml` (api / admin / postgres / redis / inner Caddy) |
| | Reverse-proxy + TLS | `/opt/edge/Caddyfile` (managed by Phase 1c blockinfile) + Cloudflare Origin certs |
| | Container hardening | admin: `read_only`, `noexec`/tmp, `cap_drop:[ALL]`, `no-new-privileges` (verified by Phase 0 baseline role) |
| | Multi-environment | `bagtrip` prod ↔ `bagtrip-preprod` (separate compose, same Caddyfile, different env) |
| **Detect and respond to incidents** | Real incident with timeline | `documentations/security/incident-2026-04-26-cryptominer.md` |
| | Forensic discipline | post-mortem §6 (extract from `/proc/<pid>/exe`, `docker commit` before destroy) |
| | Triage + containment | post-mortem §1 timeline (10 min from alert → contained) |
| | Detection improvements | Phase 4 alert `ContainerCPUSustained` (5 min vs Netdata's 7h45 baseline) |
| | Runbook culture | 12 runbooks in `infra/runbooks/`, each linked from a `runbook_url` annotation |
| **Vulnerability management** | CVE identification | post-mortem §2.1 (CVE-2025-49826) |
| | Patch path | post-mortem §4.2 (no-cache rebuild + recreate) |
| | Continuous scanning | Phase 5a Trivy in CI, fails build on HIGH/CRITICAL |
| | Forcing-function effect | 5 HIGH CVEs patched as the Trivy gate landed |
| **Defense in depth** | Edge | Cloudflare DDoS + Caddy access logs + iptables limits + CrowdSec ssh-bf |
| | Per-stack | inner Caddies on 127.0.0.1:80XX + PREROUTING DROP from non-lo |
| | Container | `read_only`, `noexec`, `cap_drop`, `no-new-privileges` |
| | Supply chain | Trivy CI |
| | Runtime | Falco rules (config shipped, runtime deferred) |
| | DR | Restic + weekly drill + 3 alerts |
| | STRIDE before/after | `documentations/security/threat-model.md` |
| **Observability** | Metrics | Prometheus + 5 exporters + RED metrics for api / admin |
| | Logs | Loki + Promtail (23 containers, allowlist filtered) |
| | Traces | OTEL on FastAPI → Tempo (188+ spans verified) |
| | Cross-pillar correlation | `trace_id` label deeplinks Loki ↔ Tempo + Grafana service map |
| | Alerting | Alertmanager + 19 rules + 12 runbooks |
| | SLO + burn rate | `documentations/observability/slo.md` + multi-window burn alerts |
| | Business KPIs | `BagTrip — Business KPIs` dashboard (Phase 7) |
| **Reliability / DR** | Backups | Restic daily, encrypted, retention policy 7d/4w/6m |
| | **Tested** restore | Weekly automated drill into throwaway postgres + sanity SELECT |
| | Backup metrics + alerts | textfile collector + 3 alerts (stale, failed, drill failed) |
| | DR escape hatch | B2 toggle documented in ADR-0005 |
| **Industrialisation / IaC** | Single source of truth | Ansible role `infra/ansible/roles/observability_stack/` |
| | Idempotence | `ok=68 changed=0` on a converged host (Phase 8) |
| | Operator entry points | `infra/Makefile` |
| | Reproducibility demo | `make -C infra redeploy-demo` (50 s end-to-end) |
| | CI/CD | `.github/workflows/ci.yml` (lint / test / Trivy / coverage / Sonar) + `cd.yml` (auto-deploy on develop / main merge) |
| **Continuous improvement** | Hardening backlog | `documentations/security/hardening-roadmap.md` (live, marks shipped items) |
| | Decision records | 5 ADRs in `documentations/adr/` |
| | SLO review cadence | `slo.md` §6 — quarterly review |
| | Recurring chores | `hardening-roadmap.md` §4 |
| **Documentation deliverable** | Architecture | `documentations/architecture/` (infrastructure + observability + C4 + RGPD) |
| | Decisions | 5 ADRs |
| | Security | post-mortem + roadmap + threat model |
| | Operations | 12 runbooks |
| | Soutenance prep | `documentations/jury/` (this folder) |
| **Communication / post-mortem culture** | Blameless framing | post-mortem §7 — distinguishes "what worked" from "what didn't" without bashing prior choices |
| | Lessons committed | post-mortem §8 has tracked follow-ups with priorities + owners + due dates |
| | Cost / business framing | `documentations/jury/cost-comparison.md` |

## What's deferred (and why)

| Item | Why deferred | Where it's tracked |
|---|---|---|
| Falco runtime probe on this kernel | `scap_init` fails on Linux 6.14 + Falco 0.39 modern eBPF combo. Rules + config are in repo (`falco_rules.local.yaml.j2`); flip with `docker compose --profile security up`. | `infra/README.md` carry-overs, ADR-0003 |
| Egress allowlist (F6) | Requires enumerating every legitimate outbound (Stripe, Amadeus, OVH LLM, Sentry, Cloudflare). Multi-hour careful work; not blocking the demo. | `hardening-roadmap.md` |
| Application rate limiting (F7) | Already partially shipped (`api/src/middleware/rate_limit.py`); Caddy `rate_limit` plugin is the second layer. | `hardening-roadmap.md` |
| auditd | Adds another sink to maintain. Falco runtime once enabled covers most of the same threats. | `hardening-roadmap.md` |
| Off-site B2 backups | Requires a credit card on file. One-flag toggle in `group_vars/all.yml`. | ADR-0005 |
