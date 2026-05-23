# Architecture globale -- BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip est une application de planification de voyages assistee par IA. Le scenario nominal : l'utilisateur decrit ses envies (dates, budget, destinations, style), un agent LLM streame un voyage complet (activites jour par jour, hebergements, vols, bagages, budget) en SSE, puis l'utilisateur valide, modifie et partage. Une fois le voyage en cours, l'app sert de compagnon (activites du jour, meteo destination, checklist bagages, depenses trackees, suggestions post-voyage).

Features principales :

- Plan trip wizard 6 etapes (dates -> voyageurs/budget -> destination -> propositions IA -> generation SSE -> review), flows manuel et IA.
- Trip detail : activites, vols, hebergements, bagages, budget, partages, completion score avec optimistic updates.
- Recherche vols Amadeus persistee par trip, multi-criteres (prix, compagnie, bagages, horaires).
- Recherche hotels Amadeus, bookings manuels avec calcul de nuits.
- Sharing viewer / editor par email avec mode read-only pour invites.
- Post-trip feedback et suggestions IA (gated premium).
- Abonnement premium via Stripe.
- Notifications push (FCM) et scheduling local pour activites.
- Profil utilisateur avec preferences de voyage (types, style, budget, contraintes).

Le monorepo regroupe trois sous-projets independants orchestres par un Makefile racine et un `compose.yml` Docker pour le dev local. La CI/CD est gere via GitHub Actions, le deploiement final tourne sur un VPS OVH (voir `infrastructure/`).

## Monorepo

| Dossier | Stack | Role |
|---------|-------|------|
| `bagtrip/` | Flutter (Dart SDK ^3.8.0) | Application mobile iOS / Android : UI cliente, BLoC, Repository, cache offline Hive, push FCM, paiements Stripe |
| `api/` | FastAPI (Python 3.12+, uv) | Backend REST + SSE, agent LangGraph, integrations Amadeus / Stripe / FCM / AirLabs / Open-Meteo / Unsplash, jobs schedulers |
| `admin-panel/` | Next.js 16 (React 19, TypeScript) | Back-office equipe BagTrip : triage users / trips / payments / notifications / content / feature flags |
| `compose.yml` | Docker Compose | Stack dev locale (db, redis, api, admin-panel) |
| `Makefile` | GNU Make | Orchestrateur centralise (init, dev, lint, test, db, deploy) |
| `documentations/` | Markdown | Specs, ADR, threat-model, infra, C4, runbooks |
| `infra/` | Ansible | Provisionnement VPS, roles observability / app-stack / edge |
| `kanban/` | Markdown | Suivi sprint |

## Stack technique

### Mobile (`bagtrip/`)

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter (Dart SDK ^3.8.0) |
| State management | `flutter_bloc` 9.x, `bloc` 9.x |
| Navigation | `go_router` 17.x avec routes typees `@TypedGoRoute` |
| DI | `get_it` 8.x (service locator) |
| Modeles | `freezed` 3.x + `json_serializable` 6.x |
| API client | `dio` 5.x avec JWT auto-injection et 401 refresh single-guard |
| Stockage securise | `flutter_secure_storage` 10.x (tokens) |
| Cache | `hive` 2.x (TTL 15 min, write queue offline) |
| Connectivite | `connectivity_plus` 6.x + `OfflineBanner` |
| Push | `firebase_messaging` 15.x + `flutter_local_notifications` 18.x |
| Observabilite | `firebase_crashlytics` 4.x, `firebase_performance` 0.10.x |
| Auth sociale | `google_sign_in` 6.x, `sign_in_with_apple` 6.x, `firebase_core` 3.x |
| Paiements | `flutter_stripe` 12.x |
| SSE | `flutter_client_sse` 2.x |
| i18n | `flutter_localizations` (EN + FR via ARB) |
| Design | FlutterGen (couleurs / fonts / assets), tokens centralises, widgets adaptatifs iOS / Android, liquid glass iOS 26+ |
| Tests | `flutter_test`, `integration_test`, `bloc_test`, `mocktail`, `mockito`, `http_mock_adapter` |

### Backend (`api/`)

