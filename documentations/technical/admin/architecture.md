# Architecture technique -- Admin Panel (Next.js)

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le back-office BagTrip est une application Next.js 16 (App Router) reservee aux comptes
au role `ADMIN`. Il consomme exclusivement l'API FastAPI sur le prefixe `/admin/*` (plus
quelques endpoints `/v1/*` pour l'auth et le flow de booking de test) et sert d'outil
operateur pour superviser les utilisateurs, les voyages, les paiements Stripe, les
recherches/reservations Amadeus, les feedbacks et les notifications push.

Le panel est volontairement **client-rendered** : pratiquement toutes les pages sous
`/app/*` sont marquees `'use client'` et chargent leurs donnees via TanStack Query +
Axios. Les Server Components Next.js ne portent que le layout racine et les wrappers de
shell. Aucun Server Action n'est expose -- choix explicite post-incident 2026-04-26 ou
une RCE Server Actions a touche le panel pre-prod.

## Stack

| Couche               | Techno                                            | Version  |
| -------------------- | ------------------------------------------------- | -------- |
| Framework            | Next.js (App Router, Turbopack)                   | 16.2.4   |
| React                | React + ReactDOM                                  | 19.1.0   |
| Langage              | TypeScript (strict, `noUnusedLocals`)             | 5.9.3    |
| State serveur        | TanStack React Query + Devtools                   | 5.85+    |
| State client         | Zustand (persisted)                               | 5.0+     |
| Tables               | TanStack React Table                              | 8.21+    |
| Forms                | React Hook Form + Zod                             | 7.72 / 4 |
| HTTP                 | Axios (`withCredentials`)                         | 1.11+    |
| UI primitives        | Radix UI + shadcn pattern                         | --       |
| Styling              | TailwindCSS                                       | 4.x      |
| Charts               | Recharts                                          | 3.8+     |
| Theme                | next-themes (light / dark / system)               | 0.4+     |
| Toasts               | Sonner                                            | 2.0+     |
| Paiements (page dev) | Stripe.js                                         | 8.6+     |
| Metriques runtime    | prom-client (route `/api/metrics`)                | 15.1+    |
| Tests unit / DOM     | Vitest + Testing Library + jsdom                  | 4.1+     |
| Tests E2E            | Cypress + `@cypress/code-coverage`                | 15.x     |
| Lint / format        | ESLint flat (`next/core-web-vitals`) + Prettier 3 | 9 / 3.6  |

Build : `output: 'standalone'` (Docker image minimale, Node 20 Alpine, port 8000).

## Architecture App Router

L'arborescence sous `src/app/` repose sur deux groupes :

- `(auth)/` : pages publiques (login + error boundary auth).
- `app/` : zone protegee, montee derriere `AuthGuard` + `AppShell` (sidebar + topbar +
  command palette `Cmd+K`).

