# Observability documentation

Source-of-truth documents for what BagTrip measures, alerts on, and commits to.

## Contents

| Document | Purpose |
|---|---|
| [`individual-contribution.md`](./individual-contribution.md) | One-page fiche covering the observability + security layer — origin, what got built, where to dig deeper. |
| [`slo.md`](./slo.md) | Service-level objectives, indicators, and error budgets. Drives alert thresholds in `infra/alerts/` and the panels in `infra/dashboards/`. |

## How this folder fits in

- **What we measure** lives in `infra/dashboards/` (Grafana JSON) and is described at a high level in `slo.md`.
- **When we wake someone up** lives in `infra/alerts/` (Prometheus rules) and is constrained by the SLOs in `slo.md`.
- **What to do when we wake someone up** lives in `infra/runbooks/` (one markdown per alert).
- **Why we made the architectural choices** lives in `documentations/adr/`.