| Composant | Technologie |
|-----------|-------------|
| Framework web | FastAPI (Python 3.12+) |
| Package manager | uv + pyproject.toml |
| ORM | SQLAlchemy 2.0 typed declarative (`Mapped[T]`) |
| Base de donnees | PostgreSQL 15 (pool tune, `selectinload` obligatoire sur relations) |
| Migrations | Alembic (`make db-revision`) |
| Cache / locks | Redis 7 (`get_redis_client()`, `redis_lock()`, rate limit) |
| Auth | JWT HS256 (`python-jose`), bcrypt, refresh token rotation, detection reuse |
| Validation | Pydantic v2 (camelCase via `populate_by_name=True` + `alias_generator`) |
| LLM / Agent | LangChain + LangGraph, OVH GPT-OSS 120B, prompts Jinja2 EN / FR |
| Vols | Amadeus (recherche, pricing, offers), AirLabs (info vols temps reel) |
| Paiements | Stripe SDK (subscriptions, webhooks signe avec `STRIPE_WEBHOOK_SECRET`) |
| Notifications | Firebase Admin SDK (FCM push) |
| HTTP sortant | `httpx.AsyncClient` singleton geres par le lifespan |
| Observabilite | `prometheus-fastapi-instrumentator`, OpenTelemetry (traces OTLP -> Tempo) |
| Securite | Middlewares request-id, security headers (HSTS / CSP / X-Frame), rate limit Redis |
| Tests | `pytest`, `pytest-asyncio`, `pytest-cov` (seuil CI 70 % sur `services/` et `api/`) |
| Lint / types | `ruff` (E, W, F, I, N, UP, B, C4, SIM), `mypy` (plugin pydantic), `bandit` |

### Admin Panel (`admin-panel/`)

| Composant | Technologie |
|-----------|-------------|
| Framework | Next.js 16.2 (App Router, Turbopack) |
| Runtime | React 19, TypeScript 5.9 |
| State / API | TanStack React Query 5.x, Zustand 5.x |
| Formulaires | `react-hook-form` 7.x + `@hookform/resolvers` + Zod 4.x |
| UI | Radix UI, Tailwind CSS 4, `lucide-react`, `cmdk`, `sonner`, `next-themes` |
| Tables | `@tanstack/react-table` 8.x |
| Graphiques | Recharts 3.x |
| Dates | `date-fns` 4.x, `react-day-picker` 9.x |
| HTTP | Axios 1.x |
| Paiements | `@stripe/stripe-js` 8.x |
| Metriques | `prom-client` (endpoint `/api/metrics` scrape par Prometheus) |
| Tests unit | Vitest 4.x, Testing Library, jsdom |
| E2E | Cypress 15.x avec `@cypress/code-coverage` |
| Lint / format | ESLint 9, Prettier 3, `tsc --noEmit` |
| Port | 8000 |

## Flux global

```
[Mobile Flutter]  <-- JWT + SSE -->  [FastAPI /v1]  <-- SQL -->  [PostgreSQL 15]
                                          |                          [Redis 7]
                                          |--- Amadeus      (vols, hotels)
                                          |--- OVH GPT-OSS  (LangGraph agent)
                                          |--- Stripe       (subs + webhooks)
                                          |--- FCM          (push)
                                          |--- AirLabs      (info vols)
                                          |--- Open-Meteo   (meteo)
                                          |--- Unsplash     (covers)

[Admin Next.js]   <-- HTTP -->        [FastAPI /admin]
```

Sequencage type d'un plan trip IA :

