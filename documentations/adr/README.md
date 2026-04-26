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