| Route                          | Type       | Role                                                                       |
| ------------------------------ | ---------- | -------------------------------------------------------------------------- |
| `/`                            | Public     | Landing marketing (CTA login)                                              |
| `/login`                       | Public     | Formulaire credentials (Zod + RHF), redirige `/app` si deja loggue         |
| `/app`                         | Protegee   | Overview : KPIs, charts users/revenus/feedbacks/trips, recent activity     |
| `/app/users`                   | Protegee   | Liste utilisateurs paginee + filtres                                       |
| `/app/users/[id]`              | Protegee   | Detail user (plan, ban, reset quota IA, suppression)                       |
| `/app/trips`                   | Protegee   | Liste voyages (statut, dates, budget, IATA)                                |
| `/app/trips/[id]`              | Protegee   | Detail trip avec sous-entites (activities, accommodations, baggage, etc.)  |
| `/app/booking-intents`         | Protegee   | Intentions de paiement Stripe (autoriser, capturer, refund)                |
| `/app/flight-bookings`         | Protegee   | Reservations vols Amadeus confirmees                                       |
| `/app/flight-searches`         | Protegee   | Recherches de vols loggees                                                 |
| `/app/activities`              | Protegee   | Toutes les activites cross-trips                                           |
| `/app/accommodations`          | Protegee   | Hebergements                                                               |
| `/app/baggage`                 | Protegee   | Items bagages                                                              |
| `/app/budget`                  | Protegee   | Items budget                                                               |
| `/app/trip-shares`             | Protegee   | Partages de voyage (roles viewer / editor)                                 |
| `/app/travelers`               | Protegee   | Voyageurs (passagers Amadeus)                                              |
| `/app/traveler-profiles`       | Protegee   | Profils de preferences (style, budget, contraintes)                        |
| `/app/feedbacks`               | Protegee   | Retours post-trip                                                          |
| `/app/notifications`           | Protegee   | Liste + envoi (broadcast ou ciblage)                                       |
| `/app/audit-log`               | Protegee   | Journal d'audit (entity, action, acteur, payload)                          |
| `/app/settings`                | Protegee   | Profil admin, theme, logout                                                |
| `/app/dev/booking-flow`        | Protegee   | Outil dev : flow complet trip + Amadeus + Stripe en mode test              |
| `/api/metrics`                 | API route  | Endpoint Prometheus (prom-client)                                          |
| `/dashboard/*`                 | Redirect   | Legacy 308 vers `/app/*` (middleware)                                      |

Chaque sous-route porte ses propres `error.tsx` / `loading.tsx` (boundary + skeleton).

## Authentification

Le contrat d'auth est entierement porte cote API (JWT acces + refresh, cookies httpOnly).
Le panel se contente d'observer la presence d'un cookie d'acces et de garder le shell
client en phase avec le role.

### Cookies

- `<prefix>access_token` (httpOnly) : pose par l'API au login. Sert au middleware Next.
- `<prefix>auth-status=authenticated` (lisible JS) : utilise par `useAuth` pour decider
  s'il doit appeler `/v1/auth/me` (evite un GET 401 a froid).

Le prefixe vient de `NEXT_PUBLIC_COOKIE_NAME_PREFIX` (vide en local, namespace par env
en preprod / prod).

### Middleware (`src/middleware.ts`)

- Matche tout sauf `api`, statiques Next, favicon, PNG.
- Routes publiques : `/`, `/login`. `/login` + cookie acces => redirige `/app`.
- Routes protegees : tout `/app/*`. Pas de cookie => redirige `/login`.
- Compat legacy : tout `/dashboard*` est redirige `308` vers `/app*`.

