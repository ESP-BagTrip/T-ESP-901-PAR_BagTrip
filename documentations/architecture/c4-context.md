# C4 — Level 1: System context

> Author: Yanis Lounadi · 2026-04-27 · part of the Phase 9 documentation
> set. The diagram below is GitHub-rendered Mermaid; PNG / SVG can be
> exported via Excalidraw or Structurizr if needed for the slide deck.

```mermaid
graph LR
    user_mobile([Mobile traveller<br/>Flutter app])
    user_admin([Internal ops<br/>BagTrip team])
    sre([SRE / on-call<br/>Yanis])
    jury([M5 jury<br/>read-only audit])

    bagtrip[("BagTrip system<br/>(this deliverable)")]:::sys

    cf[Cloudflare<br/>DNS + WAF + DDoS]
    amadeus[Amadeus<br/>flights + hotels API]
    stripe[Stripe<br/>payments + webhooks]
    llm[OVH GPT-OSS<br/>LLM endpoint]
    fcm[Firebase FCM<br/>push notifications]
    b2[Backblaze B2<br/>off-site backups - documented escape hatch]:::dim

    user_mobile -->|HTTPS| cf
    user_admin -->|HTTPS| cf
    cf -->|origin TLS| bagtrip
    sre -->|SSH 'yanis' alias| bagtrip
    sre -->|HTTPS grafana.bagtrip.fr| bagtrip
    jury -->|HTTPS grafana.bagtrip.fr<br/>+ GitHub repo| bagtrip
    bagtrip -->|outbound API| amadeus
    bagtrip -->|outbound API + webhook in| stripe
    bagtrip -->|outbound API| llm
    bagtrip -->|outbound API| fcm
    bagtrip -.->|optional, off| b2

    classDef sys fill:#0e639c,stroke:#000,color:#fff,stroke-width:2px;
    classDef dim fill:#fff,stroke:#999,color:#666,stroke-dasharray: 4 4;
```

## Outside the perimeter

- **Cloudflare** terminates DNS for every public hostname under
  `bagtrip.fr` and most other BagTrip-related domains. It absorbs
  L3/L4 DDoS and runs the free-tier WAF. We do not configure it via
  IaC in this deliverable; secret-of-trust accepted.
- **Amadeus** (test mode) supplies flight + hotel inventory.
- **Stripe** handles payments; webhooks come back into the API at
  `/v1/stripe/...`.
- **OVH GPT-OSS** is the LLM endpoint behind the trip planner.
- **Firebase FCM** delivers push notifications to the Flutter app.
- **Backblaze B2** is the documented off-site escape hatch for
  Restic. Off by default — local repo is the M5-phase deployment
  (see ADR-0005).

## Roles

- **Mobile traveller** uses the Flutter app to plan + manage trips.
- **Internal ops** uses the Next.js admin to triage user / trip /
  payment issues; it is the single highest-value compromise target.
- **SRE / on-call** is one person at the M5 phase (the author).
  Reaches the VPS via SSH and Grafana via HTTPS.
- **M5 jury** has read-only access to Grafana (`grafana.bagtrip.fr`,
  Caddy basic_auth + Grafana login) and the GitHub repository.

## What "the system" means

`bagtrip` in the diagram is everything inside the OVH VPS that this
deliverable manages: prod stack, preprod stack, edge Caddy, the
observability stack. See `c4-containers.md` for the level-2
breakdown.
