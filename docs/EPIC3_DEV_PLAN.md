# Epic 3: Agent Enhancement - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Améliorer l'agent LangChain avec de nouveaux tools, la gestion du contexte, et améliorer l'endpoint de chat avec support SSE complet pour permettre une interaction fluide entre l'agent IA et le client.

**Durée estimée** : 3-4 jours de développement

**Dépendances** : Epic 1 (modèles Conversation, Message, Context et services associés), Epic 2 (endpoints conversations/messages)

**Livrables** :
- 3 nouveaux tools agent (flights, hotels, offers)
- Endpoint agent amélioré avec support SSE complet
- Endpoint actions pour les widgets
- Mise à jour du graph LangChain
- Gestion du contexte avec versioning
- Tests manuels des flux complets

**Statut** : ✅ **IMPLÉMENTÉ**

---

## 🎯 Objectifs détaillés

1. **Agent Tools** : Créer les tools pour rechercher des vols, hôtels et gérer les offres
2. **Agent Chat amélioré** : Modifier l'endpoint pour supporter trip_id, conversation_id, context_version
3. **SSE Streaming** : Implémenter les événements SSE (message.delta, message.final, context.updated, tool.start/end, error)
4. **Gestion du contexte** : Intégrer ContextService pour mettre à jour le contexte à chaque interaction
5. **Actions rapides** : Créer l'endpoint pour gérer les actions des widgets (SELECT/BOOK)
6. **Mise à jour du graph** : Ajouter les nouveaux tools au graph LangChain

---

## 📦 Structure des tâches

### Tâche 3.1 : Créer le tool de recherche de vols
**Fichier** : `api/src/agent/tools/flights.py`

**Spécifications** :

```python
def search_flights_tool(
    origin: str,
    destination: str,
    departure_date: str,
    return_date: str | None = None,
    adults: int = 1,
    children: int = 0,
    trip_id: UUID | None = None,
    user_id: UUID | None = None,
) -> dict:
    """
    Rechercher des vols disponibles.
    - Utilise FlightSearchService.create_search()
    - Persiste la recherche en DB
    - Retourne liste d'offres avec IDs
    - Format de retour :
      {
        "offers": [
          {
            "id": "...",
            "amadeus_offer_id": "...",
            "price": 189.0,
            "currency": "EUR",
            "origin": "CDG",
            "destination": "FCO",
            "departure_date": "2024-06-15",
            ...
          }
        ],
        "search_id": "..."
      }
    """
```

**Intégration** :
- Utilise `FlightSearchService` existant
- Utilise `AmadeusClient` pour la recherche
- Persiste les offres en DB automatiquement

**Critères d'acceptation** :
- ✅ Tool créé selon le pattern LangChain
- ✅ Utilise FlightSearchService.create_search()
- ✅ Retourne format standardisé avec IDs
- ✅ Gestion d'erreurs (timeout, API errors)
- ✅ Logs appropriés

**Estimation** : 2h

---

### Tâche 3.2 : Créer le tool de recherche d'hôtels
**Fichier** : `api/src/agent/tools/hotels.py`

**Spécifications** :

```python
def search_hotels_tool(
    city_code: str,
    check_in: str,
    check_out: str,
    adults: int = 1,
    children: int = 0,
    trip_id: UUID | None = None,
    user_id: UUID | None = None,
) -> dict:
    """
    Rechercher des hôtels disponibles.
    - Utilise HotelSearchService.create_search()
    - Persiste la recherche en DB
    - Retourne liste d'offres avec IDs
    - Format de retour similaire à search_flights_tool
    """
```

**Intégration** :
- Utilise `HotelSearchService` existant
- Utilise `AmadeusClient` pour la recherche
- Persiste les offres en DB automatiquement

**Critères d'acceptation** :
- ✅ Tool créé selon le pattern LangChain
- ✅ Utilise HotelSearchService.create_search()
- ✅ Retourne format standardisé avec IDs
- ✅ Gestion d'erreurs
- ✅ Logs appropriés

