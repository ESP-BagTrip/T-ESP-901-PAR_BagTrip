# Architecture technique -- Admin Panel (Next.js)

> Panel d'administration BagTrip. Application Next.js 15 (App Router) permettant la supervision de l'ensemble des donnees de la plateforme : utilisateurs, voyages, reservations, paiements, feedbacks, notifications.

---

## Stack technique

| Couche | Technologie | Version |
|--------|------------|---------|
| Framework | Next.js (App Router, Turbopack) | 15.5.0 |
| Langage | TypeScript | 5.9.3 |
| UI | TailwindCSS | 4.x |
| Composants UI | Radix UI (Tabs, Slot) + shadcn/ui pattern | -- |
| State management (serveur) | TanStack React Query | 5.85+ |
| State management (client) | Zustand (persisted) | 5.0+ |
| Tableaux de donnees | TanStack React Table | 8.21+ |
| Formulaires | React Hook Form + Zod | 7.62+ / 4.3+ |
| HTTP client | Axios | 1.11+ |
| Charts | Recharts | 3.1+ |
| Notifications toast | Sonner | 2.0+ |
| Paiements | Stripe.js | 8.6+ |
| Icones | Lucide React | 0.542+ |
| Tests E2E | Cypress + code-coverage | 15.x |
| Linting | ESLint (next/core-web-vitals + next/typescript) | 9.x |
| Formatage | Prettier | 3.6+ |
| Docker | Node 20 Alpine | -- |

---

## Structure du projet

```
admin-panel/
├── src/
│   ├── app/                        # Next.js App Router
│   │   ├── layout.tsx              # Root layout (Providers, fonts)
│   │   ├── page.tsx                # Landing page publique
│   │   ├── error.tsx               # Global error boundary
│   │   ├── (auth)/
│   │   │   ├── login/page.tsx      # Login / Register
│   │   │   └── error.tsx           # Auth error boundary
│   │   └── (dashboard)/
│   │       ├── dashboard/page.tsx  # Dashboard principal (tabs)
│   │       ├── test/page.tsx       # Page de test booking flow (Stripe)
│   │       └── error.tsx           # Dashboard error boundary
│   ├── features/                   # Feature modules (lazy-loaded)
│   │   ├── registry.ts            # Tab registry central
│   │   ├── dashboard/             # KPIs + charts
│   │   ├── users/                 # Gestion utilisateurs
│   │   ├── trips/                 # Voyages
│   │   ├── profiles/              # Profils voyageurs
│   │   ├── travelers/             # Voyageurs (par trip)
│   │   ├── flights/               # Reservations vols
│   │   ├── flight-searches/       # Recherches vols
│   │   ├── booking-intents/       # Intentions de reservation
│   │   ├── accommodations/        # Hebergements
│   │   ├── baggage-items/         # Articles bagages
│   │   ├── activities/            # Activites
│   │   ├── budget-items/          # Depenses budget
│   │   ├── trip-shares/           # Partages voyage
│   │   ├── feedbacks/             # Retours utilisateurs
│   │   └── notifications/         # Notifications (+ envoi)
│   ├── services/                  # API service layer
│   ├── hooks/                     # Hooks globaux (auth, users, dashboard, admin data)
│   ├── stores/                    # Zustand stores
│   ├── types/                     # TypeScript types
│   ├── components/                # Composants partages
│   │   ├── ui/                    # Primitives UI (shadcn pattern)
│   │   ├── providers/             # React Query + Toaster providers
│   │   └── DataTable.tsx          # Table generique paginee
│   ├── shared/                    # Composants/hooks partages entre features
│   │   ├── components/            # TabSkeleton, TabErrorBoundary
│   │   └── hooks/                 # usePaginatedQuery
│   ├── lib/                       # Utilitaires core
│   │   ├── axios.ts               # Client HTTP configure
│   │   ├── query-client.ts        # React Query client
│   │   ├── utils.ts               # cn() helper (clsx + tailwind-merge)
│   │   └── validations/           # Schemas Zod
│   └── utils/                     # Utilitaires metier
│       ├── constants.ts           # Endpoints API, pagination, formats date
│       ├── format.ts              # Formatage dates, devises, nombres
│       ├── date.ts                # safeFormatDate (date-fns)
│       └── validation.ts          # Validation email, password, required
├── cypress/                       # Tests E2E
│   ├── e2e/homepage.cy.ts        # Tests homepage (nav, hero, stats, features, responsive, a11y)
│   └── support/commands.ts       # Custom commands (loginAsAdmin, visitDashboard)
├── cypress.config.ts              # Config Cypress (E2E + component + code-coverage)
├── Dockerfile.dev                 # Docker Node 20 Alpine
├── Makefile                       # Commandes make
├── tailwind.config.ts             # Theme custom (primary, success, warning, danger)
├── eslint.config.mjs              # ESLint flat config
└── package.json
```