1. **Mobile** : `PlanTripBloc` collecte les inputs du wizard (6 etapes) et POST `/v1/agent/plan-trip-stream` avec `locale` + payload.
2. **API** : la route est un passe-plat vers `TripPlannerService.stream_plan()` qui lance le graphe LangGraph (destination research -> activities -> flights -> accommodations -> budget) et streame des events SSE par tick.
3. **Agent** : chaque node garde un budget cumulatif (`guard()` avant tout call LLM), invoque les tools (`flights`, `hotels`, `weather`, `locations`) et persiste le `Trip` + ses enfants au fil de l'eau via les services metier.
4. **Mobile** : le client consomme le flux SSE via `flutter_client_sse`, met a jour le state au fur et a mesure, gere les retries via `_cancelSseStream()` avant tout nouveau stream.
5. **Trip detail** : une fois cree, l'utilisateur ouvre le trip ; `TripDetailBloc` charge le hub centralise (trip + activities + flights + accommodations + baggage + budget + shares + completion) et applique des optimistic updates.
6. **Operations sur item** : tout edit / validate / replace passe par `ItemFormScaffold`, `QuickPreviewSheet`, `ReplaceSearchSheet` cote UI et les extensions `validate(...)` cote repository (single payload `{validationStatus: VALIDATED}`).
7. **Jobs backend** : deux schedulers asyncio tournent en lifespan : `trip_status_scheduler` (DRAFT -> PLANNED -> ONGOING -> COMPLETED) et `notification_scheduler` (rappels depart, H-4 / H-1 vol, resume matinal, alertes budget) avec lock distribue Redis.
8. **Admin** : l'equipe BagTrip se connecte au panel Next.js, qui consomme `/admin/*` via Axios et React Query, masque les champs sensibles via `redact_for_viewer()` cote backend.

Authentification : email + password (bcrypt cost >=12) ou OAuth Google / Apple via Firebase. Le backend emet un JWT access (60 min) et un refresh token rotatif (30 jours, store en sha256 dans `refresh_tokens`, detection de reuse). Cote mobile, `ApiClient` Dio intercepte les 401, declenche un refresh atomique via `_isRefreshing` flag, rejoue la requete originale.

## Plans utilisateurs

Trois plans definis dans `api/src/config/plans.py` :

| Plan | Generations IA / mois | Viewers / trip | Post-voyage IA | Acces admin |
|------|----------------------:|---------------:|:--------------:|:-----------:|
| FREE | limite (quota IA) | 2 | Non | Non |
| PREMIUM | illimite | 10 | Oui | Non |
| ADMIN | illimite | illimite | Oui | Oui (`/admin`) |

L'abonnement PREMIUM est gere via Stripe (subscription + webhook signe). Les viewers / editors d'un trip sont invites par email, mode read-only enforced cote backend par les dependencies `TripAccess`.

## Liens

- [c4-context.md](c4-context.md) -- C4 niveau 1 : acteurs, perimetre systeme, integrations externes.
- [c4-containers.md](c4-containers.md) -- C4 niveau 2 : zoom dans le VPS, stacks prod / preprod / observability, trust boundaries.
- [../database/](../database/) -- Modele de donnees PostgreSQL, ERD, migrations Alembic.
- [../infrastructure/](../infrastructure/) -- Provisionnement VPS, Ansible, edge Caddy, backups Restic.
- [../security/threat-model.md](../security/threat-model.md) -- Trust boundaries et risques associes.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| C4 niveau 3 (components) | Pas de diagramme par container (FastAPI modules, BLoCs Flutter, modules admin). Les niveaux 1-2 existent mais l'eclatement par composant logique reste a documenter. | P1 |
| Diagramme de sequence SSE | Le flux plan-trip-stream est decrit en texte mais aucun diagramme de sequence formel ne montre les events SSE node-par-node avec gestion d'erreur / repair JSON / budget exhausted. | P1 |
| ADR architecture mobile | Pas d'ADR retraant le choix BLoC + Repository + `Result<T>` vs alternatives (Riverpod, Provider, Cubit-only). Les conventions sont dans `CLAUDE.md` mais pas justifiees historiquement. | P2 |
| Catalogue d'integrations | Pas de fiche dediee par integration (Amadeus / Stripe / OVH GPT-OSS / AirLabs / FCM / Unsplash / Open-Meteo) avec quotas, TTL cache, fallback, contact support. | P2 |
| Schema admin-panel | L'admin est documente high-level mais pas en C4-component : pas de detail des routes admin consommees, de la matrice features / endpoints, des role-aware redactions. | P2 |
| Runbook agent IA | Pas de runbook dedie pour les pannes LLM (OVH GPT-OSS down, repair JSON loop infini, budget exhausted en cascade). | P2 |
