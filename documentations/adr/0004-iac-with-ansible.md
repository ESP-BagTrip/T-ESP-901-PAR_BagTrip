# ADR-0004 — Infrastructure-as-code with Ansible (not Terraform / k8s)

- **Status**: accepted
- **Date**: 2026-04-27
- **Authors**: Yanis Lounadi

## Context

The "I" in "M5 IaC" is graded; what matters operationally is whether the
observability stack can be reproduced from a clean slate without manual
steps. Three families of tools were on the table:

- **Configuration management** — Ansible, Salt, Puppet, Chef
- **Infrastructure provisioning** — Terraform, Pulumi, OpenTofu
- **Container orchestration** — Kubernetes (k3s / k0s flavours), Nomad

The state we manage:
1. Host packages (`restic`, `iptables-persistent`)
2. systemd unit files (the restic timer)
3. iptables rules (`netfilter-persistent`)
4. File templates rendered from Ansible variables
5. Docker compose stacks (created by `docker compose up` from rendered files)
6. Container images (pulled by docker, version-pinned in our compose)
7. **No external cloud resources** — no managed DBs, no S3 buckets that
   need provisioning, no IAM. The OVH VPS itself is provisioned manually.

## Decision

We pick **Ansible** as the single IaC tool, deployed from the developer's
laptop (or eventually CI) against `vps_prod` over SSH. The role lives at
`infra/ansible/roles/observability_stack/`; everything an operator needs
flows through `make -C infra deploy`.

We **deliberately do not** layer Terraform on top, even though it is
fashionable, and we do not migrate to Kubernetes.

## Consequences

### Easier
- One language (YAML + Jinja), one execution model (push-based SSH),
  one state model (the live host is the source of truth, no
  `terraform.tfstate` to babysit).
- The "destroy & redeploy" demo (`make -C infra redeploy-demo`) is a
  6-line bash script: `docker compose down -v` then
  `ansible-playbook`. 50 seconds end to end.
- Idempotence is verified by re-running the playbook (the role lands
  `ok=68 changed=0` on a converged host) — same pattern jurys have
  seen in any Ansible course.

### Harder
- No automatic provisioning of the OVH VPS itself: when we eventually
  need to spin a second host (a staging environment, a DR replica),
  the bootstrap is manual until we add a Terraform-OVH or pulumi
  layer for compute resources only.
- No declarative drift detection beyond what `--check` mode catches
  — we don't get a Terraform-style "X resources will change" preview
  for non-Ansible-managed state (e.g. ad-hoc Docker volumes, manual
  edits on the host).

### Now off-limits
- Mixing Terraform + Ansible state for the SAME resource. If we ever
  add Terraform for cloud resources, it must own provisioning only;
  Ansible owns configuration. No dual-ownership.
- "Just SSH and edit" on `/opt/observability/*` — every change goes
  through the role.

## Alternatives considered

| Alternative | Rejected because |
|---|---|
| **Terraform for everything** | Adds a state file we don't need (no cloud-API resources to track). The `cloud-init` / `local-exec` provisioner workarounds for installing `restic` etc. are awkward. Doubles the tool surface area. |
| **Kubernetes / k3s** | Adds etcd, an API server, kubelet on the host, Helm charts to maintain. Solves scheduling problems we don't have on a single VPS. The 26/04 incident already demonstrated that container isolation alone is insufficient (the container was compromised); Kubernetes wouldn't have changed that outcome. |
| **GitOps (ArgoCD / Flux)** | Same reasoning as Kubernetes — these tools assume a Kubernetes target. The git-driven equivalent for our setup is to run `ansible-playbook` from CI on `develop` / `main` merges, which is a 10-line GitHub Action away when we want it. |
| **Pure docker-compose without IaC** | Can't deploy the systemd timers (Restic), the iptables rules, the Caddy edge changes, or the host-level packages from compose. Ansible was needed for those. |
| **Salt / Puppet** | Comparable feature set; Ansible's push-based SSH model fits "one VPS, one operator" better than the agent-based alternatives. |

## References

- `infra/ansible/roles/observability_stack/` (the role)
- `infra/Makefile` (operator entry points)
- `infra/scripts/destroy-redeploy-demo.sh` (the live demo)
- ADR-0001 (umbrella observability strategy)
