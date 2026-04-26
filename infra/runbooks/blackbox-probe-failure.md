# Runbook — Public endpoint probe failing

> Triggered by: `BlackboxProbeDown` (3 consecutive failed probes ≈ 90 s).

## Triage

```bash
# From your laptop (verifies the FULL path: Cloudflare → edge → inner stack)
curl -sI -m 10 https://<failing-host>

# From the VPS (skips Cloudflare — verifies edge + inner stack only)
ssh yanis 'curl -sI --resolve <failing-host>:443:127.0.0.1 -m 10 https://<failing-host>'
```

## Decide where the failure is

| External `curl` says | Internal `curl` says | Likely cause |
|---|---|---|
| Timeout | OK | Cloudflare / DNS issue. Check Cloudflare dashboard. |
| 5xx | 5xx | Inner stack — see `api-down.md` or `container-restart-loop.md`. |
| TLS error | TLS error | Cert expired or mismatched — see `tls-cert-expiry.md`. |
| 502 from Caddy | timeout | Inner Caddy can't reach the upstream container. |

## edge Caddy is the most common failure point

```bash
ssh yanis
sudo docker logs --tail 50 edge-caddy 2>&1 | grep -iE "error|warn"
sudo docker exec edge-caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

If a recent edit to `/opt/edge/Caddyfile` introduced a syntax error,
`caddy validate` exits non-zero. The previous backup is at
`/opt/edge/Caddyfile.bak` — copy back and recreate the container.

## Don't

- Don't restart `edge-caddy` blindly: it currently bind-mounts the
  Caddyfile as a single file (Phase 1c carry-over), so a `--force-recreate`
  is the only way to pick up new config — but that briefly takes every
  public hostname offline.
