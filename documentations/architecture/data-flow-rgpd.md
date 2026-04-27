# Data flow + RGPD posture

> Author: Yanis Lounadi · 2026-04-27 · part of the Phase 9 docs.

## What personal data BagTrip handles

| Category | Examples | Where it lives |
|---|---|---|
| Account identifiers | email, hashed password (bcrypt), display name | Postgres `users` table |
| Trip content | destinations, dates, traveller list, budget | Postgres `trips`, `activities`, `accommodations`, etc. |
| Payment metadata | Stripe Customer ID, PaymentIntent IDs | Postgres + Stripe (PCI-scoped) |
| Push tokens | FCM device tokens | Postgres `device_tokens` |
| Session state | JWT access + refresh tokens | HttpOnly Secure cookies |
| Transient logs | client IP, User-Agent, request URI | Caddy access log → Loki (14 d retention) |
| Trace metadata | request span trees | Tempo (14 d retention) |

**Out of scope** for this document:
- Cloudflare-side data (request origin / TLS metadata) — handled by
  Cloudflare's own RGPD posture
- Stripe-held payment data — PCI scope, never crosses our boundary in
  full form
- Mobile-only data (Crashlytics) — handled in app docs

## Data flow

```mermaid
graph LR
    user([User<br/>EU IP]) -->|TLS| cf[Cloudflare<br/>EU edge]
    cf -->|TLS origin| edge[edge Caddy<br/>OVH VPS Roubaix FR]
    edge -->|HTTP local| innercaddy[Inner Caddy]
    innercaddy --> api[FastAPI<br/>structlog JSON]
    api -->|TLS| pg[Postgres 15<br/>same VPS]

    api -.->|Stripe API| stripe[Stripe<br/>EU + US]
    api -.->|FCM API| fcm[Firebase<br/>EU + US]

    edge -->|JSON access log<br/>50 MB × 7| accesslog[/opt/edge/logs/access.log]
    accesslog -->|Promtail| loki[Loki 14 d<br/>same VPS]
    api -->|stdout JSON| dockerlog[Docker json-file]
    dockerlog -->|Promtail| loki

    api -->|OTLP gRPC| tempo[Tempo 14 d<br/>same VPS]

    pg -->|pg_dump piped| restic[Restic encrypted<br/>/var/backups/bagtrip-restic<br/>local on VPS]
    restic -.->|"optional B2 toggle<br/>(off in M5 phase)"| b2[(Backblaze B2<br/>EU bucket)]:::dim

    classDef dim fill:#fff,stroke:#999,color:#666,stroke-dasharray: 4 4;
```

## Where data physically resides

| Stage | Hoster | Region | Encryption |
|---|---|---|---|
| Caddy edge logs | OVH VPS | Roubaix (FR) | At rest: ext4 default (no FDE on this VPS) |
| Postgres | OVH VPS | Roubaix (FR) | At rest: ext4 default |
| Loki blocks | OVH VPS | Roubaix (FR) | At rest: ext4 default |
| Tempo blocks | OVH VPS | Roubaix (FR) | At rest: ext4 default |
| Restic repo | OVH VPS | Roubaix (FR) | **AES-256 at rest** (restic native) |
| Backblaze B2 (when enabled) | Backblaze | EU bucket | restic AES + B2 SSE |
| Stripe data | Stripe | EU + US (PCI) | TLS in transit, Stripe encryption at rest |

The whole pipeline stays on EU hosts (OVH FR + Cloudflare EU edge +
Stripe EU presence) so cross-border transfer flags don't fire under
GDPR. Stripe US side is covered by Stripe's SCC + DPF certifications.

## Retention

| Type | Default retention | Override |
|---|---|---|
| Caddy access logs (file rotation) | 7 × 50 MB = 350 MB | rotation in Caddyfile |
| Loki | 14 days | `observability_loki_retention_period` (336 h) |
| Prometheus TSDB | 30 days OR 20 GB cap, whichever first | `observability_prometheus_retention_*` |
| Tempo blocks | 14 days | `observability_loki_retention_period` (re-used) |
| Restic snapshots | 7 daily / 4 weekly / 6 monthly | `observability_restic_retention` |
| Postgres `users.deleted_at` | retained until DSAR-driven hard delete | application logic |

Any user-driven data deletion (account deletion request) MUST cascade
to:
1. `users` row hard-deleted (or anonymised — TBD by product)
2. `trips`, `activities`, `bookings`, `device_tokens` for that user
3. Stripe Customer object (via the Stripe API)
4. *Future: a Loki / Tempo deletion job for trace_id ↔ user_id pairs.
   Currently logs are time-bounded so 14 d after a delete request the
   data falls out of the retention window naturally.*

This is documented as an open follow-up — full DSAR automation is not
in the M5 scope.

## Access controls (operator side)

| Resource | Who can access | Mechanism |
|---|---|---|
| OVH VPS shell | Yanis only | SSH key-based, `ubuntu` (sudoer) + `deploy` (no sudo) |
| Grafana dashboards | Yanis + jury (read) | Caddy basic_auth + Grafana login (single password persisted in `.env`) |
| Postgres superuser | none externally | Docker network only, `bagtrip` user with strong password |
| Restic repo | Yanis only | `RESTIC_PASSWORD` in `/opt/observability/.env` (mode 0600 deploy:deploy) |
| Stripe dashboard | Yanis only | 2FA on Stripe |
| Cloudflare account | Yanis only | 2FA on Cloudflare |

## Audit posture

- **Authentication events**: visible in Loki (`{service=api, env=prod}
  |= "/auth/login" or "/auth/refresh"`).
- **Edge requests**: visible in Loki (`{job=caddy_edge_access}` with
  `client_ip`, `host`, `uri`, `status` labels).
- **Container syscalls**: not yet captured (Falco runtime deferred,
  Phase 5b).
- **Sudo invocations on host**: visible in `/var/log/auth.log` →
  journald → Promtail → Loki (when SD picks up the host journal —
  currently scrapes Docker only; auditd rule + journal scrape are
  next-step polish).

## Pending work for full RGPD posture

These items are *out of M5 scope* but documented for the next
iteration:

1. **Filesystem-level encryption** on the VPS (LUKS) — currently relies
   on OVH's physical security + restic encryption for the highest-value
   subset (DB dumps).
2. **Automated DSAR** (data subject access request) workflow — manual
   today.
3. **PII redaction** in app logs at structlog level — current logs
   already avoid logging password / token / PII intentionally
   (`api/src/utils/logger.py`), but it's a code review discipline,
   not a technical guarantee.
