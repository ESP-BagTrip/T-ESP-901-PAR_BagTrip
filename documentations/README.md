# Documentation BagTrip

> Index global de la documentation du projet BagTrip -- monorepo Flutter (mobile) + FastAPI (backend) + Next.js (admin panel).

---

## Architecture

| Document | Description |
|----------|-------------|
| [Vue d'ensemble](./architecture/overview.md) | Vue d'ensemble monorepo, stack, flux global |
| [Infrastructure](./architecture/infrastructure.md) | Docker, compose, Makefile, deploiement |
| [Base de donnees](./architecture/database.md) | Schema BDD, migrations Alembic, models |

---

## CI/CD

| Document | Description |
|----------|-------------|
| [CI/CD](./ci-cd.md) | Workflows GitHub Actions, pre-commit, quality gates |

---

## Documentation fonctionnelle

| Document | Description |
|----------|-------------|
| [Authentification](./functional/authentication.md) | OAuth, JWT, onboarding |
| [Profil et personnalisation](./functional/profile-personalization.md) | Profil voyageur, preferences |
| [Paiements](./functional/payments.md) | Stripe, abonnements |
| [Creation de voyage](./functional/trip-creation.md) | Wizard multi-etapes, creation voyage |
| [Planification IA](./functional/ai-planning.md) | Agent IA LangGraph, SSE, suggestions |
| [Home](./functional/home.md) | Etats home, transitions contextuelles |
| [Detail voyage](./functional/trip-detail.md) | Page detail, completion, sections, roles |
| [Activites](./functional/activities.md) | CRUD activites, validation, suggestions IA |
| [Mode en voyage](./functional/in-trip-mode.md) | Detection auto, timeline, now indicator |
| [Post-voyage](./functional/post-trip.md) | Souvenirs, feedback, transition |
| [Notifications](./functional/notifications.md) | Push FCM, scheduling local, deep links |
| [Vols et transports](./functional/flights-transports.md) | Recherche vols, IATA, boarding-pass |
| [Hebergements](./functional/accommodations.md) | Hebergements, recherche hotels |
| [Bagages](./functional/baggage.md) | Checklist IA, categories |
| [Budget](./functional/budget.md) | Depenses, breakdown, estimation IA |
| [Partage](./functional/sharing.md) | Invitation, permissions, revoke |

---

## Documentation technique -- Mobile (Flutter)

| Document | Description |
|----------|-------------|
| [Architecture](./technical/mobile/architecture.md) | BLoC + Repository + Result, DI, layering |
| [Design system](./technical/mobile/design-system.md) | Tokens, composants adaptatifs, animations |
| [Navigation](./technical/mobile/navigation.md) | GoRouter, shell branches, deep links |
| [Cache et offline](./technical/mobile/cache-offline.md) | Cache Hive, connectivity, offline |
| [Internationalisation](./technical/mobile/i18n.md) | Internationalisation EN/FR |
| [Accessibilite](./technical/mobile/accessibility.md) | VoiceOver, WCAG AA, Dynamic Type |
| [Dark mode](./technical/mobile/dark-mode.md) | Implementation dark mode |
| [Tests](./technical/mobile/testing.md) | Strategies de test, coverage, golden tests |

---

## Documentation technique -- API (FastAPI)

| Document | Description |
|----------|-------------|
| [Architecture](./technical/api/architecture.md) | FastAPI, middleware, error handling |
| [Endpoints](./technical/api/endpoints.md) | Reference complete des routes |
| [Agent IA](./technical/api/ai-agent.md) | LangGraph, nodes, ReAct, SSE |
| [Integrations](./technical/api/integrations.md) | Amadeus, AirLabs, Unsplash, Firebase, Stripe |
| [Jobs](./technical/api/jobs.md) | Background jobs, scheduling |
| [Auth](./technical/api/auth.md) | OAuth, JWT, guards, middleware |

---

## Documentation technique -- Admin Panel (Next.js)

| Document | Description |
|----------|-------------|
| [Architecture](./technical/admin/architecture.md) | Next.js, features, stack, tests |

---

## Ce qu'il manque

Les documentations suivantes n'existent pas encore et pourraient etre ajoutees :

### Fonctionnel

- **Gestion des roles et permissions** -- Documentation detaillee des roles (owner, editor, viewer) et de leur impact sur chaque fonctionnalite
- **Recherche et decouverte** -- Fonctionnalites de recherche de destinations, recommandations, explore
- **Carte et geolocalisation** -- Visualisation cartographique des activites et itineraires
- **Photos et medias** -- Gestion des photos de voyage, galerie, partage

### Technique mobile

- **Performance et optimisation** -- Strategies de performance, lazy loading, optimisation images
- **Push notifications (implementation)** -- Configuration FCM, gestion des tokens, handlers
- **Animations et micro-interactions** -- Catalogue des animations, springs, transitions

### Technique API

- **Securite** -- Rate limiting, CORS, sanitization, audit
- **Monitoring et observabilite** -- Logging, metriques, alerting
- **Base de donnees (operations)** -- Indexation, requetes complexes, performances

### Technique admin

- **Tests E2E complets** -- Documentation des scenarios de test au-dela de la homepage
- **Deploiement admin** -- Procedure de deploiement specifique au panel admin

### Transverse

- **Guide de contribution** -- Standards de code, workflow PR, conventions de commit
- **Glossaire** -- Definitions des termes metier (trip, traveler, booking intent, etc.)
- **Changelog** -- Historique des versions et fonctionnalites par sprint
