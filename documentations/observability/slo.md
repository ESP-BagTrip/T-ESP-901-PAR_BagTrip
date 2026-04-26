# Service-Level Objectives — BagTrip

> Status: **draft baseline**, established 2026-04-26 as part of the M5 observability plan (Phase 0).
> Targets will be re-tuned once we have 30 days of Prometheus history (Phase 4 review).

## Purpose

SLOs translate the user-facing promise into numeric targets we can alert on. Without them, alert thresholds are arbitrary ("CPU > 90 %") and pages happen for things users don't actually feel.

Each SLO below states:

- **Service** — the user-perceived surface
- **SLI** — what we measure (a ratio over time, computed from Prometheus / Loki / blackbox probes)
- **SLO** — the target (e.g. 99.5 % over 30 days)
- **Error budget** — the inverse: how much "bad" we tolerate before paging
- **Burn-rate alerts** — the multi-window alerting we'll wire in Phase 4

## 1. BagTrip API (`api.bagtrip.fr`)

| Field | Value |
|---|---|
| Service | Public REST + SSE API consumed by the Flutter app |
| User-perceived promise | "The app responds quickly and rarely errors" |

### 1.1 Availability

- **SLI**: `1 - (sum(rate(http_requests_total{job="bagtrip-api", code=~"5..", path!="/health"}[5m])) / sum(rate(http_requests_total{job="bagtrip-api", path!="/health"}[5m])))`
- **SLO**: ≥ 99.5 % over a rolling 30-day window
- **Error budget**: 0.5 % → ~3.6 hours of "all 5xx, all the time" per 30 days, more realistically a few short outages
- **Burn-rate alerts** (Phase 4):
  - Page if budget burns at 14× rate over 1 h *and* over 5 m (fast burn)
  - Ticket if budget burns at 3× rate over 6 h *and* over 30 m (slow burn)

### 1.2 Latency (p95)

- **SLI**: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="bagtrip-api", path!~"/health|/metrics", path!~".*stream.*"}[5m])) by (le))`
- **SLO**: p95 < 500 ms over a rolling 30-day window for non-streaming endpoints
- **Note**: SSE endpoints (`/agent/plan-trip-stream`) intentionally hold connections open — excluded from this SLI; tracked separately in §1.4
- **Alert**: page if p95 > 1 s for 10 min

### 1.3 SSE trip planner success rate

- **SLI**: `1 - (sum(rate(sse_trip_planner_terminated_total{outcome="error"}[5m])) / sum(rate(sse_trip_planner_terminated_total[5m])))`
- **SLO**: ≥ 98 % of SSE plan-trip streams reach `done` without an `error` event over a rolling 7-day window
- **Rationale**: the LangGraph agent occasionally hits LLM rate limits or budget exhaustion; 2 % is the budget for those before we flag a regression
- **Alert**: ticket if error rate > 5 % for 30 min

### 1.4 SSE end-to-end latency

- **SLI**: time from request acceptance to first `proposal_ready` event, p95
- **SLO**: p95 < 8 s, p99 < 20 s over rolling 7 days
- **Alert**: ticket if p95 > 15 s for 30 min (LLM degradation, not a user emergency yet)

## 2. BagTrip admin panel (`bagtrip.fr`, `dev.bagtrip.fr`)

| Field | Value |
|---|---|
| Service | Internal Next.js admin used by ops + back-office |
| User-perceived promise | "I can sign in and manage things without timeouts" |

### 2.1 Availability

- **SLI**: blackbox probe `probe_success` against `https://bagtrip.fr/login` and `https://dev.bagtrip.fr/login` every 30 s
- **SLO**: ≥ 99 % over a rolling 30-day window (lower than API since admin has fewer users and impact)
- **Alert**: page if 5 consecutive probes fail (~2.5 min)

### 2.2 TLS validity

- **SLI**: `probe_ssl_earliest_cert_expiry - time()` (seconds until the leaf cert expires)
- **SLO**: > 14 days at all times
- **Alert**: ticket at < 14 days, page at < 3 days

## 3. Edge Caddy + reverse proxies

| Field | Value |
|---|---|
| Service | TLS termination + routing for every public hostname |
| User-perceived promise | "Requests reach the right backend, fast" |

### 3.1 Edge availability

- **SLI**: `probe_success` (blackbox) against each public hostname listed in `infra/ansible/group_vars/all.yml::bagtrip_public_domains`
- **SLO**: ≥ 99.9 % per hostname over rolling 30 days
- **Alert**: page if any probe target fails 3 consecutive checks (~90 s)

### 3.2 Proxy latency (TTFB)

- **SLI**: `histogram_quantile(0.95, sum(rate(caddy_http_request_duration_seconds_bucket{handler="reverse_proxy"}[5m])) by (le))`
- **SLO**: p95 < 300 ms (excluding `/agent/plan-trip-stream`) over rolling 30 days
- **Alert**: ticket if p95 > 700 ms for 15 min

## 4. Reliability — backups (Phase 6)

| Field | Value |
|---|---|
| Service | Restic snapshots of all Postgres instances + critical volumes |
| User-perceived promise | "If everything explodes, we recover" |

### 4.1 Backup freshness

- **SLI**: `time() - restic_last_successful_backup_timestamp` (seconds since last green backup)
- **SLO**: < 26 hours (24 h cron + 2 h slack) at all times
- **Alert**: page if > 30 hours

### 4.2 Restore drill success

- **SLI**: weekly `restore-test.sh` exit code, exposed as Prometheus gauge
- **SLO**: 100 % success over the last 4 weekly drills
- **Alert**: page on first failure (a single failed drill is already an outage of confidence)

## 5. Out of scope — explicit non-goals

- Per-user latency tracking. Out of scope until we exceed ~10 k DAU.
- Geographic distribution of probes. Today everything probes from the VPS itself; we accept the false-negative on "internet between user and edge" until we add an external sentinel.
- Mobile app crash-free rate. Tracked elsewhere (Crashlytics) — not in this document.

## 6. Reviewing these targets

- **Cadence**: every 90 days, or after any sustained breach.
- **Process**: pull the rolling 30-day data from Prometheus, compute actuals, compare to SLOs. If we never come close to breaching, the target is too loose. If we breach often without user impact, it's too tight.
- **Outcome**: a pull request updating this file, signed off by whoever holds the on-call pager that quarter.

## 7. Mapping to M5 jury rubric

| Rubric criterion | Where this document shows it |
|---|---|
| Define and operate SLOs | §1–4 (numeric targets, error budgets, burn-rate alerts) |
| User-centric measurement | §1.3, §1.4 (we measure the SSE trip planner the way a user feels it) |
| Continuous improvement | §6 (review process, not a one-shot document) |
| Alignment with incident response | §1.1 burn-rate alerts wire directly into the runbooks created from incident-2026-04-26 |
