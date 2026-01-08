# Epic 1: Core Data Models & Services (API) - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer les modèles de données et services de base nécessaires pour gérer les conversations, messages et contexte dans le système de planification de voyage par IA.

**Durée estimée** : 2-3 jours de développement

**Dépendances** : Aucune (Epic 1 est la fondation)

**Livrables** :
- 3 nouveaux modèles SQLAlchemy (Conversation, Message, Context)
- 3 nouveaux services (ConversationService, MessageService, ContextService)
- 1 script de migration DB
- Tests unitaires pour chaque service
- Documentation des modèles et services

---

## 🎯 Objectifs détaillés

1. **Modèles de données** : Créer les tables `conversations`, `messages`, et `contexts` avec les relations appropriées
2. **Services métier** : Implémenter la logique CRUD pour chaque entité
3. **Migration DB** : Créer un script de migration idempotent
4. **Intégration** : Intégrer les nouveaux modèles dans le système existant
5. **Tests** : Valider le fonctionnement de chaque composant

---

## 📦 Structure des tâches

### Tâche 1.1 : Créer le modèle Conversation
**Fichier** : `api/src/models/conversation.py`

**Spécifications** :
- Table : `conversations`
- Colonnes :
  - `id` : UUID (primary key, auto-généré)
  - `trip_id` : UUID (ForeignKey vers `trips.id`, nullable=False, index=True)
  - `user_id` : UUID (ForeignKey vers `users.id`, nullable=False, index=True)
  - `title` : String (nullable=True)
  - `created_at` : DateTime(timezone=True, server_default=func.now())
  - `updated_at` : DateTime(timezone=True, onupdate=func.now())
- Relations :
  - `trip` : relationship vers `Trip` (back_populates="conversations")
  - `messages` : relationship vers `Message` (cascade="all, delete-orphan")
  - `contexts` : relationship vers `Context` (cascade="all, delete-orphan")

**Critères d'acceptation** :
- ✅ Modèle créé selon le pattern existant (User, Trip)
- ✅ Relations SQLAlchemy configurées correctement
- ✅ Index sur `trip_id` et `user_id` pour performance
- ✅ Timestamps automatiques

**Estimation** : 30 minutes

---

### Tâche 1.2 : Créer le modèle Message
**Fichier** : `api/src/models/message.py`

**Spécifications** :
- Table : `messages`
- Colonnes :
  - `id` : UUID (primary key, auto-généré)
  - `conversation_id` : UUID (ForeignKey vers `conversations.id`, nullable=False, index=True)
  - `role` : String (nullable=False) - valeurs : `user`, `assistant`, `tool`
  - `content` : Text (nullable=False)
  - `metadata` : JSON (nullable=True) - pour tool calls, offer_ids, etc.
  - `created_at` : DateTime(timezone=True, server_default=func.now())
- Relations :
  - `conversation` : relationship vers `Conversation` (back_populates="messages")

**Critères d'acceptation** :
- ✅ Modèle créé avec contrainte sur `role` (enum ou validation)
- ✅ Index sur `conversation_id` pour requêtes rapides
- ✅ Support JSON pour metadata flexible
- ✅ Pas de `updated_at` (messages immutables)

**Estimation** : 30 minutes

---

### Tâche 1.3 : Créer le modèle Context
**Fichier** : `api/src/models/context.py`

**Spécifications** :
- Table : `contexts`
- Colonnes :
  - `id` : UUID (primary key, auto-généré)
  - `user_id` : UUID (ForeignKey vers `users.id`, nullable=False, index=True)
  - `trip_id` : UUID (ForeignKey vers `trips.id`, nullable=False, index=True)
  - `conversation_id` : UUID (ForeignKey vers `conversations.id`, nullable=False, index=True)
  - `version` : Integer (nullable=False, default=1) - **IMPORTANT pour versioning**
  - `state` : JSON (nullable=False) - LangChain state machine
  - `ui` : JSON (nullable=False) - Widgets et actions UI
  - `updated_at` : DateTime(timezone=True, onupdate=func.now())
- Relations :
  - `conversation` : relationship vers `Conversation` (back_populates="contexts")
  - `trip` : relationship vers `Trip`
  - `user` : relationship vers `User`

**Critères d'acceptation** :
- ✅ Versioning implémenté (version incrémentée à chaque update)
- ✅ Index composite sur (user_id, trip_id, conversation_id) pour requêtes rapides
- ✅ JSON pour state et ui (flexibilité)
- ✅ Pas de `created_at` (on crée toujours un context initial)

**Estimation** : 45 minutes

---

### Tâche 1.4 : Mettre à jour les modèles existants
**Fichiers** :
- `api/src/models/trip.py` (ajouter relation)
- `api/src/models/__init__.py` (exporter nouveaux modèles)

