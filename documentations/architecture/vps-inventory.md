# Inventaire VPS BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip tourne en mono-VPS sur OVH. Une seule machine heberge les
deux environnements applicatifs (production + preproduction) et la
stack d'observabilite, derriere un Caddy de bordure place devant
Cloudflare. Le VPS est referenes dans Ansible (`infra/ansible/inventory/hosts.yml`)
sous l'identifiant `vps_prod`, dans le groupe `bagtrip_vps`.

Roles assumes par la machine :

- Heberger les containers Docker des stacks `bagtrip` (prod) et
  `bagtrip-preprod` (preprod) sous `/opt/`.
- Faire tourner la stack d'observabilite (`/opt/observability`)
  deployee par le role Ansible `observability_stack`.
- Servir le trafic public via le Caddy de bordure (`/opt/edge`)
  qui termine TLS pour tous les hostnames `*.bagtrip.fr`.
- Recevoir les deploiements continus depuis GitHub Actions
  (workflow `.github/workflows/cd.yml`) via SSH.
- Heberger le repository Restic local pour les sauvegardes
  Postgres.

OS : Ubuntu 25.04, kernel 6.14, 8 vCPU / 31 GiB RAM, disque
ext4 193 GiB. Pas de swap. Docker Engine 29.x. Aucun socket
Docker n'est expose a un container hors observabilite.

## Acces

| Canal | Detail |
|---|---|
| SSH operateur | Alias `yanis` declare dans `~/.ssh/config` (resolution + ProxyJump + cle) |
| Utilisateur SSH | `ubuntu` (sudoer, hors groupe `docker`) |
| Utilisateur CD | `deploy` (proprietaire de `/opt/bagtrip*`, hors groupe `docker`) |
| Root SSH | Desactive |
| GitHub Actions | Secrets `OVH_HOST`, `OVH_USER`, `OVH_SSH_KEY` (cf `.github/workflows/cd.yml`) |
| Ansible control plane | `infra/ansible/inventory/hosts.yml` cible `ansible_host: yanis` |

Le Caddy admin API est lie en loopback (`127.0.0.1:2019`), aucune
API d'administration des containers n'est exposee a Internet.

## Stacks deployes

Les stacks sont rangees sous `/opt/` avec un repo git par stack,
proprietaire `deploy:deploy`. Le workflow CD fait un
`git reset --hard` sur la branche cible puis un
`docker compose up -d --build`.

| Stack | Path | Compose | Description |
|---|---|---|---|
| bagtrip (prod) | `/opt/bagtrip` | `compose.prod.yml` + `.env.production` | API FastAPI + admin Next.js + Postgres + Redis + Caddy interne, branche `main` |
| bagtrip-preprod | `/opt/bagtrip-preprod` | `compose.prod.yml` + `.env.production` | Meme topologie que prod, branche `develop`, Caddy interne sur port 8082, donnees clonees depuis prod a chaque deploy |
| edge | `/opt/edge` | `compose.yml` (caddy host network) | Caddy 2 de bordure, termine TLS pour tous les hostnames publics, logs JSON dans `/opt/edge/logs/access.log` |
| observability | `/opt/observability` | Genere par `roles/observability_stack` (`compose.yml.j2`) | Prometheus, Grafana, Loki, Promtail, Tempo, Alertmanager, exporters et Blackbox |

Profil Falco present mais inactif sur la stack observability
(profile compose `security` non active sur ce kernel).

## Containers bagtrip (prod et preprod)

Topologie strictement identique entre prod et preprod, le seul
ecart est le port loopback du Caddy interne (`CADDY_HOST_PORT`
8081 en prod, 8082 en preprod) et les volumes Docker dont le
nom est prefixe par le nom de stack (`bagtrip_*` vs
`bagtrip-preprod_*`). Les noms de containers utilises ci-dessous
sont ceux de la prod ; en preprod il faut lire `bagtrip-preprod-<name>-1`.

