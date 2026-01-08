# Epic 2: Conversation & Message Management API - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer les endpoints API pour gérer les conversations et récupérer l'historique des messages, permettant au client de créer des conversations et d'accéder à l'historique des messages.

**Durée estimée** : 1-2 jours de développement

**Dépendances** : Epic 1 (modèles Conversation, Message, Context et services associés)

**Livrables** :
- 2 nouveaux modules de routes API (conversations, messages) ✅
- 2 nouveaux modules de schémas Pydantic ✅
- Intégration dans le router principal ✅
- Tests manuels des endpoints (optionnel)
- Documentation des endpoints ✅

**Statut** : ✅ **IMPLÉMENTÉ** - Toutes les tâches de développement sont terminées. Les endpoints sont fonctionnels et intégrés dans l'application principale.

---

## 🎯 Objectifs détaillés

1. **Endpoints Conversations** : Créer les routes pour créer, lister et récupérer des conversations
2. **Endpoints Messages** : Créer les routes pour récupérer l'historique des messages avec pagination
3. **Sécurité** : Implémenter la validation d'ownership (RBAC minimal) dans chaque endpoint
4. **Schémas** : Définir les schémas de requête et réponse pour chaque endpoint
5. **Intégration** : Enregistrer les nouveaux routers dans l'application principale

---

## 📦 Structure des tâches

### Tâche 2.1 : Créer les schémas pour les conversations
**Fichier** : `api/src/api/conversations/schemas.py`

**Schémas à créer** :

```python
class ConversationCreateRequest(BaseModel):
    """Requête de création de conversation."""
    title: str | None = None

class ConversationResponse(BaseModel):
    """Réponse conversation."""
    id: UUID
    tripId: UUID = Field(alias="trip_id")
    userId: UUID = Field(alias="user_id")
    title: str | None = None
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")
    
    class Config:
        from_attributes = True
        populate_by_name = True

class ConversationListResponse(BaseModel):
    """Réponse liste de conversations."""
    items: list[ConversationResponse]

class ConversationDetailResponse(BaseModel):
    """Réponse détaillée d'une conversation."""
    conversation: ConversationResponse
```

**Critères d'acceptation** :
- ✅ Schémas créés selon le pattern existant (TripResponse, etc.)
- ✅ Utilisation de `Field(alias=...)` pour mapping camelCase ↔ snake_case
- ✅ Configuration `from_attributes = True` et `populate_by_name = True`
- ✅ Types corrects (UUID, datetime, Optional)

**Estimation** : 30 minutes

---

### Tâche 2.2 : Créer les routes pour les conversations
**Fichier** : `api/src/api/conversations/routes.py`

**Endpoints à implémenter** :

#### 1. `POST /v1/trips/{tripId}/conversations`
```python
@router.post(
    "",
    response_model=ConversationDetailResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new conversation",
    description="Create a new conversation for a trip",
)
async def create_conversation(
    request: ConversationCreateRequest,
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Créer une nouvelle conversation pour un trip.
    - Vérifier que le trip appartient à l'utilisateur (via ConversationService)
    - Créer la conversation avec ConversationService.create_conversation()
    - Retourner la conversation créée
    """
```

#### 2. `GET /v1/trips/{tripId}/conversations`
```python
@router.get(
    "",
    response_model=ConversationListResponse,
    summary="List conversations for a trip",
    description="Get all conversations for a specific trip",
)
async def list_conversations(
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lister toutes les conversations d'un trip.
    - Vérifier que le trip appartient à l'utilisateur
    - Récupérer les conversations via ConversationService.get_conversations_by_trip()
    - Retourner la liste triée par created_at DESC
    """
```

#### 3. `GET /v1/conversations/{conversationId}`
```python
@router.get(
    "/{conversationId}",
    response_model=ConversationDetailResponse,
    summary="Get conversation details",
    description="Get detailed information about a specific conversation",
)
async def get_conversation(
    conversationId: UUID = Path(..., description="Conversation ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Récupérer une conversation par ID.
    - Vérifier que la conversation appartient à l'utilisateur
    - Récupérer via ConversationService.get_conversation_by_id()
    - Retourner la conversation ou 404 si non trouvée
    """
```

**Gestion d'erreurs** :
- Utiliser `AppError` et `create_http_exception` du pattern existant
- Erreurs possibles : `TRIP_NOT_FOUND`, `CONVERSATION_NOT_FOUND`, `UNAUTHORIZED`