**Modifications** :
- Ajouter `conversations` relationship dans `Trip`
- Exporter `Conversation`, `Message`, `Context` dans `__init__.py`

**Critères d'acceptation** :
- ✅ Relations bidirectionnelles fonctionnelles
- ✅ Imports corrects dans `__init__.py`

**Estimation** : 15 minutes

---

### Tâche 1.5 : Créer ConversationService
**Fichier** : `api/src/services/conversation_service.py`

**Méthodes à implémenter** :

```python
@staticmethod
def create_conversation(
    db: Session,
    trip_id: UUID,
    user_id: UUID,
    title: str | None = None
) -> Conversation:
    """
    Créer une nouvelle conversation pour un trip.
    - Vérifier que le trip appartient à l'utilisateur
    - Créer la conversation
    - Retourner la conversation créée
    """

@staticmethod
def get_conversation_by_id(
    db: Session,
    conversation_id: UUID,
    user_id: UUID
) -> Conversation | None:
    """
    Récupérer une conversation par ID.
    - Vérifier que la conversation appartient à l'utilisateur
    - Retourner None si non trouvée ou non autorisée
    """

@staticmethod
def get_conversations_by_trip(
    db: Session,
    trip_id: UUID,
    user_id: UUID
) -> list[Conversation]:
    """
    Récupérer toutes les conversations d'un trip.
    - Vérifier que le trip appartient à l'utilisateur
    - Retourner liste triée par created_at DESC
    """
```

**Gestion d'erreurs** :
- `TRIP_NOT_FOUND` : si trip_id n'existe pas ou n'appartient pas à user_id
- Utiliser `AppError` du pattern existant

**Critères d'acceptation** :
- ✅ Toutes les méthodes implémentées
- ✅ Validation ownership (user_id, trip_id)
- ✅ Gestion d'erreurs cohérente avec le reste du code
- ✅ Pattern similaire à `TripsService`

**Estimation** : 1h30

---

### Tâche 1.6 : Créer MessageService
**Fichier** : `api/src/services/message_service.py`

**Méthodes à implémenter** :

```python
@staticmethod
def create_message(
    db: Session,
    conversation_id: UUID,
    role: str,
    content: str,
    metadata: dict | None = None
) -> Message:
    """
    Créer un nouveau message dans une conversation.
    - Valider role (user, assistant, tool)
    - Créer le message
    - Retourner le message créé
    """

@staticmethod
def get_messages_by_conversation(
    db: Session,
    conversation_id: UUID,
    limit: int = 20,
    offset: int = 0
) -> list[Message]:
    """
    Récupérer les messages d'une conversation.
    - Pagination avec limit/offset
    - Tri par created_at ASC (chronologique)
    - Retourner liste de messages
    """

@staticmethod
def get_message_count_by_conversation(
    db: Session,
    conversation_id: UUID
) -> int:
    """
    Compter le nombre total de messages dans une conversation.
    Utile pour la pagination côté client.
    """
```

**Gestion d'erreurs** :
- `INVALID_ROLE` : si role n'est pas user/assistant/tool
- `CONVERSATION_NOT_FOUND` : si conversation_id n'existe pas

**Critères d'acceptation** :
- ✅ Validation du role
- ✅ Pagination fonctionnelle
- ✅ Tri chronologique correct
- ✅ Pattern similaire aux autres services

**Estimation** : 1h

---

### Tâche 1.7 : Créer ContextService
**Fichier** : `api/src/services/context_service.py`

**Méthodes à implémenter** :

```python
@staticmethod
def get_context(
    db: Session,
    user_id: UUID,
    trip_id: UUID,
    conversation_id: UUID
) -> Context | None:
    """
    Récupérer le contexte actuel (dernière version).
    - Rechercher le contexte avec la version la plus élevée
    - Vérifier ownership
    - Retourner None si non trouvé
    """

@staticmethod
def create_context(
    db: Session,
    user_id: UUID,
    trip_id: UUID,
    conversation_id: UUID,
    state: dict,
    ui: dict
) -> Context:
    """
    Créer un nouveau contexte (version 1).
    - Vérifier ownership
    - Créer avec version=1
    - Retourner le contexte créé
    """

@staticmethod
def update_context(
    db: Session,
    context_id: UUID,
    state: dict,
    ui: dict,
    current_version: int
) -> Context:
    """
    Mettre à jour un contexte (incrémenter version).
    - Vérifier que current_version correspond à la version actuelle
    - Incrémenter version
    - Mettre à jour state et ui
    - Retourner le contexte mis à jour
    """

@staticmethod
def increment_context_version(
    db: Session,
    context_id: UUID
) -> int:
    """
    Incrémenter la version d'un contexte (sans modifier state/ui).
    Utile pour invalider un contexte sans le modifier.
    - Retourner la nouvelle version
    """
```