**Estimation** : 2h

---

### Tâche 3.3 : Créer les tools de gestion d'offres
**Fichier** : `api/src/agent/tools/offers.py`

**Spécifications** :

```python
def select_offer_tool(
    offer_id: str,
    offer_type: str,  # "flight" | "hotel"
    trip_id: UUID | None = None,
    user_id: UUID | None = None,
) -> dict:
    """
    Sélectionner une offre (flight ou hotel).
    - Met à jour context.state.selected.{flight_offer_id|hotel_offer_id}
    - Retourne success
    """

def book_offer_tool(
    offer_id: str,
    offer_type: str,  # "flight" | "hotel"
    trip_id: UUID | None = None,
    user_id: UUID | None = None,
) -> dict:
    """
    Réserver une offre (POC : stub).
    - Pour le POC, crée un BookingIntent
    - Retourne booking_intent_id
    - Dans le futur, déclenchera le vrai processus de booking
    """
```

**Intégration** :
- Utilise `ContextService` pour mettre à jour le contexte
- Utilise `BookingIntentService` pour créer les intentions de réservation

**Critères d'acceptation** :
- ✅ select_offer_tool met à jour context.state.selected
- ✅ book_offer_tool crée un BookingIntent (stub)
- ✅ Validation des paramètres (offer_type, offer_id)
- ✅ Gestion d'erreurs

**Estimation** : 2h

---

### Tâche 3.4 : Mettre à jour AgentState
**Fichier** : `api/src/agent/state.py`

**Modifications** :
- Ajouter `trip_id: UUID | None = None`
- Ajouter `conversation_id: UUID | None = None`
- Ajouter `context_version: int | None = None`

**Critères d'acceptation** :
- ✅ AgentState mis à jour avec nouveaux champs
- ✅ Compatibilité avec le code existant
- ✅ Types corrects

**Estimation** : 30 minutes

---

### Tâche 3.5 : Mettre à jour le graph LangChain
**Fichier** : `api/src/agent/graph.py`

**Modifications** :
- Importer les nouveaux tools (flights, hotels, offers)
- Ajouter les tools au graph
- Configurer les tools avec les bons paramètres

**Code à ajouter** :
```python
from src.agent.tools.flights import search_flights_tool
from src.agent.tools.hotels import search_hotels_tool
from src.agent.tools.offers import select_offer_tool, book_offer_tool

# Dans la configuration du graph
tools = [
    search_locations_by_keyword_tool,
    search_location_by_id_tool,
    search_location_nearest_tool,
    search_flights_tool,  # NOUVEAU
    search_hotels_tool,   # NOUVEAU
    select_offer_tool,    # NOUVEAU
    book_offer_tool,      # NOUVEAU
]
```

**Critères d'acceptation** :
- ✅ Tous les nouveaux tools ajoutés au graph
- ✅ Tools fonctionnels dans le graph
- ✅ Pas de régression sur les tools existants

**Estimation** : 1h

---

### Tâche 3.6 : Créer les schémas pour l'agent
**Fichier** : `api/src/api/agent/schemas.py` (créer ou modifier)

**Schémas à créer** :

```python
class ChatRequest(BaseModel):
    """Requête de chat avec l'agent."""
    trip_id: UUID
    conversation_id: UUID
    message: str
    context_version: int | None = None

class ActionRequest(BaseModel):
    """Requête d'action rapide."""
    trip_id: UUID
    conversation_id: UUID
    action: dict  # {"type": "SELECT_FLIGHT", "offer_id": "..."}
    context_version: int | None = None

class SSEEvent(BaseModel):
    """Événement SSE."""
    event: str  # "message.delta", "message.final", "context.updated", etc.
    data: dict
```

**Critères d'acceptation** :
- ✅ Schémas créés selon le pattern existant
- ✅ Validation des types (UUID, str, int)
- ✅ Support optionnel pour context_version

**Estimation** : 30 minutes

---