**Critères d'acceptation** :
- ✅ Tous les endpoints implémentés
- ✅ Validation ownership via les services (pas de vérification directe en route)
- ✅ Gestion d'erreurs cohérente avec le reste de l'API
- ✅ Pattern similaire à `api/src/api/trips/routes.py`
- ✅ Utilisation de `get_current_user` pour l'authentification

**Estimation** : 1h30

---

### Tâche 2.3 : Créer le module __init__.py pour conversations
**Fichier** : `api/src/api/conversations/__init__.py`

**Contenu** :
```python
"""Module pour la gestion des conversations."""
```

**Critères d'acceptation** :
- ✅ Fichier créé avec docstring
- ✅ Pattern cohérent avec les autres modules API

**Estimation** : 5 minutes

---

### Tâche 2.4 : Créer les schémas pour les messages
**Fichier** : `api/src/api/messages/schemas.py`

**Schémas à créer** :

```python
class MessageResponse(BaseModel):
    """Réponse message."""
    id: UUID
    conversationId: UUID = Field(alias="conversation_id")
    role: str  # "user", "assistant", "tool"
    content: str
    metadata: dict | None = Field(default=None, alias="message_metadata")
    createdAt: datetime = Field(alias="created_at")
    
    class Config:
        from_attributes = True
        populate_by_name = True

class MessageListResponse(BaseModel):
    """Réponse liste de messages avec pagination."""
    items: list[MessageResponse]
    total: int
    limit: int
    offset: int
```

**Critères d'acceptation** :
- ✅ Schémas créés selon le pattern existant
- ✅ Support de la pagination (total, limit, offset)
- ✅ Mapping correct de `message_metadata` (alias pour `metadata` en DB)
- ✅ Types corrects

**Estimation** : 30 minutes

---

### Tâche 2.5 : Créer les routes pour les messages
**Fichier** : `api/src/api/messages/routes.py`

**Endpoint à implémenter** :

#### `GET /v1/conversations/{conversationId}/messages`
```python
@router.get(
    "",
    response_model=MessageListResponse,
    summary="Get conversation messages",
    description="Get paginated list of messages for a conversation",
)
async def get_messages(
    conversationId: UUID = Path(..., description="Conversation ID"),
    limit: int = Query(default=20, ge=1, le=100, description="Number of messages to return"),
    offset: int = Query(default=0, ge=0, description="Number of messages to skip"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Récupérer l'historique des messages d'une conversation avec pagination.
    - Vérifier que la conversation appartient à l'utilisateur
    - Récupérer les messages via MessageService.get_messages_by_conversation()
    - Récupérer le total via MessageService.get_message_count_by_conversation()
    - Retourner la liste paginée triée par created_at ASC (chronologique)
    """
```

**Gestion d'erreurs** :
- `CONVERSATION_NOT_FOUND` : si conversation_id n'existe pas ou n'appartient pas à l'utilisateur
- Validation des paramètres de pagination (limit max 100, offset >= 0)

**Critères d'acceptation** :
- ✅ Endpoint implémenté avec pagination
- ✅ Validation ownership (via ConversationService.get_conversation_by_id)
- ✅ Paramètres de pagination validés (Query avec ge/le)
- ✅ Tri chronologique correct (created_at ASC)
- ✅ Retourne total pour permettre la pagination côté client
- ✅ Gestion d'erreurs cohérente

**Estimation** : 1h

---

### Tâche 2.6 : Créer le module __init__.py pour messages
**Fichier** : `api/src/api/messages/__init__.py`

**Contenu** :
```python
"""Module pour la gestion des messages."""
```

**Critères d'acceptation** :
- ✅ Fichier créé avec docstring
- ✅ Pattern cohérent avec les autres modules API

**Estimation** : 5 minutes

---

### Tâche 2.7 : Intégrer les routers dans l'application principale
**Fichier** : `api/src/main.py`

**Modifications** :
- Importer les nouveaux routers
- Ajouter les routers à l'application FastAPI avec `app.include_router()`

**Code à ajouter** :
```python
# Imports
from src.api.conversations.routes import router as conversations_router
from src.api.messages.routes import router as messages_router

# Dans la fonction de création de l'app ou après création
app.include_router(conversations_router, prefix="/v1/trips/{tripId}/conversations")
app.include_router(conversations_router, prefix="/v1/conversations")  # Pour GET /v1/conversations/{id}
app.include_router(messages_router, prefix="/v1/conversations/{conversationId}/messages")
```