**Gestion d'erreurs** :
- `CONTEXT_NOT_FOUND` : si context_id n'existe pas
- `CONTEXT_VERSION_MISMATCH` : si current_version ne correspond pas (optimistic locking)
- `UNAUTHORIZED` : si user n'est pas propriétaire

**Critères d'acceptation** :
- ✅ Versioning fonctionnel (optimistic locking)
- ✅ Validation ownership
- ✅ Gestion des conflits de version
- ✅ Pattern cohérent avec les autres services

**Estimation** : 2h

---

### Tâche 1.8 : Créer le script de migration
**Fichier** : `api/src/migrations/migrate_conversation_tables.py`

**Spécifications** :
- Script idempotent (peut être exécuté plusieurs fois)
- Vérifier existence des tables avant création
- Utiliser le pattern existant (`migrate_user_table.py`, `migrate_booking_tables.py`)
- Logs informatifs à chaque étape

**Structure** :
```python
def migrate_conversation_tables(engine: Engine) -> None:
    """
    Migrate conversation-related tables:
    - Create conversations table
    - Create messages table
    - Create contexts table
    """
    with engine.connect() as conn:
        trans = conn.begin()
        try:
            # Check and create conversations table
            # Check and create messages table
            # Check and create contexts table
            trans.commit()
        except Exception as e:
            trans.rollback()
            raise
```

**Critères d'acceptation** :
- ✅ Idempotent (peut être exécuté plusieurs fois sans erreur)
- ✅ Gestion d'erreurs avec rollback
- ✅ Logs clairs
- ✅ Pattern cohérent avec migrations existantes

**Estimation** : 1h

---

### Tâche 1.9 : Intégrer la migration dans main.py
**Fichier** : `api/src/main.py`

**Modifications** :
- Ajouter l'appel à `migrate_conversation_tables()` dans la fonction `lifespan`
- Placer après les autres migrations existantes
- Gérer les exceptions (logger.warn si échec)

**Code à ajouter** :
```python
# Migrer les tables de conversation si nécessaire
try:
    from src.migrations.migrate_conversation_tables import migrate_conversation_tables
    migrate_conversation_tables(engine)
except Exception as e:
    logger.warn(f"Conversation tables migration failed (may already be migrated): {e}")
```

**Critères d'acceptation** :
- ✅ Migration appelée au démarrage de l'API
- ✅ Gestion d'erreurs non-bloquante
- ✅ Logs appropriés

**Estimation** : 15 minutes

---

### Tâche 1.10 : Tests unitaires (optionnel mais recommandé)
**Fichiers** :
- `api/tests/test_conversation_service.py`
- `api/tests/test_message_service.py`
- `api/tests/test_context_service.py`

**Tests à implémenter** :
- Création de conversations/messages/contexts
- Récupération par ID
- Validation ownership
- Pagination messages
- Versioning context
- Gestion d'erreurs

**Critères d'acceptation** :
- ✅ Couverture des cas principaux
- ✅ Tests d'erreurs
- ✅ Tests de validation

**Estimation** : 2h (optionnel)

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
api/src/models/
  ├── conversation.py          [NOUVEAU]
  ├── message.py              [NOUVEAU]
  └── context.py              [NOUVEAU]

api/src/services/
  ├── conversation_service.py [NOUVEAU]
  ├── message_service.py      [NOUVEAU]
  └── context_service.py      [NOUVEAU]

api/src/migrations/
  └── migrate_conversation_tables.py [NOUVEAU]
```

### Fichiers à modifier

```
api/src/models/
  ├── __init__.py             [MODIFIER - ajouter exports]
  └── trip.py                 [MODIFIER - ajouter relation]

api/src/main.py               [MODIFIER - ajouter migration]
```

---

## 🗄️ Schéma de base de données

### Table `conversations`

```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_conversations_trip_id ON conversations(trip_id);
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
```

### Table `messages`

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR NOT NULL CHECK (role IN ('user', 'assistant', 'tool')),
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(conversation_id, created_at);
```

### Table `contexts`

```sql
CREATE TABLE contexts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    version INTEGER NOT NULL DEFAULT 1,
    state JSONB NOT NULL,
    ui JSONB NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_contexts_user_trip_conv ON contexts(user_id, trip_id, conversation_id);
CREATE INDEX idx_contexts_conversation_version ON contexts(conversation_id, version DESC);
```

---

## 🔄 Flux de données

### Création d'une conversation

