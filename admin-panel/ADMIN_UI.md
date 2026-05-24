# Admin UI — BagTrip

Guide rapide pour travailler sur la console admin (`admin-panel/`). Architecture et conventions issues de la refonte SMP-301.

## Vue d'ensemble

- **Next.js 15 App Router** + React 19 + TypeScript strict.
- **Tailwind CSS v4** avec tokens en `@theme`.
- **shadcn/ui** (style new-york) copié localement dans `src/components/ui/`.
- **TanStack Query v5** pour la data, **Zustand** pour `sidebarCollapsed`, **URL** pour la pagination et le date range.
- **next-themes** pour light/dark/system sans flash.
- **Cypress** E2E + **Vitest** unit pour les utils purs.

## Structure

```
src/
  app/
    layout.tsx                     # ThemeProvider + Providers + Geist
    globals.css                    # @import 'tailwindcss' + tokens.css
    page.tsx                       # Landing publique (inchangée)
    (auth)/login/page.tsx          # Login admin
    app/                           # Console admin (protégée)
      layout.tsx                   # AuthGuard + AppShell
      page.tsx                     # Overview (vitrine Ive)
      <entity>/page.tsx            # 14 routes liste (users, trips, …)
      settings/page.tsx
      dev/booking-flow/page.tsx    # QA tool (dev only)
  components/
    ui/                            # Primitives shadcn + customs (KPICard, Sparkline, kbd, empty-state, date-range-picker)
    layout/                        # Sidebar, Topbar, Breadcrumb, CommandPalette, ThemeToggle, UserPill, PageHeader, ActivityFeed, AuthGuard, AppShell
    charts/                        # AreaChartCard, BarChartCard, DonutChartCard, DistributionChartCard
    providers/                     # ThemeProvider, QueryProvider, Providers
    DataTable.tsx                  # TanStack Table générique + pagination URL-sync
  config/
    navigation.ts                  # NAV_SECTIONS — source unique consommée par Sidebar, Breadcrumb, CommandPalette
  features/<entity>/
    columns.tsx                    # Colonnes TanStack Table
    hooks.ts                       # useXTab() → usePaginatedQuery
  hooks/                           # useAuth, useDateRange
  shared/hooks/usePaginatedQuery.ts# URL-synced pagination, normalise PaginatedResponse + AdminListResponse
  stores/useUIStore.ts             # sidebarCollapsed (persist)
  styles/tokens.css                # @theme + @layer base (light/dark)
  utils/                           # delta, format, group-by (+ tests .test.ts)
  middleware.ts                    # /app protected + /dashboard→/app 308
```

## Design tokens

Tous les tokens vivent dans `src/styles/tokens.css` :

- **Palette neutre** : `--color-gray-0` … `--color-gray-950` (11 shades).
- **Accent** : `--primary` (blue-600 en light, blue-500 en dark).
- **Statuts** : `--success` / `--warning` / `--destructive` / `--info`.
- **Surfaces sémantiques** : `--background`, `--foreground`, `--card`, `--muted`, `--border`, `--ring`, `--sidebar`, `--popover`…
- **Charts** : `--chart-1` à `--chart-5`, `--chart-grid`, `--chart-axis`.
- **Radius** : 4 niveaux max (xs/sm/md/lg).
- **Shadows** : 4 niveaux Ive-subtle.

Le bridge `@theme inline` expose ces vars comme tokens Tailwind → `bg-background`, `text-foreground`, `border-border`, etc.

## Règles de contribution

1. **Zéro hex hardcodé** en dehors de `tokens.css`. Jamais de `bg-blue-*` / `text-gray-*` / `bg-white` dans les nouveaux composants shell/overview.
2. **Typo** : hiérarchie 6 niveaux max (Title-1 32/40/700, Title-2 24/32/600, Title-3 20/28/600, Body 16/24/400, Small 14/21/400, Caption 12/16/500). `tabular-nums` sur tous les chiffres.
3. **Animation discipline** : transitions 200–300ms max. `prefers-reduced-motion` respecté globalement via `tokens.css`.
4. **Accessibilité** : landmarks (`<header role="banner">`, `<nav aria-label>`, `<aside aria-label>`, `<main>`), `aria-current="page"` sur l'item de nav actif, focus ring visible (`ring-ring`), contrast AA minimum light + dark.
5. **Deep-linking** : chaque état d'interface qui mérite d'être partagé vit dans l'URL (page, limit, range).
6. **i18n** : français hardcodé assumé V1. Pas de `t()` pour l'instant.

## Ajouter une page

1. Créer le dossier `src/app/app/<route>/` avec `page.tsx`, `loading.tsx`, `error.tsx`.
2. Ajouter l'entrée dans `src/config/navigation.ts` (section + icon Lucide).
3. Si la page liste une entité, réutiliser `<DataTable>` + `usePaginatedQuery` + les `columns.tsx` existantes.
4. Envelopper chaque page avec `<PageHeader title description actions?>`.

## Ajouter un composant shadcn

```bash
npx shadcn@latest add <name> --yes
```

Le fichier atterrit dans `src/components/ui/<name>.tsx`. Vérifier qu'il utilise bien les tokens (`bg-background`, `bg-card`, `ring-ring`, etc.) et n'introduit pas de hex en dur.

## Scripts

```bash
npm run dev            # Next dev sur :8000 (Turbopack)
npm run build          # Next build (sans Turbopack — bug nested `app/` folder)
npm run type-check     # tsc --noEmit
npm run lint           # next lint
npm run test           # vitest run (utils purs)
npm run test:watch     # vitest watch
npm run cypress:open   # Cypress interactif
npm run cypress:run    # Cypress headless
npm run check-all      # type-check + lint + format:check
```

## Tests

- **Vitest** — `src/utils/*.test.ts` + `src/hooks/*.test.ts` (purs, environment node).
- **Cypress** — 5 specs E2E dans `cypress/e2e/` : `homepage.cy.ts` (landing), `auth-flow.cy.ts`, `dashboard-shell.cy.ts`, `dashboard-overview.cy.ts`, `dashboard-users-crud.cy.ts`. Les E2E nécessitent `make dev-docker` (API + DB) + `npm run dev`.
- Pas de Storybook (surface de maintenance non justifiée).

## Dette technique connue

- `src/features/**/columns.tsx` conservent temporairement des couleurs legacy (`bg-gray-*`, `text-gray-*`) — à nettoyer au fil de l'eau.
- Pagination sort/filter non URL-synced (seulement `?page`).
- Metrics côté backend : pas d'endpoint dédié pour _trip status distribution_ (client-side group-by sur `/admin/trips?limit=200`) ni de delta période précédente (calcul client via `windowDelta`).
- KPIs V2 (DAU/WAU/MAU, AI acceptance, funnel, NPS) absents — nécessitent de nouveaux endpoints backend.
- Multi-langue non implémentée (V1 assumée française).
