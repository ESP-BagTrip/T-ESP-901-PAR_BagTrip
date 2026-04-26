# Runbook — TLS certificate expiring

> Triggered by: `TlsCertificateExpiringSoon` (warn, < 14 days),
> `TlsCertificateExpiringCritical` (page, < 3 days).

## Where the cert lives

- Public hosts (`*.bagtrip.fr`): auto-provisioned by Caddy via Let's
  Encrypt — should renew automatically when ≤ 30 days.
- `vault-cards.com`, `claw.zatoun.fr`: Cloudflare Origin certificates
  manually placed under `/opt/edge/certs/`. **Manual rotation required.**

## Triage

```bash
ssh yanis
sudo docker exec edge-caddy caddy list-certs 2>&1 | head -30
sudo openssl x509 -in /opt/edge/certs/origin.pem -noout -dates       # for the manual ones
```

If Caddy's auto-https is stuck, the most common cause is the renewal
ACME challenge being intercepted by Cloudflare proxy. Verify the relevant
DNS record is **DNS-only** (gray cloud) for ACME or that
`tls.dns.cloudflare` is configured with an API token.

## Mitigation

- **Auto-renewal stuck** → run `sudo docker exec edge-caddy caddy reload
  --config /etc/caddy/Caddyfile`; Caddy retries on next loop.
- **Origin cert expired (vault-cards.com / zatoun.fr)** → re-issue from
  Cloudflare dashboard, replace `origin.pem` / `origin-key.pem` (mode
  0600 deploy:deploy), recreate edge-caddy.

## Don't

- Don't comment out the affected vhost — that breaks redirect / HSTS for
  any visitor who already cached our `Strict-Transport-Security` header.
