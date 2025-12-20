# BagTrip Admin 🎯

Interface d'administration moderne pour la plateforme BagTrip, construite avec Next.js 15, TypeScript et TailwindCSS.

![BagTrip Admin](https://img.shields.io/badge/Next.js-15-black?style=flat-square&logo=next.js)
![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?style=flat-square&logo=typescript)
![TailwindCSS](https://img.shields.io/badge/TailwindCSS-4-38B2AC?style=flat-square&logo=tailwind-css)

## 🚀 Quick Start

### Pour les nouveaux collaborateurs

1. **Cloner le repository :**
```bash
git clone <repository-url>
cd BagTrip/application
```

2. **Initialisation automatique (recommandée) :**
```bash
make init
```
Cette commande va :
- ✅ Installer toutes les dépendances npm
- ✅ Copier le fichier d'environnement
- ✅ Configurer les hooks Git
- ✅ Vérifier la configuration TypeScript

3. **Lancer l'application :**
```bash
make dev
```

L'application sera disponible sur [http://localhost:8000](http://localhost:8000)

### Configuration Alternative (Manuelle)

Si vous préférez configurer manuellement :

```bash
# 1. Installer les dépendances
npm install

# 2. Copier les variables d'environnement
cp .env.example .env.local

# 3. Configurer les hooks Git
make git-hooks

# 4. Lancer le développement
npm run dev
```

## 🛠️ Environnement de développement

### Prérequis système
- **Node.js** >= 22.x
- **npm** >= 10.x
- **Git** pour le versioning

### Variables d'environnement

Le projet utilise des services mock en développement, aucune configuration backend requise :

```bash
# .env.local (généré automatiquement)
NODE_ENV=development
NEXT_PUBLIC_USE_MOCK_SERVICES=true
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

### Architecture technique

```
src/
├── app/                 # Next.js App Router (pages)
│   ├── (auth)/         # Routes d'authentification
│   ├── (dashboard)/    # Routes protégées admin
│   └── layout.tsx      # Layout racine
├── components/         # Composants réutilisables
│   ├── ui/            # Composants UI de base
│   ├── forms/         # Composants de formulaires
│   └── providers/     # Providers React (Query, etc.)
├── services/          # Couche d'accès aux données
├── hooks/             # Hooks React personnalisés
├── types/             # Définitions TypeScript
├── utils/             # Fonctions utilitaires
└── lib/               # Configurations tierces
```

## 🎯 Commandes disponibles

### Développement
```bash
make dev          # Lance le serveur de développement
make build        # Build de production
make start        # Démarre l'app en mode production
```

### Qualité de code
```bash
make lint         # Vérification ESLint
make lint-fix     # Correction automatique ESLint
make type-check   # Vérification TypeScript
make format       # Formatage Prettier
make check-all    # Tous les contrôles qualité
```

### Tests
```bash
make test-e2e           # Tests E2E Cypress (headless)
make test-e2e-open      # Tests E2E avec interface
make cypress-open       # Ouvre Cypress
```

### Utilitaires
```bash
make clean        # Nettoie les fichiers temporaires
make status       # Affiche l'état du projet
make help         # Liste toutes les commandes
```

## 🧪 Système de tests

### Tests End-to-End avec Cypress

Le projet utilise Cypress 15.0 pour les tests E2E :

```bash
# Lancer les tests en mode headless
make test-e2e

# Ouvrir l'interface Cypress pour développer
make cypress-open

# Tests disponibles
cypress/e2e/homepage.cy.ts    # Tests de la page d'accueil (18 tests)
```

**Tests couverts :**
- ✅ Navigation et liens
- ✅ Sections hero et statistiques
- ✅ Fonctionnalités interactives (tabs)
- ✅ Responsive design
- ✅ Accessibilité
- ✅ Performance (< 3s)
- ✅ SEO

### Authentification Mock

En développement, l'app utilise un système d'authentification factice :

**Comptes de test disponibles :**
```
admin@bagtrip.com / admin123 (super_admin)
manager@bagtrip.com / manager123 (admin)
user@bagtrip.com / user123 (user)
```

## 🔒 Qualité et sécurité

### Standards de code
- **ESLint** : Configuration stricte avec règles Next.js
- **Prettier** : Formatage automatique du code
- **TypeScript** : Mode strict activé
- **Conventions** : Hooks Git pour validation automatique

### CI/CD GitHub Actions

Le projet inclut 3 workflows automatisés :

**1. CI Principal** (`.github/workflows/ci.yml`)
- ✅ TypeScript type checking
- ✅ ESLint validation
- ✅ Build verification
- ✅ Tests Cypress (Chrome + Firefox)
- ✅ Quality Gate avec rapports

**2. Sécurité** (`.github/workflows/security.yml`)
- 🔒 Audit des dépendances npm
- 🔒 Détection de secrets (TruffleHog)
- 🔒 Analyse CodeQL
- 📅 Scan hebdomadaire automatique

**3. Validation PR** (`.github/workflows/pr-checks.yml`)
- 📋 Validation format des PR
- 📊 Analyse de taille des changements
- 🔍 Détection des types de modifications
- 📝 Génération de rapports automatiques

### Template de Pull Request

Le projet fournit un template complet pour les PR incluant :
- 📝 Description des changements
- ✅ Checklist qualité complète
- 🧪 Instructions de test
- 🔐 Vérifications sécurité

## 🏗️ Architecture applicative

### Stack technique
- **Frontend :** Next.js 15, React 19, TypeScript 5
- **Styling :** TailwindCSS 4, Headless UI, Heroicons
- **État :** React Query (TanStack Query)
- **Forms :** React Hook Form
- **Charts :** Recharts
- **Tests :** Cypress 15

### Gestion d'état
- **Server State :** React Query pour cache et synchronisation
- **Auth State :** Hooks personnalisés avec tokens JWT
- **Local State :** React useState/useReducer

### Patterns utilisés
- **Composition over Inheritance** : Composants réutilisables
- **Custom Hooks** : Logique métier isolée
- **Service Layer** : Abstraction des appels API
- **Mock Services** : Développement sans backend

## 📱 Fonctionnalités

### Interface d'administration
- 👥 **Gestion utilisateurs** : CRUD, rôles, statuts
- 📊 **Dashboard analytics** : KPIs, graphiques temps réel
- 💬 **Support client** : Gestion feedbacks, tickets
- ⚙️ **Configuration** : Paramètres système
- 🔐 **Sécurité** : Authentification JWT, contrôle d'accès

### UX/UI
- 📱 **Responsive Design** : Mobile-first approach
- 🎨 **Design System** : Composants cohérents TailwindCSS
- ♿ **Accessibilité** : Standards WCAG respectés
- ⚡ **Performance** : Lazy loading, optimisation bundle

## 🚀 Déploiement

### Environnements

**Développement :**
```bash
NODE_ENV=development
NEXT_PUBLIC_USE_MOCK_SERVICES=true
```

**Production :**
```bash
NODE_ENV=production
NEXT_PUBLIC_USE_MOCK_SERVICES=false
NEXT_PUBLIC_API_URL=https://api.bagtrip.com
```

### Build de production
```bash
make build    # Génère le build optimisé
make start    # Démarre le serveur de production
```

## 🤝 Contribution

### Workflow Git
1. Créer une branche depuis `develop`
2. Nommer selon la convention : `feat/`, `fix/`, `docs/`
3. Développer avec les hooks Git actifs
4. Ouvrir une PR avec le template fourni
5. Validation automatique par CI/CD

### Standards de commit
```
feat: ajout de la gestion des utilisateurs
fix: correction du bug d'authentification
docs: mise à jour du README
test: ajout des tests Cypress pour le dashboard
```

## 📚 Ressources

### Documentation
- [Next.js 15 Documentation](https://nextjs.org/docs)
- [TailwindCSS Documentation](https://tailwindcss.com/docs)
- [React Query Documentation](https://tanstack.com/query)
- [Cypress Documentation](https://docs.cypress.io)
