# ADR-0003 — Defense in depth, prioritised by the 26/04 post-mortem

- **Status**: accepted
- **Date**: 2026-04-27
- **Authors**: Yanis Lounadi

## Context

The 26/04 cryptominer incident
(`documentations/security/incident-2026-04-26-cryptominer.md`) surfaced
seven distinct gaps in the BagTrip security posture. Each gap, viewed
individually, has a credible technical control to close it; the
question this ADR answers is **which controls in which order** — given
finite calendar time before the M5 jury, we needed a forcing function
to sequence the work.

## Decision

We sequence security work by **post-mortem follow-up ID**, not by
"what looks coolest". Each phase of the M5 plan is anchored to one or
more `F<n>` items in the incident document:

| Gap (from §2.2 of the post-mortem) | Control | Phase | Status |
|---|---|---|---|
| F1 — No CVE scanner in CI | Trivy `fs` scan, fail-build on HIGH/CRITICAL | 5a | shipped |
| F2 — Manual upgrades, no Dependabot | Trivy waivers + tracked in `.trivyignore` | 5a | shipped (forcing function) |
| F3 — Container without `read_only`, `noexec`, cap drop | Already applied 26/04, asserted by Phase 0 baseline role | 0 | shipped |
| F4 — No HIDS catching `*.js → sh → base64 → /tmp/*` | Falco runtime rules + alerts | 5b | rules shipped, runtime deferred |
| F5 — No edge access logs | Caddy JSON access logs → Loki + dashboards | 1+2 | shipped |
| F6 — No egress filtering | Outbound allowlist via Falco + per-stack `internal: true` networks | 5c | deferred |
| F7 — No app-layer rate limit | Rate-limit middleware in api + Caddy `rate_limit` | n/a (out of M5 scope) | application work |

Beyond closing those specific gaps, two architectural decisions follow
from the same incident-driven framing:

- **Monitor what would have caught the attack.** The
  `ContainerCPUSustained` alert (Phase 4) fires in 5 minutes on the
  exact pattern that took Netdata 7h45 to surface. Not a generic CPU
  alert — explicitly named after the incident's `incident_pattern`
  label.
- **Test the recovery path you claim.** Backups existed elsewhere; the
  M5 rubric asks for *tested* recovery. Phase 6 ships a weekly restore
  drill that runs end-to-end in Postgres throwaway containers and
  alerts on its own failure (`ResticRestoreDrillFailed` paging).

## Consequences

### Easier
- Every control has a "what would have changed on 26/04?" answer in
  one sentence. That's the slide.
- Reviewers can cross-check `incident-2026-04-26-cryptominer.md §8`
  against the alert rules + runbooks and see the loop closed.

### Harder
- Some F items are application work (F7 rate limiting) and don't fit
  cleanly into "infra phases" — they need separate PRs against
  `api/` / `admin-panel/`. Tracked in the hardening-roadmap.
- F6 (egress allowlist) requires enumerating *every* legitimate
  outbound — Stripe, Amadeus, OVH LLM, Sentry, Cloudflare. That's
  several hours of careful work before any rule lands. Deferred.

### Now off-limits
- Adding security controls "because they're best practice" without
  tying them to a concrete threat we observed or modelled in
  `threat-model.md`. The bar is "what does this protect against in
  *our* threat model?"

## Alternatives considered

| Alternative | Rejected because |
|---|---|
| **Wazuh as a one-stop SIEM** | Overkill for one host; would require maintaining a parallel agent / manager / dashboards stack on top of Grafana. |
| **CrowdSec WAF replacing Falco entirely** | Different layer — CrowdSec watches edge logs (we use it for SSH brute-force already); Falco watches syscalls inside containers. Complementary, not substitutes. |
| **Trivy image scan against built images instead of `fs` scan** | Slower (requires building images in CI), and `fs` already catches OS package CVEs in Dockerfiles. We can add image scan as a Phase 9+ depth pass. |

## References

- `documentations/security/incident-2026-04-26-cryptominer.md` §2.2 (gap list)
- `documentations/security/hardening-roadmap.md` (live tracker, marks shipped items)
- `documentations/security/threat-model.md` (STRIDE before / after columns)
- `infra/ansible/roles/observability_stack/templates/alerts/containers.yml.j2` (`ContainerCPUSustained`)
- `infra/ansible/roles/observability_stack/templates/falco_rules.local.yaml.j2`