| Container | Image | Role | Expose |
|---|---|---|---|
| `bagtrip-postgres-1` | `postgres:15-alpine` | Base relationnelle BagTrip | Reseau interne Docker uniquement |
| `bagtrip-redis-1` | `redis:7-alpine` | Sessions, rate limit, idempotency, locks distribues | Reseau interne Docker uniquement |
| `bagtrip-api-1` | Build local `./api` | FastAPI + Uvicorn, port 3000, healthcheck `/health` | Reseau interne, scrape OTel vers `tempo:4317` |
| `bagtrip-admin-1` | Build local `./admin-panel` | Next.js 14, port 8000, read-only rootfs, `cap_drop: ALL`, tmpfs sur `/tmp` et `/app/.next/cache` | Reseau interne uniquement |
| `bagtrip-caddy-1` | `caddy:2-alpine` | Reverse proxy interne, route par hostname (`bagtrip.fr` -> admin, `api.bagtrip.fr` -> api), bloque `/metrics` publics | `127.0.0.1:8081` (prod), `127.0.0.1:8082` (preprod) |

Le Caddyfile interne est partage entre prod et preprod, le tri
des requetes se fait sur le `Host` propage par le Caddy de bordure.

## Containers observability_stack

Deployes par le role `observability_stack` sous `/opt/observability`.
Multi-homed sur les reseaux Docker externes `bagtrip_default` et
`bagtrip-preprod_default` pour atteindre les containers d'app
sans publier de port.

| Container | Image | Role |
|---|---|---|
| `observability-prometheus` | `prom/prometheus:v2.55.1` | Scrape des cibles, retention 30j / 20 GB |
| `observability-grafana` | `grafana/grafana:11.4.0` | UI dashboards et alertes |
| `observability-alertmanager` | `prom/alertmanager:v0.27.0` | Routage alertes (webhook Discord optionnel) |
| `observability-loki` | `grafana/loki:3.3.2` | Logs centralises (retention 14j) |
| `observability-promtail` | `grafana/promtail:3.3.2` | Collecte logs Docker + journald + `/opt/edge/logs` |
| `observability-tempo` | `grafana/tempo:2.7.1` | Traces OTLP recues sur `tempo:4317` depuis l'API |
| `observability-node-exporter` | `prom/node-exporter:v1.8.2` | Metriques hote, lit `textfile` pour metrics Restic |
| `observability-cadvisor` | `gcr.io/cadvisor/cadvisor:v0.55.1` | Metriques par container |
| `observability-postgres-exporter-prod` | `prometheuscommunity/postgres-exporter:v0.16.0` | Metriques Postgres prod |
| `observability-postgres-exporter-preprod` | meme image | Metriques Postgres preprod |
| `observability-redis-exporter-prod` | `oliver006/redis_exporter:v1.66.0` | Metriques Redis prod |
| `observability-redis-exporter-preprod` | meme image | Metriques Redis preprod |
| `observability-blackbox-exporter` | `prom/blackbox-exporter:v0.25.0` | Sonde HTTP des hostnames publics |
| `observability-falco` | `falcosecurity/falco:0.39.0` | Profile compose `security`, non active par defaut |

## Hostnames publics

Tous les hostnames passent par Cloudflare (proxy + certificat
origin Cloudflare en `/opt/edge/certs/`). Le Caddy de bordure
ecoute en host network sur 80 et 443 et route vers le Caddy
interne du stack concerne.

| Hostname | Backend | Public/Restricted |
|---|---|---|
| `bagtrip.fr` | bagtrip prod -> admin Next.js | Public |
| `api.bagtrip.fr` | bagtrip prod -> api FastAPI | Public |
| `dev.bagtrip.fr` | bagtrip-preprod -> admin Next.js | Public (preprod) |
| `api.dev.bagtrip.fr` | bagtrip-preprod -> api FastAPI | Public (preprod) |
| `grafana.bagtrip.fr` | observability -> Grafana (`127.0.0.1:8087`) | Restricted (basic auth edge Caddy) |
| `monitoring.bagtrip.fr` | Netdata historique (`127.0.0.1:8085`) | Restricted (basic auth edge Caddy) |

Endpoints `/metrics` publics : refuses par les Caddyfiles
internes ET par un drop iptables sur le port `8089` Caddy edge
metrics. Les exporters internes sont scrapes via DNS Docker.

