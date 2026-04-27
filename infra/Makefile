# BagTrip infrastructure / observability stack — operator entry points.
# All targets thin-wrap `ansible-playbook` so the team has a single place
# to look for "how do I drive infra".

ANSIBLE_DIR    := ansible
INVENTORY      := $(ANSIBLE_DIR)/inventory/hosts.yml
PLAYBOOK       := $(ANSIBLE_DIR)/playbooks/site.yml

# Pass extra Ansible flags via EXTRA, e.g.:
#   make -C infra deploy EXTRA='--tags observability -vv'
EXTRA ?=

.PHONY: help ping check deploy lint redeploy redeploy-demo

help:  ## list available targets
	@grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ — /'

ping:  ## ansible -m ping vps_prod (smoke test SSH/sudo plumbing)
	cd $(ANSIBLE_DIR) && ansible -i inventory/hosts.yml vps_prod -m ping

check:  ## dry-run the playbook (--check) — never modifies the host
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/hosts.yml playbooks/site.yml --check $(EXTRA)

deploy:  ## apply the playbook (default tag: observability)
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags observability $(EXTRA)

deploy-baseline:  ## apply only the baseline assertions
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags baseline $(EXTRA)

lint:  ## ansible-lint over the role
	cd $(ANSIBLE_DIR) && ansible-lint roles/ playbooks/ || true

redeploy-demo:  ## DESTRUCTIVE: tear down + ansible-rebuild the observability stack
	@echo ">>> This will destroy /opt/observability containers + named volumes (logs / metrics / traces history)."
	@echo ">>> Application stacks (bagtrip prod / preprod / edge) are NOT touched."
	@bash scripts/destroy-redeploy-demo.sh

# --- Convenience: tail journal of the restic timers ----------------------
restic-status:  ## show last backup + restore-drill status
	@ssh yanis 'sudo systemctl list-timers --no-pager | grep restic; echo; sudo journalctl -u restic-backup.service --since "24 hours ago" --no-pager | tail -20'

restic-backup-now:  ## run the nightly backup synchronously (ad-hoc)
	@ssh yanis 'sudo systemctl start restic-backup.service && sudo journalctl -u restic-backup.service -f'

restic-restore-test-now:  ## run the weekly restore drill synchronously (ad-hoc)
	@ssh yanis 'sudo systemctl start restic-restore-test.service && sudo journalctl -u restic-restore-test.service -f'
