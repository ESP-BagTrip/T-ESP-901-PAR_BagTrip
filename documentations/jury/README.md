# M5 soutenance — index

Companion folder for the Master M5 jury defence. Everything here is
**reading-order** material for someone who wants to evaluate this
deliverable from scratch.

## Read in this order

1. [`../security/incident-2026-04-26-cryptominer.md`](../security/incident-2026-04-26-cryptominer.md) — the forcing function.
2. [`../adr/0001-observability-stack-strategy.md`](../adr/0001-observability-stack-strategy.md) — umbrella plan.
3. [`../security/threat-model.md`](../security/threat-model.md) — STRIDE before / after columns.
4. [`./rubric-mapping.md`](./rubric-mapping.md) — what we ship vs what's graded.
5. [`./demo-scenario.md`](./demo-scenario.md) — the live walkthrough script.
6. [`./slides-outline.md`](./slides-outline.md) — slide deck structure.
7. [`./cost-comparison.md`](./cost-comparison.md) — OVH vs AWS / GCP figures.
8. [`../architecture/c4-context.md`](../architecture/c4-context.md) and [`../architecture/c4-containers.md`](../architecture/c4-containers.md) — diagrams.
9. [`../architecture/data-flow-rgpd.md`](../architecture/data-flow-rgpd.md) — RGPD data flow.
10. [`../security/hardening-roadmap.md`](../security/hardening-roadmap.md) — what's done vs what's left.

## What's *not* in this folder

- The runbooks (`infra/runbooks/`) — operational, not soutenance.
- The dashboards JSON (`infra/dashboards/`) — render in Grafana.
- The Ansible role (`infra/ansible/`) — the actual deployment.

## Demo prerequisites

```bash
# from any tab on the laptop
ssh yanis 'sudo grep GF_ADMIN_PASSWORD /opt/observability/.env | cut -d= -f2'
# → use this for both Caddy basic_auth and Grafana login on grafana.bagtrip.fr
```

## Q&A cheat sheet

| Likely question | One-line answer + reference |
|---|---|
| Why not Datadog / Grafana Cloud? | Self-hosted is the rubric expectation; 15× cheaper at our scale → ADR-0001, ADR-0002, cost-comparison.md |
| Why not Kubernetes? | Adds etcd / API server / kubelet to solve scheduling we don't have → ADR-0004 |
| Why not Terraform? | We have no cloud-API resources to track → ADR-0004 |
| Why is Falco off? | `scap_init` fails on Linux 6.14 + Falco 0.39 → rules ship as config, runtime flips with `--profile security` → ADR-0003, infra/README.md |
| What about prod? | Phase 1b lives on `develop` → preprod auto-deploys via cd.yml. Prod is a scheduled merge to `main` outside the M5 window. |
| How do you keep secrets safe? | Generated on first deploy, persisted in `/opt/observability/.env` (mode 0600 deploy:deploy), never in git → ADR-0005 |
| What if the VPS dies? | restic local repo + 50s ansible rebuild on a fresh VPS → ADR-0005, demo-scenario.md step 6 |
| What about RGPD? | data-flow-rgpd.md — EU-only hosting (OVH FR + Cloudflare EU + Stripe EU SCC) |