### Tâche 3.7 : Modifier l'endpoint agent chat
**Fichier** : `api/src/api/agent/routes.py`

**Modifications** :

#### 1. Modifier le schéma de requête
- Ajouter `trip_id`, `conversation_id`, `context_version` à `ChatRequest`

#### 2. Modifier la fonction `chat_endpoint`
```python
@router.post("/agent/chat")
async def chat_endpoint(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint de chat avec l'agent (SSE streaming).
    
    Flux :
    1. Valider auth (déjà fait via middleware)
    2. Valider trip/conversation ownership
    3. Charger context (dernier) via ContextService.get_context()
    4. Charger N derniers messages (ex 20) via MessageService
    5. Vérifier context_version (si mismatch → erreur)
    6. Exécuter agent en streaming SSE
    7. À chaque tool call :
       - Appeler le tool
       - Mettre à jour context.state + context.ui via ContextService
       - Émettre context.updated via SSE
    8. À la fin :
       - Persister message user via MessageService
       - Persister message assistant via MessageService
       - Persister context version++ via ContextService
    """
```

**Événements SSE à émettre** :
- `message.delta` : tokens texte en streaming
- `message.final` : message final + message_id
- `context.updated` : snapshot context complet (version, state, ui)
- `tool.start` : notification début tool
- `tool.end` : notification fin tool
- `error` : erreurs

**Critères d'acceptation** :
- ✅ Endpoint modifié avec nouveaux paramètres
- ✅ Validation ownership trip/conversation
- ✅ Chargement context et messages
- ✅ Vérification context_version (optimistic locking)
- ✅ Émission événements SSE corrects
- ✅ Persistance messages et context
- ✅ Gestion d'erreurs complète

**Estimation** : 4h

---

### Tâche 3.8 : Créer l'endpoint actions
**Fichier** : `api/src/api/agent/routes.py`

**Spécifications** :

```python
@router.post("/agent/actions")
async def agent_actions(
    request: ActionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Endpoint pour les actions rapides des widgets.
    
    Actions supportées :
    - SELECT_FLIGHT : sélectionner un vol
    - BOOK_FLIGHT : réserver un vol
    - SELECT_HOTEL : sélectionner un hôtel
    - BOOK_HOTEL : réserver un hôtel
    
    Flux :
    1. Valider auth
    2. Valider trip/conversation ownership
    3. Vérifier context_version
    4. Exécuter l'action (appeler le tool correspondant)
    5. Mettre à jour le contexte
    6. Retourner réponse JSON (ou SSE si nécessaire)
    """
```

**Gestion d'erreurs** :
- `CONTEXT_VERSION_MISMATCH` : si version ne correspond pas
- `OFFER_NOT_FOUND` : si offer_id n'existe pas
- `UNAUTHORIZED` : si user n'est pas propriétaire

**Critères d'acceptation** :
- ✅ Endpoint créé avec toutes les actions
- ✅ Validation ownership
- ✅ Vérification context_version
- ✅ Appel des tools appropriés
- ✅ Mise à jour du contexte
- ✅ Gestion d'erreurs

**Estimation** : 2h

---

### Tâche 3.9 : Intégrer ContextService dans les tools
**Fichiers** : `api/src/agent/tools/flights.py`, `hotels.py`, `offers.py`

**Modifications** :
- Les tools doivent mettre à jour le contexte après leurs actions
- Utiliser `ContextService.update_context()` pour mettre à jour `state` et `ui`
- Enrichir `context.ui.widgets` avec les offres trouvées

**Exemple pour search_flights_tool** :
```python
# Après avoir récupéré les offres
offers = flight_search_service.get_offers_by_search(search_id)

# Construire les widgets
widgets = [
    {
        "type": "FLIGHT_OFFER_CARD",
        "offer_id": offer.id,
        "title": f"{offer.origin} → {offer.destination}",
        "subtitle": f"À partir de {offer.grand_total} {offer.currency}",
        "actions": [
            {"type": "SELECT_FLIGHT", "label": "Choisir"},
            {"type": "BOOK_FLIGHT", "label": "Réserver"}
        ]
    }
    for offer in offers[:5]  # Limiter à 5 offres
]

# Mettre à jour le contexte
context_service.update_context(
    db=db,
    context_id=context.id,
    state={
        **context.state,
        "stage": "proposing",
        "requirements": {...}
    },
    ui={
        "widgets": widgets,
        "quick_replies": [...]
    },
    current_version=context.version
)
```

