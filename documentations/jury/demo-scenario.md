# Live demo — M5 jury walkthrough (12-15 minutes)

> Author: Yanis Lounadi · 2026-04-27 · run this script in front of the jury.
> Prep: open these tabs ahead of time so the demo doesn't wait on TLS handshakes.

## Pre-flight (do BEFORE the jury walks in)

1. Browser tabs open:
   - `https://grafana.bagtrip.fr/d/bagtrip-infra-overview` (Phase 1)
   - `https://grafana.bagtrip.fr/d/bagtrip-api-red?var-env=preprod` (Phase 1b)
   - `https://grafana.bagtrip.fr/d/bagtrip-logs?var-service=api&var-env=preprod` (Phase 2)
   - `https://grafana.bagtrip.fr/explore` (for Tempo demo)
   - `https://grafana.bagtrip.fr/alerting/list` (Phase 4)
   - `https://grafana.bagtrip.fr/d/bagtrip-synthetic-dr` (Phase 6)
   - `https://github.com/ESP-BagTrip/T-ESP-901-PAR_BagTrip/security/code-scanning` (Phase 5a)
2. Terminal tabs:
   - one `ssh yanis` shell
   - one `cd ~/repo/infra` shell ready for `make redeploy-demo`
3. The post-mortem markdown open:
   `documentations/security/incident-2026-04-26-cryptominer.md`

## Storyline (5 min context)

**Slide 1 — Why this matters**
> *"On April 26 my pre-prod admin panel was compromised through a
> Server-Actions header-injection bug in Next.js 15.5.0. A staged
> dropper landed a stripped Linux ELF cryptominer at /tmp/XXEKdPOH and
> mined Monero for 7 hours 45 minutes before our default Netdata
> sustained-CPU alert finally fired."*

Show the post-mortem timeline (`§1`). Highlight TTD (7h45) vs TTC (10
min once we noticed). The point: containment was fast, **detection was
slow**, and the gap was a tooling gap, not a competence gap.

**Slide 2 — The seven gaps**

Show post-mortem `§2.2`. Walk through the table once. Stop on:
> *"Five of these are infrastructure work. Two are application work
> (rate limit, egress allowlist). The M5 deliverable closes the
> infrastructure side, sequenced explicitly by these follow-up IDs —
> ADR-0003 documents the sequencing."*

## Architecture (2 min)

**Slide 3 — Three pillars**

Hand-draw the diagram OR show the C4 in `documentations/architecture/`:

```
Application layer — FastAPI / Next.js
        │ instrumented (prometheus-fastapi-instrumentator + prom-client + OTEL SDK)
        ▼
Observability layer — Prom + Loki + Tempo (LGTM, all behind Grafana)
        │
        ▼
Operations layer — Alertmanager → Discord/email + 12 runbooks + Restic + IaC (Ansible)
```

> *"Three pillars unified under Grafana, ADR-0002 explains why we picked
> Loki over ELK and Tempo over Jaeger. Everything ships through one
> Ansible role — ADR-0004 explains why not Terraform / Kubernetes."*

## Live walkthrough (8 min)

### Step 1 — Metrics pillar (2 min)

Open `BagTrip — Infra overview`.

> *"Phase 1: Prometheus, four exporters (node, cadvisor, postgres ×2,
> redis ×2), nine targets currently UP."*

Switch to `BagTrip — API RED`, env=preprod.

> *"Phase 1b: every BagTrip request is timed and counted. The middleware
> exposes RED metrics — Rate, Errors, Duration. p95 visible here."*

Switch to `BagTrip — Synthetic + DR`.

> *"Phase 7: synthetic probes against five public hosts every 15
> seconds. The 'Restic — last backup status' panel — that's the DR
> tested-recovery signal."*

### Step 2 — Logs pillar + correlation (2 min)

Open `BagTrip — Logs`, filter `service=api, env=preprod`.

> *"Phase 2: Loki + Promtail. 23 BagTrip-managed containers ship logs
> here, allowlist-filtered so adjacent unrelated workloads on the same
> host never enter the index. Notice the trace_id label on each line."*

Click a log line with a `trace_id` value (if any) → "View trace" button →
opens Tempo trace.

