#!/usr/bin/env bash
# BagTrip observability stack — destroy & redeploy demo (Phase 8).
#
# This is the live demo for the M5 jury: prove that the observability stack
# is fully reproducible from the Ansible role + the persisted /etc state on
# the VPS (passwords, restic repo, certs).
#
# What it does, in order:
#   1. Snapshots the current state (container count, sample metric values)
#   2. `docker compose down -v` on /opt/observability — kills every container
#      AND nukes the named volumes (Prometheus TSDB, Loki blocks, Tempo
#      blocks, Grafana DB). Bagtrip prod / preprod / edge are NOT touched.
#   3. Re-runs `ansible-playbook` from the controller (this machine).
#   4. Re-snapshots and diffs.
#
# What it preserves:
#   - /opt/observability/.env (passwords, the restic password)
#   - /var/backups/bagtrip-restic (the restic repository)
#   - /etc/iptables/rules.v4 (the persisted firewall rules)
#   - /etc/systemd/system/restic-*.{service,timer}
#   - /opt/edge/Caddyfile (with the Phase 1c Grafana vhost block)
#
# Safe to run from a project-root shell:
#   make -C infra redeploy-demo
# or directly:
#   bash infra/scripts/destroy-redeploy-demo.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ANSIBLE_DIR="$REPO_ROOT/infra/ansible"
SSH_HOST="yanis"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }

snapshot() {
  ssh "$SSH_HOST" '
    echo "## containers"
    sudo docker ps --filter "name=observability-" --format "{{.Names}}\t{{.Status}}" | sort
    echo
    echo "## prometheus uptime (seconds)"
    curl -s http://127.0.0.1:9090/api/v1/query?query=time%28%29-process_start_time_seconds 2>/dev/null \
      | python3 -c "import json,sys; d=json.load(sys.stdin)[\"data\"][\"result\"]; print(d[0][\"value\"][1] if d else \"n/a\")"
    echo
    echo "## loki series (any)"
    curl -s "http://127.0.0.1:3100/loki/api/v1/labels" 2>/dev/null \
      | python3 -c "import json,sys; print(len(json.load(sys.stdin)[\"data\"]), \"labels\")"
    echo
    echo "## tempo spans received total"
    sudo docker exec observability-prometheus wget -qO- http://tempo:3200/metrics 2>/dev/null \
      | grep "^tempo_distributor_spans_received_total" || echo "tempo unreachable"
  ' || true
}

bold "==> 1/4  current state"
snapshot

bold "==> 2/4  destroying observability stack (containers + named volumes)"
ssh "$SSH_HOST" '
  sudo docker compose -f /opt/observability/compose.yml down -v --remove-orphans
'
red "    stack DOWN — Grafana / Prom / Loki / Tempo / Alertmanager all gone."

bold "==> 3/4  re-running ansible-playbook (rebuild from scratch)"
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags observability

bold "==> 4/4  post-rebuild state"
sleep 8
snapshot

green "==> done."
echo
echo "Verify in the browser:"
echo "  https://grafana.bagtrip.fr  (same admin password as before — passwords"
echo "                                were persisted via /opt/observability/.env)"
echo "  Dashboards: 10 (auto-provisioned)"
echo "  Restic repo + snapshots: still on /var/backups/bagtrip-restic"
echo
echo "What changed:"
echo "  * Prometheus / Loki / Tempo started fresh — no metric / log / trace"
echo "    history before the rebuild moment."
echo "  * Container creation timestamps reset."
echo
echo "What survived:"
echo "  * Grafana admin + Caddy basic_auth credentials (.env)"
echo "  * Restic repo + previous snapshots (separate /var/backups path)"
echo "  * iptables rules (netfilter-persistent rules.v4)"
echo "  * Systemd timers (restic-backup.timer, restic-restore-test.timer)"
echo "  * Edge Caddyfile vhosts (Grafana public exposure, /metrics vhost)"