## Volumes persistents

Tous les volumes sont des volumes Docker nommes, geres par chaque
compose. Les chemins host vivent sous `/var/lib/docker/volumes/`.

| Volume | Stack | Contenu |
|---|---|---|
| `bagtrip_postgres_data` | bagtrip prod | Donnees Postgres production |
| `bagtrip_redis_data` | bagtrip prod | Snapshot Redis (`--save 60 1`) |
| `bagtrip_caddy_data` / `bagtrip_caddy_config` | bagtrip prod | Etat Caddy interne |
| `bagtrip-preprod_postgres_data` | bagtrip preprod | Donnees Postgres preprod (ecrasees a chaque deploy) |
| `bagtrip-preprod_redis_data` | bagtrip preprod | Snapshot Redis preprod |
| `bagtrip-preprod_caddy_data` / `bagtrip-preprod_caddy_config` | bagtrip preprod | Etat Caddy interne preprod |
| `observability_prometheus_data` | observability | TSDB Prometheus (30j / 20 GB) |
| `observability_grafana_data` | observability | Config et dashboards Grafana persistes |
| `observability_loki_data` | observability | Index + chunks Loki (14j) |
| `observability_promtail_data` | observability | Position des tailers de logs |
| `observability_tempo_data` | observability | Traces stockees |
| `observability_alertmanager_data` | observability | Etat silences / notifications |

Chemins host hors volumes Docker :

- `/var/backups/bagtrip-restic` : repository Restic local
  (cf. `observability_restic_local_repo_path`).
- `/var/lib/node_exporter/textfile` : metriques Prometheus
  ecrites par les hooks Restic (backup + restore drill).
- `/opt/edge/logs/access.log` : logs JSON Caddy, monte
  read-only dans Promtail.
- `/opt/edge/certs/` : certificats Cloudflare origin.

## Backups Restic

Geres par `roles/observability_stack` via deux unites systemd
templatisees :

- `restic-backup.timer` -> `restic-backup.service` : tous les
  jours a 02:00 UTC, snapshot Postgres prod + preprod
  (cibles definies dans `observability_restic_targets`).
  Le script `restic_backup.sh` exporte les bases via
  `pg_dump` puis pousse dans le repo Restic et ecrit les
  metriques de succes / duree dans le textfile node_exporter.
- `restic-restore-test.timer` -> `restic-restore-test.service` :
  tous les dimanches a 03:00 UTC, lance
  `restic_restore_test.sh` qui restaure le dernier snapshot
  dans un container Postgres jetable et verifie l'integrite.

Politique de retention : 7 daily, 4 weekly, 6 monthly.
Repository par defaut local sous `/var/backups/bagtrip-restic`,
basculable vers Backblaze B2 via les variables
`observability_restic_repository`, `observability_restic_b2_account_id`
et `observability_restic_b2_account_key`.

## Ce qu'il manque

Limites identifiees a la cloture du projet :

- **Single point of failure** : tout vit sur un seul VPS OVH.
  Pas de standby, pas de bascule automatique. Un incident
  hardware = downtime complet jusqu'a restore Restic sur une
  nouvelle machine.
- **Backups off-site** : Restic ecrit par defaut sur le meme
  disque que les bases. La bascule B2 est cablee mais pas
  activee en prod.
- **Pas d'IaC pour les stacks app** : seul `observability_stack`
  est decrit dans Ansible. `bagtrip`, `bagtrip-preprod` et
  `edge` sont deployes via `git pull` + `docker compose`,
  sans role Ansible qui materialise l'etat attendu.
- **Pas de rotation de secret automatisee** : `.env.production`
  est edite manuellement sur le VPS, jamais sealed / pas de
  vault central.
- **Falco hors service** : le profile `security` du compose
  observability reste off, le probe eBPF echoue sur le kernel
  6.14 du VPS.
- **Pas de monitoring synthetic externe** : Blackbox tourne
  depuis le VPS lui-meme, donc une panne reseau OVH ne genere
  ni alerte ni metrique.
- **DNS Cloudflare** : pas de Terraform / pas d'export
  versionne des records, la zone est manipulee a la main
  dans la console.
