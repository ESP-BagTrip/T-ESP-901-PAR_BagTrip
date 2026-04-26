# Runbook — SLO error budget burning

> Triggered by: `ApiAvailabilityFastBurn` (page),
> `ApiAvailabilitySlowBurn` (ticket).

The API availability SLO target is **99.5 %** over a rolling 30-day
window (see `documentations/observability/slo.md`). The two burn-rate
alerts catch the same pathology at different speeds:

| Alert | Window | Burn | Meaning |
|---|---|---|---|
| Fast | 5 m AND 1 h | 14× | We'd consume 5 % of monthly budget in ~2 h if this continues |
| Slow | 30 m AND 6 h | 3× | A slow leak the user notices once per session |

## What to do

A burn-rate alert is **not** an "API is down" alert — it's a "you are
spending budget faster than agreed". Treat it as a strong nudge to
investigate, not as a page-the-team-immediately incident *unless*
follow-on signals fire (`ApiHighErrorRate`, `ApiDown`).

1. Open the API RED dashboard for `env=prod`. The error rate panel
   should be elevated — confirm it's real (not a Prometheus scrape gap).
2. Cross-check Loki + Tempo for the failing endpoint, exactly as in
   `api-error-rate.md`.
3. If the error budget is genuinely being spent and you can't fix the
   root cause within an hour, freeze deploys until the budget recovers.
   Pre-canned slack message: *"Heads up — API SLO burn-rate is fast
   ($X×). Freezing deploys until incident resolution."*

## What to write in the post-mortem

For every burn-rate alert that fires longer than 30 minutes, append a
row to the SLO review log (Phase 9 deliverable). Even if the cause was
"a single buggy migration", we want the trail.
