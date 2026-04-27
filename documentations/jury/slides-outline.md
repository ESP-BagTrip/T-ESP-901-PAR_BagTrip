# Slide deck — M5 soutenance outline

> Markdown-format outline for slides. Drop into Keynote / Slidev /
> Marp. ~14 slides for a 12-15 minute talk + 5 minute demo + Q&A.

---

## 1. Title

**BagTrip — production observability + security stack**
Yanis Lounadi · Master M5 · 2026

Subtitle: *built in 8 days, sequenced by a real incident*

---

## 2. Project context

- BagTrip — AI-assisted travel planning (Flutter mobile / FastAPI / Next.js admin)
- Stacks on a single OVH VPS, three environments (prod, preprod, dev)
- 4 vCPU / 16 GiB / 96 GiB disk → upgraded to 8 / 31 / 193 mid-deliverable
- Three apps colocated: `bagtrip` prod, `bagtrip` preprod, `bagtrip` mobile

---

## 3. The 26/04 incident (the forcing function)

Single screenshot: post-mortem timeline header.

- **2026-04-26 09:07 UTC** — Server Actions RCE on Next.js 15.5.0
  (CVE-2025-49826)
- Dropper: `next-server → sh → base64 → sh → /tmp/XXEKdPOH`
- Stripped Linux ELF cryptominer, Monero pool at 51.81.51.221:33333
- **7 h 45 min** mining at 99 % CPU before Netdata sustained-CPU alert
- Containment: 10 minutes once detected. **Detection was the gap.**

> Real incident, real forensics, real post-mortem in
> `documentations/security/incident-2026-04-26-cryptominer.md`.

---

## 4. The seven gaps

Bullet list (project-style):

- F1 — No CVE scanner in CI
- F2 — Manual upgrades, no Dependabot
- F3 — Container without `read_only`, `noexec`, cap drop ✅ patched 26/04
- F4 — No HIDS catching the dropper pattern
- F5 — No edge access logs ✅ patched 26/04
- F6 — No egress filtering
- F7 — No app-layer rate limit

> *"Every phase of this M5 deliverable closes one or more of these IDs.
> ADR-0003 documents the sequencing."*

---

## 5. Architecture — three pillars

(Diagram — `documentations/architecture/c4-containers.md`)

```
[Mobile / Admin / Public]
     │
     ▼
[Cloudflare → Caddy edge :443]
     │ (logs JSON → Promtail → Loki)
     ▼
[Inner Caddies on 127.0.0.1:80XX]
     │
     ▼
[FastAPI / Next.js / Postgres / Redis]
     │ /metrics + OTLP traces
     ▼
[Prometheus + Loki + Tempo  ←→ Grafana ← Alertmanager → Discord/email]
                 │
                 ▼
   [node_exporter + cAdvisor + postgres / redis / blackbox exporters]
```

ADR-0002: why Loki over ELK, Tempo over Jaeger.

---

## 6. Three pillars + correlation (live)

Live demo:

1. **Metrics** — `BagTrip — Infra overview` dashboard
2. **Logs** — `BagTrip — Logs`, filter by service
3. **Traces** — click trace_id label → Tempo flame graph
4. **Cross-pillar deeplinks** — Loki ↔ Tempo via derived field

> *"Three pillars correlated through `trace_id`. One UI. One query
> language family."*

---

## 7. Defense in depth — incident-driven

Stack diagram by trust boundary:

| Layer | Control | Closes |
|---|---|---|
| Edge | Cloudflare WAF + Caddy access logs + iptables | F5, ddos |
| Per-stack | Inner Caddies + iptables PREROUTING DROP | T2 |
| Container | `read_only` + `noexec` + `cap_drop:[ALL]` | F3 (asserted by Ansible) |
| Supply chain | **Trivy CI gate** | F1 |
| Runtime | **Falco rules** (deferred runtime) | F4 |
| DR | **Restic + weekly restore drill** | data loss |

(ADR-0003 — defense-in-depth strategy)

---

## 8. Trivy already paid off

Screenshot of GitHub code-scanning Security tab (Phase 5a).