```
1. User crée un Trip
2. User crée une Conversation pour ce Trip
   → ConversationService.create_conversation()
   → Retourne Conversation avec id
3. (Optionnel) Création d'un Context initial
   → ContextService.create_context()
   → Version = 1, state = {}, ui = {}
```

### Ajout d'un message

```
1. User envoie un message
   → MessageService.create_message()
   → role = "user", content = "..."
2. Agent répond
   → MessageService.create_message()
   → role = "assistant", content = "...", metadata = {...}
```

### Mise à jour du contexte

```
1. Agent exécute un tool (ex: search_flights)
2. Tool met à jour le contexte
   → ContextService.update_context()
   → Version++, state updated, ui updated
3. Client reçoit context.updated via SSE
```

---

## ✅ Checklist de validation

### Modèles
- [x] Conversation créé avec toutes les colonnes
- [x] Message créé avec validation role
- [x] Context créé avec versioning
- [x] Relations SQLAlchemy configurées
- [x] Exports dans `__init__.py`
- [x] Relation ajoutée dans Trip

### Services
- [x] ConversationService : create, get_by_id, get_by_trip
- [x] MessageService : create, get_by_conversation, count
- [x] ContextService : get, create, update, increment_version
- [x] Validation ownership dans tous les services
- [x] Gestion d'erreurs cohérente

### Migration
- [x] Script de migration créé
- [x] Migration idempotente
- [x] Intégration dans main.py
- [x] Tables créées correctement en DB

### Tests
- [ ] Tests unitaires (optionnel)
- [ ] Test manuel : créer conversation → message → context
- [ ] Test versioning context
- [ ] Test pagination messages

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 1.1** : Créer modèle Conversation
2. **Tâche 1.2** : Créer modèle Message
3. **Tâche 1.3** : Créer modèle Context
4. **Tâche 1.4** : Mettre à jour modèles existants
5. **Tâche 1.8** : Créer script de migration
6. **Tâche 1.9** : Intégrer migration dans main.py
7. **Tâche 1.5** : Créer ConversationService
8. **Tâche 1.6** : Créer MessageService
9. **Tâche 1.7** : Créer ContextService
10. **Tâche 1.10** : Tests (optionnel)

---

## 📝 Notes importantes

### Versioning du contexte
- Le `version` est **critique** pour éviter les conflits
- Toujours vérifier `current_version` avant update
- Incrémenter à chaque modification
- Client doit envoyer `context_version` dans les requêtes

### Performance
- Index sur toutes les foreign keys
- Index composite sur (user_id, trip_id, conversation_id) pour Context
- Index sur (conversation_id, created_at) pour Messages (pagination)

### Sécurité
- Toujours valider ownership (user_id) dans les services
- Ne jamais exposer les IDs sans vérification
- Utiliser les foreign keys avec CASCADE pour la cohérence

### JSON Fields
- `metadata` (Message) : flexible pour tool calls, offer_ids, etc.
- `state` (Context) : LangChain state machine
- `ui` (Context) : widgets et actions UI

---

## 🔗 Liens avec les épics suivants

- **Epic 2** : Utilisera ConversationService et MessageService pour les endpoints API
- **Epic 3** : Utilisera ContextService pour gérer le contexte de l'agent
- **Epic 6** : Client utilisera les endpoints créés dans Epic 2

---

## 📚 Références

- Pattern de modèles : `api/src/models/user.py`, `trip.py`
- Pattern de services : `api/src/services/trips_service.py`
- Pattern de migrations : `api/src/migrations/migrate_user_table.py`
- Gestion d'erreurs : `api/src/utils/errors.py`

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Implémenté - Terminé

## Notes d'implémentation

### Changements par rapport au plan initial

1. **Colonne `metadata` renommée en `message_metadata`**
   - SQLAlchemy réserve le nom `metadata` pour son propre usage
   - La colonne a été renommée en `message_metadata` dans le modèle `Message`
   - Mise à jour correspondante dans la migration et le service

### Fichiers créés

- `api/src/models/conversation.py` - Modèle Conversation
- `api/src/models/message.py` - Modèle Message
- `api/src/models/context.py` - Modèle Context
- `api/src/services/conversation_service.py` - Service ConversationService
- `api/src/services/message_service.py` - Service MessageService
- `api/src/services/context_service.py` - Service ContextService
- `api/src/migrations/migrate_conversation_tables.py` - Script de migration

### Fichiers modifiés

- `api/src/models/trip.py` - Ajout relation `conversations`
- `api/src/models/__init__.py` - Export des nouveaux modèles
- `api/src/main.py` - Intégration de la migration

### Tests effectués

- ✅ Modèles créés et relations configurées
- ✅ Migration idempotente testée
- ✅ Services implémentés avec validation ownership
- ✅ Versioning du contexte avec optimistic locking
- ✅ Aucune erreur de linting