**Critères d'acceptation** :
- ✅ Tools mettent à jour le contexte après leurs actions
- ✅ Widgets créés correctement avec les offres
- ✅ State mis à jour (stage, requirements, selected)
- ✅ Gestion des erreurs de versioning

**Estimation** : 2h

---

### Tâche 3.10 : Implémenter le format SSE
**Fichier** : `api/src/api/agent/routes.py`

**Spécifications** :

Créer des fonctions helper pour émettre les événements SSE :

```python
async def emit_sse_event(
    event_type: str,
    data: dict,
    response: StreamingResponse
):
    """Émettre un événement SSE."""
    event_data = json.dumps(data)
    await response.write(f"event: {event_type}\n")
    await response.write(f"data: {event_data}\n\n")

# Utilisation dans chat_endpoint
async def chat_endpoint(...):
    async def event_generator():
        # Émettre message.delta pendant le streaming
        async for chunk in agent_stream:
            await emit_sse_event("message.delta", {"text": chunk}, ...)
        
        # Émettre tool.start
        await emit_sse_event("tool.start", {"tool": "search_flights"}, ...)
        
        # Émettre context.updated
        await emit_sse_event("context.updated", {
            "version": context.version,
            "state": context.state,
            "ui": context.ui
        }, ...)
        
        # Émettre message.final
        await emit_sse_event("message.final", {
            "message_id": message_id,
            "text": full_text
        }, ...)
    
    return StreamingResponse(event_generator(), media_type="text/event-stream")
```

**Critères d'acceptation** :
- ✅ Format SSE standard respecté
- ✅ Tous les événements émis correctement
- ✅ Gestion des erreurs avec event error
- ✅ Headers HTTP corrects (Content-Type: text/event-stream)

**Estimation** : 2h

---

### Tâche 3.11 : Persister les messages dans le chat
**Fichier** : `api/src/api/agent/routes.py`

**Modifications** :
- Avant d'exécuter l'agent : persister le message user via `MessageService.create_message()`
- Après la réponse de l'agent : persister le message assistant via `MessageService.create_message()`
- Inclure les tool calls dans `message_metadata` si nécessaire

**Code à ajouter** :
```python
# Persister message user
user_message = message_service.create_message(
    db=db,
    conversation_id=conversation_id,
    role="user",
    content=request.message
)

# ... exécution agent ...

# Persister message assistant
assistant_message = message_service.create_message(
    db=db,
    conversation_id=conversation_id,
    role="assistant",
    content=full_response_text,
    message_metadata={
        "tool_calls": [...],
        "context_version": new_context_version
    }
)
```

**Critères d'acceptation** :
- ✅ Message user persisté avant l'exécution
- ✅ Message assistant persisté après la réponse
- ✅ Metadata incluse si nécessaire
- ✅ Gestion d'erreurs

**Estimation** : 1h

---

### Tâche 3.12 : Tests manuels (optionnel mais recommandé)
**Fichiers** : Documentation ou script de test

**Tests à effectuer** :

1. **Chat avec recherche de vols** :
   ```bash
   POST /v1/agent/chat
   Body: {
     "trip_id": "...",
     "conversation_id": "...",
     "message": "Je veux aller de Paris à Rome le 15 juin",
     "context_version": null
   }
   ```
   - ✅ Vérifier événements SSE (message.delta, tool.start, context.updated, message.final)
   - ✅ Vérifier que les offres sont dans context.ui.widgets
   - ✅ Vérifier que les messages sont persistés

