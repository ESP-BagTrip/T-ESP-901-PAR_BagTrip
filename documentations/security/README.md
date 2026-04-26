# Security documentation — BagTrip

Documents tracking the security posture of the BagTrip infrastructure (single OVH VPS hosting `bagtrip` prod, `bagtrip` preprod, `pokemon-ocr`, `openclaw`, behind a Cloudflare-fronted Caddy edge).

## Contents

| Document | Purpose |
|---|---|
| [`incident-2026-04-26-cryptominer.md`](./incident-2026-04-26-cryptominer.md) | Full post-mortem of the cryptominer compromise of `bagtrip-preprod-admin-1`. Timeline, IOCs, RCA, remediation, lessons learned, M5 competency mapping. |
| [`hardening-roadmap.md`](./hardening-roadmap.md) | Live inventory of security controls already in place + prioritised backlog of remaining defence-in-depth work. |

## How these documents relate

- The **post-mortem** is the trigger document — it explains *why* certain controls exist now and *why* the roadmap looks the way it does.
- The **roadmap** is the forward-looking document — it lists what is in place (so the BagTrip team can see at a glance what protects them today) and what remains to do, with priorities and acceptance criteria.

When a new control ships, update the roadmap (move from ⏳ to ✅) and reference the change in either a future post-mortem or a release-note.

When a new incident happens, write a new `incident-YYYY-MM-DD-<short>.md` in this folder using the same structure as the 2026-04-26 one, and add follow-ups into the roadmap.
