# BagTrip Admin Panel

Console admin pour monitorer le SaaS BagTrip (planification de voyages avec IA).

Stack : Next.js 15 App Router · React 19 · TypeScript strict · Tailwind CSS v4 · shadcn/ui · TanStack Query/Table · next-themes · Cypress + Vitest.

## Quickstart

```bash
npm install
npm run dev        # http://localhost:8000
```

Le dev server a besoin de l'API FastAPI + Postgres. Depuis la racine du monorepo :

```bash
make dev-docker    # Postgres + Redis + API + admin panel
```

Connexion : créer un compte avec `plan = ADMIN` (seed via `api/src/seeds/create_admin.py`) puis `/login`.

## Scripts

```bash
npm run dev           # Next dev sur :8000 (Turbopack)
npm run build         # Next build (prod)
npm run start         # Next start
npm run lint          # ESLint (next lint)
npm run type-check    # tsc --noEmit
npm run format        # Prettier write
npm run format:check  # Prettier check
npm run check-all     # type-check + lint + format:check
npm run test          # Vitest run (unit)
npm run test:watch    # Vitest watch
npm run test:ui       # Vitest UI
npm run cypress:open  # Cypress interactif
npm run cypress:run   # Cypress headless
npm run test:e2e      # Cypress + serveur local (start-server-and-test)
```

## Structure

- `src/app/` — routes Next.js App Router. La landing publique vit sur `/`, la console admin sous `/app/*` (protégée par middleware).
- `src/components/` — primitives shadcn (`ui/`), charpente (`layout/`), charts (`charts/`), providers.
- `src/features/<entity>/` — `columns.tsx` + `hooks.ts` par entité (users, trips, …).
- `src/config/navigation.ts` — source unique consommée par Sidebar, Breadcrumb, CommandPalette.
- `src/styles/tokens.css` — design tokens (`@theme` Tailwind v4 + light/dark surfaces).
- `src/middleware.ts` — protection `/app/*` + redirect legacy `/dashboard → /app`.

## Documentation

- [`ADMIN_UI.md`](./ADMIN_UI.md) — guide design system, conventions, comment ajouter une page, dette connue.
- `CLAUDE.md` (racine monorepo) — contexte général du projet.

## Testing

- **Unit** : Vitest sur les utilitaires purs (`src/utils/*.test.ts`, `src/hooks/*.test.ts`). 32 tests.
- **E2E** : Cypress (`cypress/e2e/*.cy.ts`) — landing, auth, shell, overview, users CRUD.