---

## Architecture applicative

### Route groups (App Router)

L'application utilise les route groups Next.js pour separer les contextes :

- **`(auth)/`** -- Pages publiques d'authentification (login/register)
- **`(dashboard)/`** -- Pages protegees (dashboard, test booking flow)

Chaque groupe dispose de son propre `error.tsx` (error boundary).

### Feature modules et Tab Registry

Le dashboard est construit sur un systeme d'onglets dynamiques. Le fichier `features/registry.ts` centralise la configuration :

```typescript
export const TAB_REGISTRY: TabConfig[] = [
  { id: 'dashboard', name: 'Dashboard', component: lazy(() => import('./dashboard/...')) },
  { id: 'users',     name: 'Utilisateurs', component: lazy(() => import('./users/...')) },
  // ... 15 onglets au total
]
```

Chaque feature module suit la meme structure :

```
features/<nom>/
├── columns.tsx        # Definition des colonnes TanStack Table
├── hooks.ts           # Hook usePaginatedQuery specifique
└── components/
    └── <Nom>Tab.tsx   # Composant tab (DataTable + pagination)
```

Les tabs sont chargees en **lazy loading** (`React.lazy`) avec `Suspense` (fallback `TabSkeleton`) et encapsulees dans `TabErrorBoundary`.

### Les 15 onglets du dashboard

| Onglet | Feature | Donnees affichees |
|--------|---------|-------------------|
| Dashboard | `dashboard` | KPIs (users, trips, revenus, feedbacks) + charts Recharts |
| Utilisateurs | `users` | CRUD users avec modification du plan (FREE/PREMIUM/ADMIN) |
| Trips | `trips` | Liste voyages (titre, IATA, dates, statut, budget) |
| Profils Voyageurs | `profiles` | Profils (style, budget, companions, completion) |
| Voyageurs | `travelers` | Voyageurs par trip (nom, type, DOB, genre) |
| Booking Intents | `booking-intents` | Intentions (type, statut, montant, Stripe PI ID) |
| Res. Vols | `flights` | Reservations vols (offre, statut, booking ref) |
| Rech. Vols | `flight-searches` | Recherches (IATA, dates, classe, nb passagers) |
| Hebergements | `accommodations` | Hotels (nom, adresse, dates, prix/nuit) |
| Bagages | `baggage-items` | Articles (nom, categorie, quantite, is_packed) |
| Activites | `activities` | Activites (titre, date, horaires, lieu, categorie, cout) |
| Budget Items | `budget-items` | Depenses (label, montant, categorie, is_planned) |
| Partages | `trip-shares` | Partages (user, trip, role, date invitation) |
| Feedbacks | `feedbacks` | Retours (note, highlights/lowlights, recommend) |
| Notifications | `notifications` | Notifications (type, titre, body, lu/non-lu) + envoi |

---

## State management

### TanStack React Query (etat serveur)

Toutes les donnees API transitent par React Query :

