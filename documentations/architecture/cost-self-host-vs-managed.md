# Cost comparison — OVH self-hosted vs. AWS / GCP managed equivalent

> Author: Yanis Lounadi · 2026-04-27 · architecture documentation

## Why this document

The M5 jury asks for a defensible business-case for the architecture
choice. "OVH was cheap" isn't enough; the question is **what would the
same observability + reliability posture cost on AWS or GCP, and is the
delta worth the operational overhead?**

## Scope

Three equivalent stacks compared:

1. **Current — OVH self-hosted** (one VPS, Ansible-managed)
2. **AWS managed** (EC2 + RDS + S3 + CloudWatch + GuardDuty + AWS Backup)
3. **GCP managed** (Compute Engine + Cloud SQL + Cloud Storage + Cloud Logging + Cloud Monitoring + Backup-DR)

Same workload assumed:
- 4 vCPU / 16 GiB memory equivalent baseline (we have 8 / 31 since the
  26/04 upgrade — comparison uses the original 4/16 baseline to avoid
  inflating)
- 100 GiB block storage (Postgres + observability TSDBs + logs)
- ~50 GiB / month log + metric volume
- Backups: 4 snapshots × 1 GiB = 4 GiB / month off-site
- Equivalent observability: metrics / logs / traces / 14-day retention /
  3 alert channels / restore-tested DR

Pricing pulled 2026-04-27 from each provider's pricing pages; figures
are EUR-converted at the published rate. Numbers rounded to the nearest
euro.

## Cost summary (EUR / month)

| Component | OVH self-hosted | AWS managed | GCP managed |
|---|--:|--:|--:|
| Compute (4 vCPU / 16 GiB) | 19 € | 70 € (`t3.xlarge`) | 90 € (`e2-standard-4`) |
| Block storage (100 GiB SSD) | included | 12 € (gp3) | 17 € (Standard PD) |
| Managed Postgres (8 GiB / single AZ) | n/a (in-host) | 65 € (`db.t3.medium`) | 80 € (`db-g1-small`) |
| Object storage (off-site backups, 4 GiB) | 0 € (Backblaze B2 free tier) | 1 € (S3 Standard + lifecycle) | 1 € (Cloud Storage Standard) |
| Metrics + logs + traces (50 GiB ingest) | 0 € (Prom / Loki / Tempo self-hosted on the same VPS) | 60 € (CloudWatch Logs ingest + 30-day retention) | 50 € (Cloud Logging + Cloud Monitoring) |
| Threat detection (CVE scan + runtime) | 0 € (Trivy CI + Falco rules) | 40 € (GuardDuty + Inspector) | 40 € (Security Command Center Premium pro-rated) |
| Backup orchestration | 0 € (restic + systemd) | 8 € (AWS Backup standard) | 6 € (Backup-DR) |
| Edge / WAF | 0 € (Cloudflare free + Caddy) | 25 € (CloudFront + WAF rules) | 20 € (Cloud CDN + Cloud Armor minimum) |
| **Total / month** | **~19 €** | **~281 €** | **~304 €** |

Annualised:

| | OVH | AWS | GCP |
|---|--:|--:|--:|
| Year 1 | ~228 € | ~3 372 € | ~3 648 € |
| 3-year TCO | ~684 € | ~10 116 € | ~10 944 € |

**Order of magnitude: 15× cheaper to self-host on OVH for this workload.**
The gap shrinks when you include "operator hours" — AWS / GCP take far
less time per month to maintain. At my consulting rate (~ 60 €/h), AWS
breaks even at ~4 h/month of saved operations time. We spend much less
than that on the OVH stack today (idempotent role, automated DR
drill, alerting wired). Self-host wins.

## Where the savings come from

1. **No managed-DB premium** — RDS / Cloud SQL each charge ~ 70 €/mo for
   a single small Postgres. We run two (prod + preprod) on the same
   host for free. The trade-off is no managed multi-AZ failover, which
   we don't need at this stage.

2. **No log-ingest tax** — CloudWatch / Cloud Logging charge per GiB
   ingested AND stored, with 30-day defaults. Our Loki retention is
   14 days configurable, on local SSD, ingest-free. Same for Tempo.

3. **No SaaS observability uplift** — Datadog / Grafana Cloud / New
   Relic typically start ~30 €/host/month with very limited included
   metrics retention. We chose self-hosted Grafana stack precisely
   because the M5 rubric values it AND because it's the cheaper path.

4. **Edge is free** — Cloudflare free tier covers DDoS L3/L4, basic
   WAF, and unlimited bandwidth. AWS / GCP charge for the WAF *and*
   for egress.

## Where the trade-offs hurt

| Trade-off | OVH cost | Mitigation |
|---|---|---|
| Single host = single point of failure | One VPS reboot = full outage | Cloudflare cache softens during planned downtime; off-site backups in B2 are the recovery path. The `make -C infra redeploy-demo` run takes 50 s once a clean host is provisioned. |
| Manual VPS provisioning | First deploy on a fresh OVH host requires `apt install` + Docker + restic + Ansible bootstrap | The Ansible role handles everything past that bootstrap; bootstrap itself is < 10 minutes manual work |
| No multi-AZ DB | A disk failure on the VPS loses the live DB | Daily restic backup + weekly drill verify recovery — but the RPO is 24 h. Multi-AZ would cost +65 € / mo on AWS for a 5-min RPO. |
| Compliance posture | No SOC2 / ISO certifications come with OVH SaaS-style | OVH Bare Metal/VPS is GDPR-compliant by default (EU host). For a regulated industry we'd revisit. |
| Self-managed security patching | We own kernel updates (auto via `unattended-upgrades`) | The 26/04 incident hit because of an *application*-layer CVE that managed services would not have patched either; the cost / value trade-off here is more even than it looks. |

## Conclusion

For BagTrip's pre-launch scale, self-hosting on OVH and re-investing the
~ 250 €/mo delta into product / dev hours is the right call. The IaC
reproducibility (50 s rebuild from clean host) and the tested DR drill
keep the operational risk inside an acceptable envelope.

The **break-even point** for moving to AWS / GCP is roughly:
- Multi-region failover becomes a hard requirement (regulatory,
  contractual SLA), OR
- The operator-hours cost exceeds 4 h/month at full developer rates, OR
- Compliance certificates (SOC2 / ISO 27001) become contractual.

None of those are true today. We revisit at the next strategic review.