> *"Phase 3: OpenTelemetry SDK on FastAPI auto-instruments the request
> path. The trace_id label on the log line deeplinks to Tempo, where
> you can see the request span tree, the SQLAlchemy span, the
> downstream HTTPX call. Three pillars correlated through one ID."*

### Step 3 — Alerting + runbook (1.5 min)

Open `https://grafana.bagtrip.fr/alerting/list`.

> *"Phase 4: 19 alert rules. SLO multi-window burn-rate alerts (Google
> SRE methodology). Each rule has a runbook_url annotation that
> deeplinks the on-call to a markdown runbook."*

Click `ContainerCPUSustained` → show `cryptominer-suspect.md` runbook.

> *"This is the rule that, applied to the 26/04 timeline, would have
> fired 5 minutes into the incident instead of 7 hours 45. The runbook
> walks through forensics-preserving containment in the order that
> doesn't destroy evidence."*

### Step 4 — Supply-chain gate (1 min)

Open `https://github.com/ESP-BagTrip/T-ESP-901-PAR_BagTrip/security/code-scanning`.

> *"Phase 5a: Trivy `fs` scan in CI. Fails the build on HIGH/CRITICAL
> CVEs with a fixed version. Already paid off in production: five HIGH
> CVEs (cryptography, langchain-core, orjson, pyasn1, urllib3) were
> patched as a forcing-function effect of the gate landing."*

Show `.trivyignore` — empty by design — explain the expiry-dated
waiver convention.

### Step 5 — DR demo (1 min)

```bash
make -C infra restic-status
```

> *"Phase 6: daily restic backup (last run timestamp visible). Weekly
> restore drill (last drill status). Three alerts wire those into
> Alertmanager — the drill alert is the strongest 'are backups
> real?' signal in the stack."*

Optionally trigger ad-hoc:

```bash
make -C infra restic-backup-now
```

### Step 6 — IaC reproducibility (1.5 min) — ⚠️ optional, only if time

```bash
make -C infra redeploy-demo
```

> *"Phase 8: complete reproducibility from scratch. We're going to
> destroy the observability stack — containers AND named volumes — and
> rebuild it from the Ansible role. The bagtrip prod / preprod / edge
> stacks are not touched."*

While it runs (~50 seconds), narrate:

> *"Pure idempotence — `ansible-playbook` converges to ok=68
> changed=0 on a converged host. The destroy + redeploy is a
> single command because the role is the source of truth."*

When it finishes, refresh Grafana — same admin password (persisted in
`/opt/observability/.env`), same dashboards, same Restic repo. Only
metric / log / trace history is reset.

## Closing (1 min)

> *"To summarise: an incident hit; we identified seven gaps; we
> documented every decision in five ADRs; we shipped the controls in
> sequence dictated by the post-mortem follow-up IDs; we demonstrated
> the DR is tested, the IaC is reproducible, and the observability
> covers metrics, logs, traces, alerts, and business KPIs. The Falco
> runtime probe is the one item we couldn't land on this kernel
> version — config and rules are in the repo, ready to flip on with
> `--profile security` when the kernel-probe path is sorted."*

> *"M5 rubric coverage in `documentations/jury/rubric-mapping.md`."*

## If the jury asks…

| Question | Short answer |
|---|---|
| Why not Datadog? | ADR-0001, ADR-0002 — self-hosted is the rubric expectation, and 15× cheaper at our scale (`cost-comparison.md`). |
| Why not Kubernetes? | ADR-0004 — adds etcd / API server / kubelet to solve scheduling problems we don't have. |
| Why deferred Falco runtime? | Modern eBPF probe fails `scap_init` on this Linux 6.14 kernel. Rules are committed, runtime flips on with one compose profile (`--profile security`). |
| What about prod? | Phase 1b instrumentation is on `develop` (preprod). The merge to `main` (prod) is a separate scheduled deploy outside the M5 demo window. |
| How do you keep secrets safe? | All secrets in `/opt/observability/.env` (mode 0600 deploy:deploy), generated on first deploy, persisted, never in git. ADR-0005 details restic password handling. |
| What about audit / compliance? | The threat-model `before/after` is the "audit narrative". Hardening-roadmap §5 explicitly lists deferred items (HSM/KMS for secrets, multi-region failover, WAF). |