2. **Action SELECT_FLIGHT** :
   ```bash
   POST /v1/agent/actions
   Body: {
     "trip_id": "...",
     "conversation_id": "...",
     "action": {"type": "SELECT_FLIGHT", "offer_id": "..."},
     "context_version": 5
   }
   ```
   - ✅ Vérifier que context.state.selected.flight_offer_id est mis à jour
   - ✅ Vérifier que la version est incrémentée

3. **Test context_version mismatch** :
   - ✅ Envoyer context_version incorrect → erreur "stale context, refresh"

4. **Test ownership** :
   - ✅ Tester avec trip/conversation d'un autre utilisateur → erreur 403/404

**Critères d'acceptation** :
- ✅ Tous les flux testés manuellement
- ✅ Cas d'erreur testés
- ✅ Validation ownership testée
- ✅ Versioning testé

**Estimation** : 2h (optionnel)

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
api/src/agent/tools/
  ├── flights.py              [NOUVEAU]
  ├── hotels.py               [NOUVEAU]
  └── offers.py               [NOUVEAU]

api/src/api/agent/
  └── schemas.py              [NOUVEAU ou MODIFIER]
```

### Fichiers à modifier

```
api/src/agent/
  ├── state.py                [MODIFIER - ajouter trip_id, conversation_id, context_version]
  └── graph.py                [MODIFIER - ajouter nouveaux tools]

api/src/api/agent/
  └── routes.py               [MODIFIER - améliorer chat_endpoint, ajouter actions_endpoint]
```

---

## 🗄️ Conception du contexte (state machine légère)

### Champs minimaux (context.state)

```json
{
  "stage": "collecting_requirements | searching | proposing | booking | done",
  "requirements": {
    "from": "...",
    "to": "...",
    "dates": { "start": "...", "end": "..." },
    "budget": "...",
    "preferences": { "hotel": "...", "flight": "..." }
  },
  "selected": {
    "flight_offer_id": null,
    "hotel_offer_id": null
  }
}
```

### Partie UI (context.ui)

```json
{
  "widgets": [
    {
      "type": "FLIGHT_OFFER_CARD",
      "offer_id": "...",
      "title": "Paris → Rome",
      "subtitle": "À partir de 189€",
      "actions": [
        { "type": "SELECT_FLIGHT", "label": "Choisir" },
        { "type": "BOOK_FLIGHT", "label": "Réserver" }
      ]
    },
    {
      "type": "HOTEL_OFFER_CARD",
      "offer_id": "...",
      "title": "Hôtel Central",
      "subtitle": "À partir de 120€/nuit",
      "actions": [
        { "type": "SELECT_HOTEL", "label": "Choisir" },
        { "type": "BOOK_HOTEL", "label": "Réserver" }
      ]
    }
  ],
  "quick_replies": ["Budget max 500€", "Départ vendredi", "Plutôt 4 étoiles"]
}
```

**Pattern** : l'agent écrit surtout dans `state`, et les "tools/services" enrichissent `ui` en fonction des entités (offers).

---

## 📡 Format SSE (simple, standard)

### Événements recommandés

- `message.delta` : tokens texte en streaming
- `message.final` : texte final + message_id
- `context.updated` : snapshot (ou patch) du contexte
- `tool.start` / `tool.end` : notifications d'utilisation d'outils
- `error` : erreurs

### Exemple d'événements

```txt
event: message.delta
data: {"text":"Je te propose ..."}

event: tool.start
data: {"tool":"search_flights"}

event: tool.end
data: {"tool":"search_flights"}

event: context.updated
data: {"version":13,"ui":{"widgets":[...]},"state":{"stage":"proposing"}}

event: message.final
data: {"message_id":"...","text":"Voici 2 vols possibles."}
```

**Best practice POC** : envoyer **1 snapshot complet de `context`** à chaque update (pas de JSON patch), c'est plus simple côté client.

---

## 🔄 Flux de données

### Chat avec l'agent

```
1. Client envoie POST /v1/agent/chat
   Body: { trip_id, conversation_id, message, context_version }