- **Query client global** (`lib/query-client.ts`) : `staleTime: 5min`, `gcTime: 10min`, retry intelligent (pas de retry sur 401/403), toast automatique sur erreur de mutation
- **Hooks globaux** (`hooks/`) : `useAuth`, `useUsers`, `useFeedbacks`, `useDashboard`, `useAdminData`
- **Hooks feature** (`features/<nom>/hooks.ts`) : utilisent `usePaginatedQuery` du shared
- **Hook partage** (`shared/hooks/usePaginatedQuery.ts`) : abstraction pagination (page state + queryFn parametree)

### Zustand (etat client)

Deux stores :

- **`useDashboardStore`** -- Onglet actif du dashboard (`activeTab`)
- **`useUIStore`** (persiste via `zustand/persist`) -- Sidebar ouverte/fermee, theme light/dark

---

## Couche services (API)

Le client HTTP (`lib/axios.ts`) est un Axios instance avec :

- `baseURL` configurable via `NEXT_PUBLIC_API_URL`
- `withCredentials: true` (cookies JWT)
- Intercepteur 401 : redirection automatique vers `/login`

### Services disponibles

| Service | Fichier | Responsabilite |
|---------|---------|----------------|
| `authService` | `services/auth.ts` | Login, register, getCurrentUser, logout |
| `usersService` | `services/users.ts` | CRUD users, toggle status, export CSV |
| `dashboardService` | `services/dashboard.ts` | Metriques, activity logs, charts |
| `adminService` | `services/admin.ts` | 12 endpoints admin (trips, travelers, flights, accommodations, baggage, activities, budget, trip-shares, notifications...), update plan, send notification |
| `tripsService` | `services/trips.ts` | CRUD trips |
| `travelersService` | `services/travelers.ts` | CRUD travelers par trip |
| `flightsService` | `services/flights.ts` | Recherche vols, detail/pricing offres |
| `bookingIntentsService` | `services/booking-intents.ts` | CRUD booking intents, book flight/hotel |
| `paymentsService` | `services/payments.ts` | Authorize, capture, cancel, confirm-test |
| `feedbacksService` | `services/feedbacks.ts` | Liste feedbacks, suppression |

### Endpoints API consommes

Les endpoints sont centralises dans `utils/constants.ts` :

- **Auth** : `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/me`, `/v1/auth/logout`
- **Admin** : `/admin/trips`, `/admin/travelers`, `/admin/flight-bookings`, `/admin/traveler-profiles`, `/admin/booking-intents`, `/admin/flight-searches`, `/admin/accommodations`, `/admin/baggage-items`, `/admin/activities`, `/admin/budget-items`, `/admin/trip-shares`, `/admin/feedbacks`, `/admin/notifications`, `/admin/notifications/send`, `/admin/users`, `/admin/dashboard/metrics`, `/admin/dashboard/activity`
- **V1** : `/v1/trips`, `/v1/trips/:id/travelers`, `/v1/trips/:id/flights/searches`, `/v1/trips/:id/booking-intents`, `/v1/booking-intents/:id`, `/v1/booking-intents/:id/book`, `/v1/booking-intents/:id/payment/*`

---

## Composants partages

### DataTable

Composant generique (`components/DataTable.tsx`) base sur TanStack React Table :

- Colonnes typees via `ColumnDef<T>`
- Tri (sorting) cote client
- Pagination serveur-side ou client-side
- Skeleton loading
- Etat vide "Aucune donnee disponible"

### Primitives UI (shadcn pattern)

`components/ui/` contient les primitives stylisees avec `class-variance-authority` + `cn()` :

- `Button` (variantes : default, destructive, outline, ghost, link ; tailles : default, sm, lg, icon)
- `Input`, `Card` (CardHeader, CardTitle, CardContent), `Badge`, `Table`, `Tabs`, `Skeleton`

### Providers