Le middleware ne valide pas le role (le JWT n'est pas decode en edge). La verification
ADMIN se fait cote client via `AuthGuard`, qui appelle `useAuth()` et logout immediat
si `user.plan !== 'ADMIN'`.

### Login flow

1. `/login` rend un formulaire RHF + resolver Zod (`lib/validations/auth.ts` : email
   valide, password min 6).
2. `useAuth().login()` appelle `authService.login()` -> `POST /v1/auth/login`. L'API
   pose les cookies access + refresh + auth-status.
3. Si `data.user.plan !== 'ADMIN'`, `useAuth` declenche un `authService.logout()`
   immediat et leve `NotAdminError` (revoque la session ouverte cote API).
4. Sinon, le user est mis en cache React Query (`['auth', 'currentUser']`) et le router
   pousse vers `/app`.
5. Le shell monte, `AuthGuard` verifie `isAdmin` une seconde fois sur le cache.

Logout : `authService.logout()` + `queryClient.clear()` + redirect `/login`.

## Services

Couche `src/services/` : axios + typings, **aucune logique metier**. Toute regle vit
dans l'API.

### `lib/axios.ts` (apiClient)

Instance Axios partagee :

- `baseURL` = `NEXT_PUBLIC_API_URL` (defaut `http://localhost:3000`).
- `withCredentials: true` -> envoie les cookies httpOnly sur chaque requete.
- Header `Content-Type: application/json`.
- Intercepteur reponse : sur `401`, redirect hard `window.location.href = '/login'`
  (force un reset complet du shell et du cache).

Pas de JWT dans un header `Authorization` : le token reste en cookie httpOnly. Le panel
ne lit jamais le token.

### `services/auth.ts`

`login(credentials)`, `getCurrentUser()`, `logout()`. Wrappe `/v1/auth/login`,
`/v1/auth/me`, `/v1/auth/logout`.

### `services/admin.ts`

Le service central. Consomme les endpoints `/admin/*` :

- Lectures paginees : `getAllTrips`, `getAllTravelers`, `getAllFlightBookings`,
  `getAllTravelerProfiles`, `getAllBookingIntents`, `getAllFlightSearches`,
  `getAllAccommodations`, `getAllBaggageItems`, `getAllActivities`,
  `getAllBudgetItems`, `getAllTripShares`, `getAllNotifications`.
- Users : `getUserDetail`, `updateUser`, `updateUserPlan`, `resetAiQuota`, `banUser`,
  `unbanUser`, `deleteUser`, `bulkChangePlan`, `bulkBan`.
- Trips : `getTripDetail`, `updateTrip`, `deleteTrip`, `archiveTrip` + CRUD des
  sous-entites (`createActivity`, `updateActivity`, `deleteActivity`,
  `createAccommodation`, `updateAccommodation`, `deleteAccommodation`,
  `deleteBudgetItem`, `deleteBaggageItem`, `deleteShare`).
- Bookings : `getBookingIntentDetail`, `forceBookingStatus`, `cancelBooking`,
  `markBookingRefunded`.
- Feedbacks : `deleteFeedback`.
- Notifications : `sendNotification({ user_ids, title, body, type, trip_id })`.
- Audit : `getAuditLogs(params)`.

Tous renvoient la donnee deja typee (`AdminListResponse<T>` pour les listes paginees).

### Autres services

`trips.ts`, `travelers.ts`, `flights.ts`, `booking-intents.ts`, `payments.ts`,
`feedbacks.ts`, `users.ts`, `dashboard.ts` : facade type-safe sur les autres endpoints
(notamment ceux consommes par la page dev `/app/dev/booking-flow`).

## React Query patterns

Configuration globale (`lib/query-client.ts`) :

- `staleTime: 5 min`, `gcTime: 10 min`.
- Queries : retry x3 sauf sur `401 / 403` (pas de boucle infinie).
- Mutations : pas de retry sur 4xx (les conflits / validation API restent visibles).
- `MutationCache.onError` global : pousse un toast Sonner avec `error.response.data.detail`
  ou un message generique. Tous les services peuvent donc lever sans gestion locale.

Patterns recurrents :

- **Listes paginees** : hook generique `shared/hooks/usePaginatedQuery.ts` qui combine
  state local de page + queryFn parametree. Chaque feature `features/<nom>/hooks.ts`
  l'instancie avec sa `queryKey` et son service.
- **Dashboard** : `features/dashboard/hooks.ts` expose `useDashboardMetrics`,
  `useUserRegistrationsChart(period)`, `useRevenueChart(period)`, `useFeedbacksChart`,
  `useTripStatusDistribution`, `useRecentActivity(limit)`. `refetchInterval` plus court
  sur les KPIs (live feel).
- **Mutations** : invalidation systematique de la query mere apres succes
  (`queryClient.invalidateQueries({ queryKey })`).
- **Cookie-guarded queries** : `useAuth` n'active `getCurrentUser` qu'avec
  `enabled: hasAuthCookie()` pour eviter un 401 au boot.

## Features

15 modules sous `src/features/<nom>/` (columns TanStack Table, hooks, composants tab).
La majorite des pages `/app/*` se contente d'importer le composant racine + ses hooks.

| #  | Feature             | Route                    | Donnees                                                        |
| -- | ------------------- | ------------------------ | -------------------------------------------------------------- |
| 1  | dashboard           | `/app`                   | KPIs (users, trips, revenus, rating), charts, activity feed    |
| 2  | users               | `/app/users[/:id]`       | Liste + detail + plan FREE/PREMIUM/ADMIN, ban, quota IA        |
| 3  | trips               | `/app/trips[/:id]`       | Trips + sous-entites groupees par voyage                       |
| 4  | activities          | `/app/activities`        | Activites cross-trips (titre, date, lieu, categorie, cout)     |
| 5  | accommodations      | `/app/accommodations`    | Hebergements (hotel, dates, prix/nuit, notes)                  |
| 6  | budget-items        | `/app/budget`            | Depenses (label, montant, categorie, is_planned)               |
| 7  | baggage-items       | `/app/baggage`           | Items bagages (nom, categorie, is_packed)                      |
| 8  | trip-shares         | `/app/trip-shares`       | Partages (viewer / editor, invitation, statut)                 |
| 9  | booking-intents     | `/app/booking-intents`   | Intentions Stripe (type, status, montant, PI id)               |
| 10 | flight-searches     | `/app/flight-searches`   | Recherches vols loggees (IATA, dates, classe)                  |
| 11 | flights             | `/app/flight-bookings`   | Reservations vols confirmees (offer, booking ref)              |
| 12 | travelers           | `/app/travelers`         | Voyageurs (nom, type, DOB, genre, passeport)                   |
| 13 | profiles            | `/app/traveler-profiles` | Profils preferences (style, budget, companions, completion)    |
| 14 | feedbacks           | `/app/feedbacks`         | Retours post-trip (rating, highlights, recommend)              |
| 15 | notifications       | `/app/notifications`     | Notifications + envoi broadcast / cible                        |

Auxiliaire :

- `audit-log` (page directe, pas de feature module) -> `/app/audit-log` consomme
  `adminService.getAuditLogs` avec filtres entity / action.
- `settings` -> `/app/settings` (profil, theme via `next-themes`, logout).
- `dev/booking-flow` -> `/app/dev/booking-flow` (outil dev pour rejouer trip + Amadeus
  + Stripe en mode test, exclu de la couverture).

## Hardening post-incident

L'incident 2026-04-26 (RCE Server Actions sur preprod) a fixe plusieurs principes
d'architecture qui s'appliquent encore aujourd'hui :

- **Pas de Server Actions exposees.** Recherche `'use server'` dans `src/` = 0 hit. Le
  panel n'expose aucun endpoint POST sans frontiere d'API explicite : tout passe par
  l'API FastAPI authentifiee.
- **Pas de mutation cote serveur Next.** Le layout racine est passif (fonts, Providers).
  Les mutations metiers (DELETE user, force booking status, send notification) partent
  toujours d'un handler client + `apiClient` + cookie httpOnly. Resultat : la surface
  d'attaque n'est pas le runtime Next, c'est l'API derriere son JWT + ses guards.
- **Validation Zod en entree de tout formulaire.** Le login utilise `loginSchema`
  (`lib/validations/auth.ts`) et l'edition user `UserEditSheet` un schema Zod local.
  Les payloads passes a `adminService` sont serializes apres validation -- pas de
  string brute reinjectee dans une `eval` ou un template.
- **Defense en profondeur sur l'admin.** Triple verrou :
  1. Middleware edge : presence du cookie acces sinon redirect.
  2. `AuthGuard` client : revoque la session si `plan !== 'ADMIN'`.
  3. API : tous les endpoints `/admin/*` derriere `require_admin` cote FastAPI.
- **Audit logging systematique.** Toute action mutative (`updateUser`, `banUser`,
  `deleteTrip`, `forceBookingStatus`, `sendNotification`, etc.) est tracee cote API
  dans la table `audit_logs`, consommee ensuite par `/app/audit-log` pour
  verification operateur. Aucune mutation ne contourne ce log.
- **Pas de cles secretes cote client.** Variables d'env du panel : seules les
  `NEXT_PUBLIC_*` (API URL, cookie prefix). Les secrets Stripe, JWT, OAuth restent
  exclusivement cote API.
- **Headers securite + standalone Docker.** Build `output: 'standalone'` deploye sur
  VPS derriere reverse-proxy avec HSTS / CSP / X-Frame-Options imposes au niveau
  reverse proxy.

## Tests

### Vitest (tests unitaires + DOM)

- Config `vitest.config.ts` : `jsdom`, alias `@/`, coverage v8 (text + lcov).
- Setup : `src/__tests__/setup.ts` (Testing Library + jest-dom matchers).
- Couverture :
  - Services : `services/*.test.ts` mocke `apiClient` (axios) et verifie le mapping
    endpoint + payload.
  - Hooks : `hooks/*.test.ts` (`useAuth`, `useUsers`, `useFeedbacks`, `useDashboard`,
    `useDateRange`, `useAdminData`).
  - Composants : layout (`AppShell`, `Sidebar`, `Topbar`, `AuthGuard`, `Breadcrumb`,
    `CommandPalette`, `ThemeToggle`), `DataTable`, `DataTableToolbar`, `ConfirmDialog`,
    `RowActions`.
  - Middleware : `middleware.test.ts` (cookies, redirects, legacy `/dashboard`).
  - Pages : `app/page.test.tsx`, `app/app/page.test.tsx`, `app/app/users/[id]/page.test.tsx`,
    `app/app/trips/[id]/page.test.tsx`, `app/app/audit-log/page.test.tsx`,
    `app/app/settings/page.test.tsx`.
- Exclus du coverage : primitives `components/ui/*` (shadcn generes), `error.tsx`,
  `loading.tsx`, `app/dev/**` (outil interne), types purs.

### Cypress (tests E2E)

- Suites sous `cypress/e2e/` : `homepage.cy.ts`, `auth-flow.cy.ts`,
  `dashboard-overview.cy.ts`, `dashboard-shell.cy.ts`, `dashboard-users-crud.cy.ts`.
- Code coverage via `@cypress/code-coverage`.
- Custom commands `cypress/support/commands.ts` : `loginAsAdmin`, `visitDashboard`.

Scripts :

```
npm run test           # vitest run
npm run test:coverage  # vitest run --coverage
npm run cypress:run    # E2E headless
npm run test:e2e       # start-server-and-test + cypress
npm run check-all      # type-check + lint + format:check
```

## Ce qu'il manque

- **Refresh token cote panel** : l'intercepteur axios redirige hard sur `401` au lieu
  d'appeler `/v1/auth/refresh`. Tant que l'API rotate l'access via le refresh cookie
  sur certains endpoints, ce n'est pas critique, mais une session courte expire en
  pleine navigation au lieu d'etre prolongee silencieusement.
- **RBAC plus fin** : un seul role `ADMIN` est verifie. Pas de distinction
  `SUPER_ADMIN` / `ADMIN` cote panel, alors que `utils/constants.ts` le declare.
- **Pagination configurable** : `PAGINATION_DEFAULTS.LIMIT = 10` en dur, pas de
  selecteur de page size dans `DataTableToolbar`.
- **Export CSV** : seul `usersService.exportUsers` existe cote service, aucun bouton
  expose dans l'UI.
- **i18n** : tout est en francais en dur, pas de `next-intl` ni d'ARB.
- **Observabilite client** : pas de Sentry, pas de RUM. Les seuls signaux runtime sont
  les metriques Prometheus (`/api/metrics`) et les toasts Sonner.
- **Tests E2E mutations destructives** : les flows DELETE user / cancelBooking /
  forceBookingStatus n'ont pas encore de couverture Cypress dediee.
- **CSP / security headers in-app** : delegue au reverse proxy VPS. Pas de
  `headers()` configuree dans `next.config.ts` -- a rapatrier pour avoir un fallback
  applicatif.