**Note** : Attention à la gestion des préfixes. Il faudra peut-être créer deux routers séparés ou gérer les préfixes différemment.

**Alternative (recommandée)** :
- Créer un router pour `/v1/trips/{tripId}/conversations` avec préfixe `/v1/trips/{tripId}/conversations`
- Créer un router séparé pour `/v1/conversations/{conversationId}` avec préfixe `/v1/conversations`
- Ou utiliser un seul router avec des routes qui gèrent les deux cas

**Critères d'acceptation** :
- ✅ Routers enregistrés correctement
- ✅ Endpoints accessibles et fonctionnels
- ✅ Pas de conflits de routes
- ✅ Tags appropriés pour la documentation Swagger

**Estimation** : 30 minutes

---

### Tâche 2.8 : Tests manuels des endpoints (optionnel mais recommandé)
**Fichiers** : Documentation ou script de test

**Tests à effectuer** :

1. **Créer une conversation** :
   ```bash
   POST /v1/trips/{tripId}/conversations
   Body: { "title": "Ma conversation" }
   Headers: Authorization: Bearer {token}
   ```
   - ✅ Vérifier création réussie
   - ✅ Vérifier que le trip appartient à l'utilisateur
   - ✅ Tester avec trip inexistant (erreur 404)
   - ✅ Tester avec trip d'un autre utilisateur (erreur 403/404)

2. **Lister les conversations d'un trip** :
   ```bash
   GET /v1/trips/{tripId}/conversations
   Headers: Authorization: Bearer {token}
   ```
   - ✅ Vérifier liste retournée
   - ✅ Vérifier tri par created_at DESC
   - ✅ Tester avec trip inexistant

3. **Récupérer une conversation** :
   ```bash
   GET /v1/conversations/{conversationId}
   Headers: Authorization: Bearer {token}
   ```
   - ✅ Vérifier conversation retournée
   - ✅ Tester avec conversation inexistante (erreur 404)
   - ✅ Tester avec conversation d'un autre utilisateur (erreur 403/404)

4. **Récupérer les messages d'une conversation** :
   ```bash
   GET /v1/conversations/{conversationId}/messages?limit=20&offset=0
   Headers: Authorization: Bearer {token}
   ```
   - ✅ Vérifier messages retournés
   - ✅ Vérifier pagination (total, limit, offset)
   - ✅ Vérifier tri chronologique (created_at ASC)
   - ✅ Tester avec limit=10, offset=5
   - ✅ Tester avec conversation inexistante

**Critères d'acceptation** :
- ✅ Tous les endpoints testés manuellement
- ✅ Cas d'erreur testés
- ✅ Validation ownership testée
- ✅ Pagination testée

**Estimation** : 1h (optionnel)

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
api/src/api/
  ├── conversations/
  │   ├── __init__.py          [NOUVEAU]
  │   ├── routes.py            [NOUVEAU]
  │   └── schemas.py           [NOUVEAU]
  └── messages/
      ├── __init__.py          [NOUVEAU]
      ├── routes.py            [NOUVEAU]
      └── schemas.py           [NOUVEAU]
```

### Fichiers à modifier

```
api/src/main.py                [MODIFIER - ajouter routers]
```

---

## 🔄 Flux de données

### Création d'une conversation

```
1. Client envoie POST /v1/trips/{tripId}/conversations
   Body: { "title": "..." }
   Headers: Authorization: Bearer {token}

2. API vérifie l'authentification (get_current_user)
   → Récupère current_user

3. API appelle ConversationService.create_conversation()
   → Vérifie que trip appartient à user_id
   → Crée la conversation
   → Retourne Conversation

4. API retourne ConversationDetailResponse
   → { "conversation": {...} }
```

### Récupération de l'historique des messages

```
1. Client envoie GET /v1/conversations/{conversationId}/messages?limit=20&offset=0
   Headers: Authorization: Bearer {token}

2. API vérifie l'authentification (get_current_user)
   → Récupère current_user

3. API vérifie ownership de la conversation
   → ConversationService.get_conversation_by_id(conversationId, user_id)
   → Retourne 404 si non trouvée ou non autorisée

4. API récupère les messages
   → MessageService.get_messages_by_conversation(conversationId, limit, offset)
   → MessageService.get_message_count_by_conversation(conversationId)

5. API retourne MessageListResponse
   → { "items": [...], "total": N, "limit": 20, "offset": 0 }