- **`Providers`** -- Compose `QueryProvider` + `Toaster` (Sonner, position top-right)
- **`QueryProvider`** -- `QueryClientProvider` + `ReactQueryDevtools` (dev only)

### Shared

- **`TabSkeleton`** -- Placeholder skeleton pour le lazy loading des tabs
- **`TabErrorBoundary`** -- Error boundary class component avec bouton "Reessayer"

---

## Authentification et middleware

### Middleware Next.js (`middleware.ts`)

Protection des routes cote serveur (edge runtime) :

- **Routes publiques** : `/`, `/login`
- **Routes protegees** : `/dashboard`, `/test`, `/users`, `/feedbacks`
- Verification du cookie `access_token`
- Redirection vers `/login` si non authentifie
- Redirection vers `/dashboard` si deja authentifie (depuis `/login`)

### Hook `useAuth`

Gestion complete de l'authentification cote client :

- `getCurrentUser` via React Query (active uniquement si cookie `auth-status=authenticated` present)
- Mutations `login` / `register` avec redirection automatique vers `/dashboard`
- `logout` : appel API + `queryClient.clear()` + redirection `/login`
- Expose : `user`, `isAuthenticated`, `isLoading`, `login`, `register`, `logout`, etats de mutation

### Validation formulaires

Schemas Zod (`lib/validations/auth.ts`) :

- **Login** : email (requis, format valide), password (requis, min 6 caracteres)
- **Register** : login + fullName (optionnel) + phone (optionnel)

---

## Validation et formatage

### Validation (`utils/validation.ts`)

Fonctions utilitaires : `validateEmail`, `validatePassword` (8+ chars, majuscule, minuscule, chiffre, special), `validateRequired`, `validateMinLength`, `validateMaxLength`.

### Formatage (`utils/format.ts` et `utils/date.ts`)

- `formatDate`, `formatDateTime`, `formatRelativeTime` (date-fns, locale fr)
- `formatCurrency` (Intl.NumberFormat EUR), `formatNumber`, `formatPercentage`
- `truncateText`
- `safeFormatDate` -- fallback vers "---" si date invalide

---

## Dashboard et visualisation

Le `DashboardTab` affiche :

- **7 cartes KPI** : Utilisateurs, Actifs/Inactifs, Trips, Revenus, Feedbacks, Note moyenne, Feedbacks en attente
- **3 graphiques Recharts** :
  - LineChart inscriptions utilisateurs (par semaine/mois/annee)
  - BarChart revenus (par semaine/mois/annee)
  - BarChart distribution feedbacks (pleine largeur)

Les donnees sont rafraichies toutes les 5 minutes (`refetchInterval`).

---

## Page de test booking flow

La page `/test` (`(dashboard)/test/page.tsx`) fournit une interface de test manuelle pour le flux complet de reservation :

1. **Authentification** -- Affiche l'utilisateur connecte
2. **Creation trip** -- Paris vers Rome (hardcode)
3. **Ajout traveler** -- John Doe avec passeport
4. **Recherche vols** -- Via Amadeus
5. **Selection offre** -- Clic sur une offre
6. **Booking intent** -- Creation d'intention de reservation
7. **Autorisation paiement** -- Stripe PaymentIntent
8. **Confirmation paiement** -- Mode test (confirm-test)
9. **Reservation vol** -- Book flight
10. **Capture paiement** -- Finalisation

Integre Stripe.js pour la gestion des paiements en mode test.

---

## Notifications admin

La feature notifications inclut un composant specifique `SendNotificationModal` permettant aux administrateurs :

- D'envoyer une notification a tous les utilisateurs (broadcast)
- De selectionner des utilisateurs specifiques via checkbox
- De definir titre et corps du message
- Type automatique : `ADMIN`

---

## Tests

### Cypress E2E