2. API valide auth (get_current_user)
   → Récupère current_user

3. API valide ownership
   → ConversationService.get_conversation_by_id()
   → Vérifie que trip appartient à user

4. API charge le contexte
   → ContextService.get_context(user_id, trip_id, conversation_id)
   → Vérifie context_version (si mismatch → erreur)

5. API charge les messages
   → MessageService.get_messages_by_conversation(conversation_id, limit=20)

6. API persiste le message user
   → MessageService.create_message(role="user", content=message)

7. API exécute l'agent en streaming SSE
   → Émet message.delta pendant le streaming
   → À chaque tool call :
     - Émet tool.start
     - Exécute le tool (ex: search_flights_tool)
     - Met à jour context via ContextService
     - Émet context.updated
     - Émet tool.end

8. API persiste le message assistant
   → MessageService.create_message(role="assistant", content=...)

9. API persiste le contexte mis à jour
   → ContextService.update_context(version++)
```

### Action rapide (widget)

```
1. Client envoie POST /v1/agent/actions
   Body: { trip_id, conversation_id, action: {type, offer_id}, context_version }

2. API valide auth et ownership

3. API vérifie context_version
   → Si mismatch → erreur "stale context, refresh"

4. API exécute l'action
   → Appelle le tool correspondant (select_offer_tool ou book_offer_tool)
   → Met à jour le contexte via ContextService

5. API retourne réponse JSON
   → { "success": true, "context": {...} }
