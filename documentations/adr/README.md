# Architecture Decision Records (ADR)

This folder collects load-bearing technical decisions for the BagTrip infrastructure and observability stack. Each ADR captures **what we decided, why, and what we considered instead**, so future contributors (and the M5 jury) can read the rationale rather than reverse-engineer it from the code.

## Format

Each ADR is a single markdown file named `NNNN-short-slug.md`, with the following structure:

```
# ADR-NNNN — Title

- Status: proposed / accepted / deprecated / superseded by ADR-XXXX
- Date: YYYY-MM-DD
- Authors: …

## Context
What forces are in play. Constraints. Prior art. What problem this solves.

## Decision
The choice we made, in one paragraph.

## Consequences
What becomes easier. What becomes harder. What is now off-limits.

## Alternatives considered
Other options, with the reason each was rejected.
```

## Index

| # | Title | Status |
|---|---|---|
| [0001](./0001-observability-stack-strategy.md) | Observability stack strategy (Prom + Loki + Tempo, unified under Grafana) | accepted |
| [0002](./0002-three-pillars-grafana.md) | Three pillars unified under Grafana — picks Loki / Tempo / Alertmanager and documents rejected alternatives (ELK, Jaeger, Datadog) | accepted |
| [0003](./0003-defense-in-depth-incident-driven.md) | Defense in depth, prioritised by the 26/04 post-mortem follow-up IDs | accepted |
| [0004](./0004-iac-with-ansible.md) | Infrastructure-as-code with Ansible (not Terraform / Kubernetes) | accepted |
| [0005](./0005-restic-local-with-b2-path.md) | Restic backups with a local repo + documented B2 escape hatch + tested weekly drill | accepted |