```

---

## 🔒 Sécurité

### RBAC minimal

- **Validation ownership** : Chaque endpoint vérifie que la ressource (trip, conversation) appartient à l'utilisateur authentifié
- **Authentification requise** : Tous les endpoints utilisent `Depends(get_current_user)`
- **Pas de vérification directe en route** : La validation se fait via les services (ConversationService, MessageService)

### Points d'attention

- ✅ Ne jamais exposer les IDs sans vérification d'ownership
- ✅ Utiliser les services pour toutes les vérifications (pas de requêtes directes en route)
- ✅ Gérer les erreurs 404/403 de manière cohérente
- ✅ Ne pas exposer les messages d'autres utilisateurs

---

## ✅ Checklist de validation

### Schémas
- [x] ConversationCreateRequest créé
- [x] ConversationResponse créé avec alias corrects
- [x] ConversationListResponse créé
- [x] ConversationDetailResponse créé
- [x] MessageResponse créé avec alias corrects
- [x] MessageListResponse créé avec pagination

### Routes Conversations
- [x] POST /v1/trips/{tripId}/conversations implémenté
- [x] GET /v1/trips/{tripId}/conversations implémenté
- [x] GET /v1/conversations/{conversationId} implémenté
- [x] Validation ownership dans tous les endpoints
- [x] Gestion d'erreurs cohérente

### Routes Messages
- [x] GET /v1/conversations/{conversationId}/messages implémenté
- [x] Pagination fonctionnelle (limit, offset, total)
- [x] Tri chronologique correct (created_at ASC)
- [x] Validation ownership (via conversation)
- [x] Validation des paramètres de pagination

### Intégration
- [x] Routers enregistrés dans main.py
- [x] Endpoints accessibles et fonctionnels
- [x] Documentation Swagger générée correctement
- [x] Pas de conflits de routes

### Tests
- [ ] Test manuel : créer conversation
- [ ] Test manuel : lister conversations
- [ ] Test manuel : récupérer conversation
- [ ] Test manuel : récupérer messages avec pagination
- [ ] Test erreurs : trip inexistant
- [ ] Test erreurs : conversation inexistante
- [ ] Test erreurs : ownership (autre utilisateur)

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 2.1** : Créer schémas conversations
2. **Tâche 2.3** : Créer __init__.py conversations
3. **Tâche 2.2** : Créer routes conversations
4. **Tâche 2.4** : Créer schémas messages
5. **Tâche 2.6** : Créer __init__.py messages
6. **Tâche 2.5** : Créer routes messages
7. **Tâche 2.7** : Intégrer routers dans main.py
8. **Tâche 2.8** : Tests manuels (optionnel)

---

## 📝 Notes importantes

### Structure des routes

**Option 1 (recommandée)** : Deux routers séparés
- `conversations_router` : préfixe `/v1/trips/{tripId}/conversations` pour POST et GET list
- `conversations_detail_router` : préfixe `/v1/conversations` pour GET detail

**Option 2** : Un seul router avec gestion manuelle
- Router avec préfixe `/v1/trips/{tripId}/conversations`
- Route séparée pour GET `/v1/conversations/{conversationId}` sans préfixe

### Pagination

- **Limit** : Maximum 100, minimum 1, défaut 20
- **Offset** : Minimum 0, défaut 0
- **Total** : Retourné dans la réponse pour permettre la pagination côté client
- **Tri** : Toujours par `created_at ASC` (chronologique)

### Mapping camelCase ↔ snake_case

- Les schémas de réponse utilisent `Field(alias=...)` pour mapper les noms de colonnes DB (snake_case) vers les noms d'API (camelCase)
- Configuration `populate_by_name = True` permet les deux formats

### Dépendances

- **Epic 1 requis** : Les services ConversationService, MessageService doivent être implémentés
- Les modèles Conversation, Message doivent exister

---

## 🔗 Liens avec les épics suivants

- **Epic 3** : Utilisera les endpoints de conversations pour créer des conversations depuis l'agent
- **Epic 6** : Client utilisera ces endpoints pour afficher l'historique des conversations et messages
- **Epic 4** : Client utilisera ces endpoints pour gérer les conversations

---

## 📚 Références

- Pattern de routes : `api/src/api/trips/routes.py`
- Pattern de schémas : `api/src/api/trips/schemas.py`
- Middleware auth : `api/src/api/auth/middleware.py`
- Gestion d'erreurs : `api/src/utils/errors.py`
- Services : `api/src/services/conversation_service.py`, `message_service.py`

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Implémenté