- **Config** : viewport 1280x720, video activee, screenshots on failure, code-coverage
- **Tests homepage** (`cypress/e2e/homepage.cy.ts`) : 14 tests couvrant navigation, hero, stats, features (tab switch), CTA, footer, responsive (mobile/tablet), accessibilite (heading hierarchy, liens accessibles), performance (load < 8s), SEO
- **Custom commands** : `loginAsAdmin` (POST API), `visitDashboard` (login + navigate)
- **Support** : E2E et component testing configures

### Quality scripts

```bash
npm run type-check     # tsc --noEmit
npm run lint           # next lint
npm run format:check   # prettier --check
npm run check-all      # type-check + lint + format:check
```

---

## Types TypeScript

### Types auth et API

- `User` (id, email, plan FREE/PREMIUM/ADMIN, created_at, updated_at)
- `LoginCredentials`, `RegisterCredentials`, `AuthResponse`, `AuthState`
- `ApiResponse<T>`, `PaginatedResponse<T>`, `ApiError`, `QueryParams`

### Types admin (15 interfaces)

Chaque entite admin dispose de son interface : `AdminTrip`, `AdminTraveler`, `AdminFlightBooking`, `AdminTravelerProfile`, `AdminBookingIntent`, `AdminFlightSearch`, `AdminAccommodation`, `AdminBaggageItem`, `AdminActivity`, `AdminBudgetItem`, `AdminTripShare`, `AdminNotification`. Response generique `AdminListResponse<T>` avec pagination.

### Types booking

`Trip`, `Traveler`, `FlightOfferSummary`, `FlightSearchResponse`, `FlightOfferDetail`, `BookingIntent`, `PaymentAuthorizeResponse`, `PaymentCaptureResponse` et leurs variantes request/response.

### Types dashboard

`DashboardMetrics`, `ChartData`, `ActivityLog`.

### Types feedback

`Feedback` (trip, user, rating, highlights, lowlights, would_recommend).

---

## Configuration et deploiement

### Tailwind

Theme custom avec palette semantique (primary blue, success green, warning amber, danger red), font Inter, animations `fade-in` et `slide-up`, box-shadows `card` et `card-hover`.

### Docker

Image `node:20-alpine`, port 8000, commande `npm run dev`.

### ESLint

Flat config (v9) : `next/core-web-vitals` + `next/typescript`, ignores standards (node_modules, .next, out, build).

---

## Ce qu'il manque

- **Tests unitaires** : aucun test Jest/Vitest pour les hooks, services ou composants. Seuls des tests E2E Cypress existent.
- **Tests E2E dashboard** : les tests Cypress ne couvrent que la homepage. Il manque des tests pour le flux d'authentification, le dashboard, les onglets admin, et le booking flow.
- **Internationalisation (i18n)** : tous les textes sont en dur en francais, pas de systeme d'internationalisation.
- **Gestion des roles** : le middleware verifie uniquement la presence du cookie, sans verifier le role (admin vs user). Pas de RBAC cote frontend.
- **Dark mode** : le store `useUIStore` supporte un theme light/dark, mais il n'est utilise nulle part dans l'UI.
- **Sidebar** : le store `useUIStore` gere l'etat de la sidebar, mais aucune sidebar n'est implementee (navigation par tabs uniquement).
- **Recherche et filtres** : le type `QueryParams` supporte `search`, `sortBy`, `sortOrder`, mais ces parametres ne sont pas exposes dans l'UI des DataTable.
- **Export CSV** : le service `usersService.exportUsers` existe mais n'est pas accessible depuis l'UI.
- **Pagination par taille** : la taille de page est fixee a 10 (`PAGINATION_DEFAULTS.LIMIT`), sans possibilite pour l'utilisateur de la modifier.
- **Tests de securite** : pas de tests pour les redirections middleware, la gestion des tokens expires, ou les erreurs 403.
- **Monitoring/observabilite** : pas de Sentry, pas de logging structure, pas de metriques de performance.
- **Documentation API admin** : les endpoints `/admin/*` consommes par le panel ne sont pas documentes cote API (Swagger/OpenAPI).
