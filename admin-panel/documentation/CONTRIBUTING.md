# Guide de Contribution - BagTrip Admin 🤝

Ce guide vous explique comment contribuer efficacement au projet BagTrip Admin.

## 📋 Table des matières

- [Standards de code](#-standards-de-code)
- [Workflow de développement](#-workflow-de-développement)
- [Tests et validation](#-tests-et-validation)
- [Pull Requests](#-pull-requests)
- [Structure du projet](#-structure-du-projet)

## 📝 Standards de code

### Conventions de nommage

**Fichiers et dossiers :**
```
components/          # PascalCase pour les composants
hooks/              # camelCase avec préfixe "use"
services/           # camelCase
utils/              # camelCase
types/              # camelCase avec suffixe .types.ts
```

**Variables et fonctions :**
```typescript
// ✅ Bon
const userName = 'john';
const fetchUserData = async () => {};
const UserProfile = () => {};

// ❌ Mauvais  
const user_name = 'john';
const FetchUserData = async () => {};
const userProfile = () => {};
```

### Standards TypeScript

**Types et interfaces :**
```typescript
// ✅ Préférer les interfaces pour les objets
interface User {
  id: string;
  name: string;
  role: UserRole;
}

// ✅ Types pour les unions et primitives
type UserRole = 'admin' | 'user' | 'super_admin';
type Status = 'active' | 'inactive';

// ✅ Toujours typer les props de composants
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}
```

**Hooks personnalisés :**
```typescript
// ✅ Structure recommandée
export const useAuth = () => {
  const [state, setState] = useState<AuthState>({
    user: null,
    isLoading: true,
    error: null,
  });

  // Logic here...

  return {
    ...state,
    login,
    logout,
  };
};
```

### Standards React

**Composants fonctionnels :**
```typescript
// ✅ Structure recommandée
interface ComponentProps {
  // Props ici
}

export const Component: React.FC<ComponentProps> = ({ 
  prop1, 
  prop2 
}) => {
  // Hooks en premier
  const [state, setState] = useState();
  const { data } = useQuery();
  
  // Handlers
  const handleClick = () => {};
  
  // Effects
  useEffect(() => {}, []);
  
  // Render
  return <div>...</div>;
};
```

**Gestion d'état :**
```typescript
// ✅ React Query pour l'état serveur
const { data, isLoading, error } = useUsers();

// ✅ useState pour l'état local
const [isOpen, setIsOpen] = useState(false);

// ✅ Hooks personnalisés pour la logique complexe
const { user, login, logout } = useAuth();
```

## 🔄 Workflow de développement

### 1. Setup initial
```bash
# Cloner et initialiser
git clone <repo>
cd BagTrip/application
make init
```

### 2. Créer une branche

**Conventions de nommage :**
```bash
# Nouvelles fonctionnalités
git checkout -b feat/user-management

# Corrections de bugs
git checkout -b fix/login-redirect

# Améliorations
git checkout -b improve/dashboard-performance

# Documentation
git checkout -b docs/contributing-guide

# Tests
git checkout -b test/user-crud-e2e
```

### 3. Développement local

**Commandes essentielles :**
```bash
make dev                    # Lancer le serveur de dev
make check-all             # Vérifications complètes
make test-e2e-open         # Tests interactifs
```

**Validation continue :**
- Les hooks Git vérifient automatiquement le code
- ESLint et Prettier s'exécutent à chaque commit
- TypeScript est validé avant chaque push

### 4. Commits

**Format des messages :**
```bash
# Structure : type(scope): description

git commit -m "feat(auth): add JWT token refresh mechanism"
git commit -m "fix(dashboard): correct stats calculation bug"
git commit -m "docs(readme): update installation instructions"
git commit -m "test(homepage): add responsive design tests"
```

**Types autorisés :**
- `feat` : Nouvelle fonctionnalité
- `fix` : Correction de bug
- `docs` : Documentation
- `test` : Tests
- `refactor` : Refactoring
- `perf` : Amélioration de performance
- `ci` : CI/CD
- `chore` : Maintenance

## 🧪 Tests et validation

### Tests requis

**Avant chaque PR :**
```bash
# Vérifications qualité
make check-all

# Tests E2E
make test-e2e

# Build de production
make build
```

### Écrire de nouveaux tests

**Tests Cypress :**
```typescript
// cypress/e2e/feature.cy.ts
describe('Feature Name', () => {
  beforeEach(() => {
    cy.visit('/feature');
  });

  it('should do something', () => {
    cy.get('[data-cy="element"]').should('be.visible');
    cy.get('[data-cy="button"]').click();
    cy.url().should('include', '/expected');
  });
});
```

**Attributs data-cy :**
```tsx
// ✅ Toujours ajouter data-cy pour les tests
<button 
  data-cy="submit-btn"
  onClick={handleSubmit}
>
  Submit
</button>
```

### Coverage requis

- **Tests E2E :** Couverture des parcours utilisateur principaux
- **Fonctionnalités critiques :** 100% testées
- **Composants réutilisables :** Tests de comportement

## 📤 Pull Requests

### 1. Préparation

**Checklist avant PR :**
- [ ] Tests passent localement
- [ ] Code formaté et linté
- [ ] TypeScript compile sans erreurs
- [ ] Pas de console.log ou debugger
- [ ] Documentation mise à jour si nécessaire

### 2. Création de la PR

**Utiliser le template fourni :**
- Description claire des changements
- Type de changement identifié
- Instructions de test
- Screenshots si applicable

### 3. Review process

**Critères de validation :**
- ✅ CI/CD passe (18+ checks automatiques)
- ✅ Review approuvée par un maintainer
- ✅ Conflicts résolus
- ✅ Tests ajoutés/mis à jour

**Après merge :**
- Branche supprimée automatiquement
- Deploy automatique si configuré

## 🏗️ Structure du projet

### Ajout de nouvelles fonctionnalités

**1. Types TypeScript**
```typescript
// src/types/newFeature.ts
export interface NewFeature {
  id: string;
  name: string;
  // ...
}
```

**2. Service API**
```typescript
// src/services/newFeature.ts
export const newFeatureService = {
  async getAll(): Promise<NewFeature[]> {
    // Implementation
  },
  // ...
};
```

**3. Hook personnalisé**
```typescript
// src/hooks/useNewFeature.ts
export const useNewFeature = () => {
  return useQuery({
    queryKey: ['newFeature'],
    queryFn: newFeatureService.getAll,
  });
};
```

**4. Composant**
```typescript
// src/components/NewFeature/NewFeatureList.tsx
export const NewFeatureList = () => {
  const { data, isLoading } = useNewFeature();
  
  // Component logic
};
```

**5. Page**
```typescript
// src/app/(dashboard)/new-feature/page.tsx
export default function NewFeaturePage() {
  return <NewFeatureList />;
}
```

**6. Tests**
```typescript
// cypress/e2e/newFeature.cy.ts
describe('New Feature', () => {
  // Tests ici
});
```

### Modification des services existants

**Mock vs Real services :**
```typescript
// Ajouter à src/services/newFeature.mock.ts pour le développement
export const mockNewFeatureService = {
  async getAll(): Promise<NewFeature[]> {
    await delay(500);
    return mockData;
  },
};

// Utiliser le switch automatique dans le service principal
export const newFeatureService = USE_MOCK 
  ? mockNewFeatureService 
  : realNewFeatureService;
```

## ⚡ Bonnes pratiques

### Performance
- Lazy loading des composants lourds
- Memoization avec useMemo/useCallback quand nécessaire
- Optimisation des images avec Next.js Image
- Bundle analysis régulière

### Sécurité
- Jamais de secrets en dur dans le code
- Validation des inputs utilisateur
- Sanitization des données
- Headers de sécurité configurés

### UX
- Loading states partout
- Messages d'erreur clairs
- Feedback utilisateur immédiat
- Accessibilité (ARIA, keyboard navigation)

### Maintenance
- Documentation inline JSDoc
- Types stricts partout
- Tests automatisés
- Monitoring des erreurs

## 🆘 Support

**En cas de problème :**
1. Vérifier la documentation
2. Chercher dans les issues existantes
3. Demander sur le canal Slack #bagtrip-admin
4. Créer une issue avec reproduction steps

**Contacts :**
- **Lead Dev :** @lead-dev-username
- **DevOps :** @devops-username  
- **Design :** @design-username

---

Merci de contribuer à BagTrip Admin ! 🚀