> *"Five HIGH CVEs in the api/ dependency tree caught and patched as a
> forcing-function effect of the gate landing — cryptography,
> langchain-core, orjson, pyasn1, urllib3. Each had a fixed version
> available. The 26/04 CVE (Next.js 15.5.0) would have been blocked
> here."*

Show `.trivyignore` — expiry-dated waivers only.

---

## 9. Alerting + runbooks

Screenshot: Alertmanager UI showing the firing alert + runbook deeplink.

> *"19 alert rules. SLO multi-window burn-rate. The
> `ContainerCPUSustained` rule fires in 5 minutes on the 26/04
> pattern — that's a 90× detection improvement vs Netdata's 10-minute
> averaging."*

Walk through `infra/runbooks/cryptominer-suspect.md` highlights —
forensics-preserving containment order.

---

## 10. Tested DR

Screenshot: `BagTrip — Synthetic + DR` dashboard (Phase 7).

- Daily restic backup (encrypted, 14-d retention)
- **Weekly automated restore drill** — restores into a throwaway
  postgres + sanity-check SELECT
- `ResticRestoreDrillFailed` is the strongest "are backups real?"
  signal — pages on first drill failure
- Local-repo with documented B2 escape hatch (ADR-0005)

---

## 11. IaC reproducibility (live demo)

Run live: `make -C infra redeploy-demo`

> *"50 seconds end-to-end. Stack down → containers + named volumes
> destroyed → Ansible re-applies → stack back up. Secrets persisted
> in `/opt/observability/.env`, restic repo intact, iptables rules
> persisted via `netfilter-persistent`."*

ADR-0004 — why Ansible, not Terraform / Kubernetes.

---

## 12. Business KPIs (observability is not just infra)

Screenshot of `BagTrip — Business KPIs`.

- Signups / day, logins / day, trips created / day
- SSE plan-trip success vs error
- Subscription flow handler breakdown
- Stripe webhooks by status
- Top 15 endpoints

> *"The same observability stack serves the product side, not just SRE.
> Phase 7."*

---

## 13. Cost — why self-host

Single chart from `documentations/jury/cost-comparison.md`:

| | OVH | AWS | GCP |
|---|--:|--:|--:|
| €/month | 19 | 281 | 304 |
| 3-year TCO | 684 | 10 116 | 10 944 |

> *"15× cheaper at this workload. Break-even moves to AWS at 4 h/month
> of saved operator time, regulatory multi-region requirement, or
> SOC2 contractual ask. None apply at the M5 phase."*

---

## 14. M5 rubric coverage

Single table:

| Rubric criterion | Where in this deliverable |
|---|---|
| Operate a production environment | live, three stacks, edge proxy, monitoring |
| Detect & respond to incidents | post-mortem + 19 alerts + 12 runbooks |
| Defense in depth | edge / container / supply-chain / runtime / DR |
| Industrialisation | Trivy CI + restic timers + Ansible role + Makefile |
| Continuous improvement | hardening-roadmap, threat-model before/after, ADRs |
| Documentation deliverable | this slide deck + 5 ADRs + cost study + runbooks |
| Communication / post-mortem culture | blameless 26/04 post-mortem |

---

## 15. Lessons learned + closing

Three things this build taught me:

1. **Incident-driven scoping beats best-practice cargo-culting.** Every
   control on this slide deck answers "what would have changed on
   26/04?" in one sentence.

2. **Test the recovery path you claim.** The weekly restore drill is
   the single highest-leverage DR control I added — backups exist
   everywhere; *tested* recovery is rare.

3. **Idempotence is a forcing function.** Phase 8's
   `ok=68 changed=0` audit caught three subtle bugs (regex_search
   list-wrapping, bcrypt salt drift, Caddy admin origin enforcement)
   that would have been silent operational papercuts forever.

> *"Thank you. Questions?"*

---

## Appendix slides (only if asked)

- A1: Why not Datadog (ADR-0001 / ADR-0002)
- A2: Why not Kubernetes (ADR-0004)
- A3: Falco runtime deferral details (kernel probe `scap_init` on 6.14)
- A4: Phase-by-phase commit history walk