```

---

## 🔒 Sécurité

### Validation ownership

- **Trip/Conversation** : Vérifier que le trip/conversation appartient à l'utilisateur authentifié
- **Context** : Vérifier ownership avant toute modification
- **Offers** : Vérifier que l'offer appartient au trip de l'utilisateur

### Versioning (optimistic locking)

- **Context version** : Vérifier `context_version` dans chaque requête
- **Mismatch** : Si version ne correspond pas → erreur "stale context, refresh"
- **Increment** : Incrémenter version à chaque modification

### Points d'attention

- ✅ Ne jamais exposer les IDs sans vérification d'ownership
- ✅ Utiliser les services pour toutes les vérifications
- ✅ Gérer les erreurs de versioning de manière claire
- ✅ Logs appropriés pour le debugging

---

## ✅ Checklist de validation

### Tools
- [x] search_flights_tool créé et fonctionnel
- [x] search_hotels_tool créé et fonctionnel
- [x] select_offer_tool créé et fonctionnel
- [x] book_offer_tool créé et fonctionnel (stub)
- [x] Tools intégrés dans le graph LangChain
- [x] Tools mettent à jour le contexte correctement

### Agent State
- [x] AgentState mis à jour avec trip_id, conversation_id, context_version
- [x] Compatibilité avec le code existant

### Graph LangChain
- [x] Nouveaux tools ajoutés au graph
- [x] Pas de régression sur les tools existants
- [x] Configuration correcte des tools

### Endpoint Chat
- [x] ChatRequest mis à jour avec nouveaux champs
- [x] Validation ownership trip/conversation
- [x] Chargement context et messages
- [x] Vérification context_version
- [x] Émission événements SSE corrects
- [x] Persistance messages user et assistant
- [x] Persistance context mis à jour
- [x] Gestion d'erreurs complète

### Endpoint Actions
- [x] Endpoint créé avec toutes les actions
- [x] Validation ownership
- [x] Vérification context_version
- [x] Appel des tools appropriés
- [x] Mise à jour du contexte
- [x] Gestion d'erreurs

### SSE
- [x] Format SSE standard respecté
- [x] Tous les événements émis (message.delta, message.final, context.updated, tool.start/end, error)
- [x] Headers HTTP corrects
- [x] Gestion des erreurs avec event error

### Tests
- [ ] Test manuel : chat avec recherche de vols (à tester)
- [ ] Test manuel : chat avec recherche d'hôtels (à tester)
- [ ] Test manuel : action SELECT_FLIGHT (à tester)
- [ ] Test manuel : action BOOK_FLIGHT (stub) (à tester)
- [ ] Test erreurs : context_version mismatch (à tester)
- [ ] Test erreurs : ownership (autre utilisateur) (à tester)
- [ ] Test erreurs : offer inexistant (à tester)

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 3.4** : Mettre à jour AgentState
2. **Tâche 3.1** : Créer search_flights_tool
3. **Tâche 3.2** : Créer search_hotels_tool
4. **Tâche 3.3** : Créer select_offer_tool et book_offer_tool
5. **Tâche 3.5** : Mettre à jour le graph LangChain
6. **Tâche 3.6** : Créer les schémas pour l'agent
7. **Tâche 3.9** : Intégrer ContextService dans les tools
8. **Tâche 3.10** : Implémenter le format SSE
9. **Tâche 3.7** : Modifier l'endpoint agent chat
10. **Tâche 3.11** : Persister les messages dans le chat
11. **Tâche 3.8** : Créer l'endpoint actions
12. **Tâche 3.12** : Tests manuels (optionnel)

---

## 📝 Notes importantes

### Adapter layer (Amadeus / hôtels) — ✅ existe déjà

#### Services existants

- ✅ **FlightSearchService** (`api/src/services/flight_search_service.py`) :
  - `create_search()` : recherche + persistance
  - `get_search_by_id()` : récupérer recherche
  - `get_offers_by_search()` : récupérer offres

- ✅ **HotelSearchService** (`api/src/services/hotel_search_service.py`) :
  - `create_search()` : recherche + persistance
  - `get_search_by_id()` : récupérer recherche
  - `get_offers_by_search()` : récupérer offres

#### Intégrations Amadeus

- ✅ **Flights** (`api/src/integrations/amadeus/flights.py`) :
  - `search_flight_offers()` : recherche offres
  - `confirm_flight_price()` : pricing
  - `create_flight_order()` : commande

- ✅ **Hotels** (`api/src/integrations/amadeus/hotels.py`) :
  - `search_hotel_offers()` : recherche offres
  - `book_hotel()` : réservation

✅ Les services normalisent déjà la data, gèrent retries/timeouts, loggent les requêtes.

### Best practices

* **Idempotence** : si le client retry, éviter double création d'offres → hash request/tool params.
* **Versioning** : `context_version` check : si mismatch → renvoyer erreur "stale context, refresh".
* **Timeouts** : ajouter timeouts sur les tool calls pour éviter les blocages.
* **Logs** : logger toutes les actions importantes (tool calls, context updates, erreurs).

### Performance

- **Pagination messages** : Limiter à 20 messages pour l'historique (configurable)
- **Widgets** : Limiter à 5-10 offres par widget pour éviter la surcharge
- **SSE** : Utiliser des buffers pour éviter trop d'événements

### POC simplifications

- **Booking** : Pour le POC, `book_offer_tool` est un stub qui crée un BookingIntent
- **Context snapshot** : Envoyer snapshot complet (pas de JSON patch) pour simplifier
- **1 conversation par trip** : Au départ, extensible plus tard

---

## 🔗 Liens avec les épics suivants

- **Epic 4** : Client utilisera les endpoints agent pour le chat
- **Epic 6** : Client implémentera le client SSE et l'interface de chat
- **Epic 7** : Client implémentera le système de widgets basé sur context.ui
- **Epic 8** : Ajoutera rate limiting, timeouts, et autres améliorations de sécurité

---

## 📚 Références

- Pattern de tools : `api/src/agent/tools/locations.py`
- Pattern de graph : `api/src/agent/graph.py`
- Services : `api/src/services/flight_search_service.py`, `hotel_search_service.py`
- ContextService : `api/src/services/context_service.py`
- MessageService : `api/src/services/message_service.py`
- Gestion d'erreurs : `api/src/utils/errors.py`
- SSE FastAPI : https://fastapi.tiangolo.com/advanced/server-sent-events/

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ Implémenté
