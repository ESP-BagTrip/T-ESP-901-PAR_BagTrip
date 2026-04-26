# Runbook — Suspected cryptominer (sustained container CPU)

> Triggered by: `ContainerCPUSustained` (`infra/.../alerts/containers.yml.j2`).
> Pattern matches the **2026-04-26 cryptominer incident** signature documented
> in `documentations/security/incident-2026-04-26-cryptominer.md`.

## Symptoms

A single bagtrip container is pegged > 85 % of one CPU for more than 5 minutes
with no corresponding traffic spike on the same service in Grafana's API RED
dashboard. During the 26/04 incident, `bagtrip-preprod-admin-1` ran at 99 %
CPU for **7h45min** before any signal fired — this rule trims that window to
5 minutes.

## Triage in under 2 minutes

```bash
ssh yanis

# 1. Confirm the suspect container & PID
sudo docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
ps aux --sort=-%cpu | head -10

# 2. Inspect the binary backing the suspect process
sudo ls -la /proc/<PID>/exe                              # `.../<bin> (deleted)` is a red flag
sudo file /proc/<PID>/exe
sudo cat /proc/<PID>/cgroup                              # confirms the docker container

# 3. Where is it talking to?
sudo cat /proc/<PID>/net/tcp | awk '{print $2,$3,$4}'    # local <-> remote, hex
sudo ss -tnp | grep <PID>

# 4. Cross-check Loki for an exec-from-/tmp pattern in the last hour
#    Grafana → Logs → query: {service="<svc>"} |= "/tmp/" | json
```

## Containment (in this order — preserve evidence first)

```bash
# A. Capture the binary BEFORE killing the process (cf. §6.3 of the post-mortem)
sudo mkdir -p /var/log/incident
sudo cp /proc/<PID>/exe /var/log/incident/$(date +%Y%m%d-%H%M%S).bin
sudo sha256sum /var/log/incident/*.bin

# B. Freeze a Docker image of the live container
sudo docker commit <container> forensic/<container>-compromised:$(date +%Y%m%d-%H%M%S)

# C. Block the C2 IP at the host firewall (persisted by iptables-persistent)
sudo iptables -I OUTPUT -d <REMOTE_IP> -j DROP -m comment --comment "incident-$(date +%Y-%m-%d)"
sudo iptables -I DOCKER-USER -d <REMOTE_IP> -j DROP -m comment --comment "incident-$(date +%Y-%m-%d)"
sudo netfilter-persistent save

# D. Stop the container
sudo docker stop <container>
```

## Recovery

1. Identify the CVE / exploit path (Loki access logs around the first
   suspicious `exec` in the container journal).
2. Rebuild the image with the dependency bumped (`docker compose build
   --no-cache <service>`).
3. Recreate the container from the new image. **Do not `docker start` the
   compromised one** — it still has whatever state the attacker left.
4. Hardening checklist (already applied to bagtrip-admin since 26/04;
   verify on the affected service):
   - `read_only: true`
   - `tmpfs: /tmp:noexec,nosuid`
   - `cap_drop: [ALL]` + minimal `cap_add`
   - `security_opt: [no-new-privileges:true]`

## Escalation

- **Always** open an `incident-YYYY-MM-DD-<short>.md` post-mortem in
  `documentations/security/` regardless of containment success.
- If the binary persisted to disk under `/opt`, treat the host (not just
  the container) as compromised — full VPS rebuild required.

## Why this rule exists

Without it, the loudest possible signal a real attacker can produce takes
hours to surface: Netdata's default sustained-CPU alert is a 10-minute
average, and the 26/04 attacker ran 7h45min before being caught. Falco
(Phase 5) will add behavioural detection on top of this so quieter
exploits (e.g. data exfil at low CPU) can also be caught.
