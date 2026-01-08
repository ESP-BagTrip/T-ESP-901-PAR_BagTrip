**Contexte**

* J'ai déjà une API et un client, mais il manque beaucoup d'implémentation.
* Objectif : construire un **POC** de planification de voyage par IA, **simple à développer**, robuste, et aligné avec les bonnes pratiques.

**User story**

1. L'app se lance → l'utilisateur doit **s'authentifier**.
2. Ensuite il choisit :

   * Accéder à l'app (hors scope)
   * **Planifier un voyage IA** (scope)

**Flow "Voyage IA"**

1. L'utilisateur saisit un **nom de voyage**
   → côté API : créer un objet **Trip**
2. L'utilisateur définit les **accompagnants**
   → côté API : créer les **Travelers** (liés au trip)
3. L'utilisateur arrive dans une interface **chat** avec un **agent IA de planification**
   → tous les messages sont envoyés à un endpoint **Agent** de l'API

**Agent & Contexte**

* L'agent est un agent **LangChain** en **SSE**.
* Il utilise des **tools** via une couche **adapter** vers l'API (ex : recherche vols Amadeus, hôtels).
* Chaque réponse agent renvoie :

  * du **texte**
  * un objet **context** (au sens "state machine / context LangChain") qui circule entre client et serveur.
* Selon l'état du `context`, le client peut afficher des **widgets** (cartes vol/hôtel, actions rapides "book", etc.)

**Règles du Context**

* Le `context` est **mis à jour uniquement backend**, puis **persisté en DB**.
* Il est **build "on demand"** par des fonctions appelées par les tools ou services backend.
* Il est lié à : `user_id`, `trip_id`, `conversation_id`.

**Demande**

* Proposer un **plan d'implémentation complet** : architecture, endpoints, schéma DB, contrats SSE, gestion du context, widgets client, et plan de dev par étapes.

---

## État actuel du projet (audit)

### ✅ API - Ce qui existe déjà

#### Modèles de données
- ✅ **User** (`api/src/models/user.py`) : `id`, `email`, `password_hash`, `full_name`, `phone`, `stripe_customer_id`
- ✅ **Trip** (`api/src/models/trip.py`) : `id`, `user_id`, `title`, `origin_iata`, `destination_iata`, `start_date`, `end_date`, `status`
- ✅ **TripTraveler** (`api/src/models/traveler.py`) : `id`, `trip_id`, `first_name`, `last_name`, `date_of_birth`, `gender`, `documents`, `contacts`
- ✅ **FlightOffer** (`api/src/models/flight_offer.py`) : `id`, `flight_search_id`, `trip_id`, `amadeus_offer_id`, `currency`, `grand_total`, `offer_json`
- ✅ **HotelOffer** (`api/src/models/hotel_offer.py`) : `id`, `hotel_search_id`, `trip_id`, `hotel_id`, `offer_id`, `currency`, `total_price`, `offer_json`
- ✅ **FlightSearch** (`api/src/models/flight_search.py`) : recherche de vols persistée
- ✅ **HotelSearch** (`api/src/models/hotel_search.py`) : recherche d'hôtels persistée
- ✅ **BookingIntent** (`api/src/models/booking_intent.py`) : système de réservation orchestré

#### Endpoints API
- ✅ **Auth** (`api/src/api/auth/routes.py`) :
  - `POST /v1/auth/register` → JWT token
  - `POST /v1/auth/login` → JWT token
  - `GET /v1/auth/me` → user info
- ✅ **Trips** (`api/src/api/trips/routes.py`) :
  - `POST /v1/trips` → créer trip
  - `GET /v1/trips` → lister trips
  - `GET /v1/trips/{tripId}` → détail trip
  - `PATCH /v1/trips/{tripId}` → mettre à jour
  - `DELETE /v1/trips/{tripId}` → supprimer
- ✅ **Travelers** (`api/src/api/travelers/routes.py`) :
  - `POST /v1/trips/{tripId}/travelers` → créer traveler
  - `GET /v1/trips/{tripId}/travelers` → lister travelers
  - `PATCH /v1/trips/{tripId}/travelers/{travelerId}` → mettre à jour
  - `DELETE /v1/trips/{tripId}/travelers/{travelerId}` → supprimer
- ✅ **Agent** (`api/src/api/agent/routes.py`) :
  - `POST /v1/agent/chat` → SSE streaming (basique, sans trip/conversation)

#### Services & Intégrations
- ✅ **FlightSearchService** (`api/src/services/flight_search_service.py`) : recherche vols Amadeus + persistance
- ✅ **HotelSearchService** (`api/src/services/hotel_search_service.py`) : recherche hôtels Amadeus + persistance
- ✅ **Amadeus Client** (`api/src/integrations/amadeus/`) :
  - `flights.py` : recherche vols, pricing, orders
  - `hotels.py` : recherche hôtels, booking
  - `locations.py` : recherche locations
- ✅ **Auth Middleware** (`api/src/api/auth/middleware.py`) : JWT validation

#### Agent LangGraph
- ✅ **Agent Graph** (`api/src/agent/graph.py`) : LangGraph avec Gemini 2.5 Flash Lite
- ✅ **Agent State** (`api/src/agent/state.py`) : `AgentState` avec `userid`
- ✅ **Location Tools** (`api/src/agent/tools/locations.py`) :
  - `search_locations_by_keyword_tool`
  - `search_location_by_id_tool`
  - `search_location_nearest_tool`

### ❌ API - Ce qui manque

#### Modèles de données
- ✅ **Conversation** : modèle créé dans `api/src/models/conversation.py` avec relations vers Trip, Message, Context
- ✅ **Message** : modèle créé dans `api/src/models/message.py` avec validation role et support JSON (message_metadata)
- ✅ **Context** : modèle créé dans `api/src/models/context.py` avec versioning et index composites

#### Endpoints API
- ✅ **Conversations** : endpoints créés pour créer/gérer conversations
- ✅ **Messages** : endpoints créés pour récupérer l'historique
- ✅ **Agent amélioré** : l'endpoint `/v1/agent/chat` prend maintenant `trip_id`, `conversation_id`, `context_version` avec SSE complet
- ✅ **Agent Actions** : endpoint `POST /v1/agent/actions` créé pour les actions rapides

#### Agent Tools
- ✅ **Flight Search Tool** : outil agent créé pour rechercher des vols (`api/src/agent/tools/flights.py`)
- ✅ **Hotel Search Tool** : outil agent créé pour rechercher des hôtels (`api/src/agent/tools/hotels.py`)
- ✅ **Select Offer Tool** : outil créé pour sélectionner une offre (`api/src/agent/tools/offers.py`)
- ✅ **Book Offer Tool** : outil créé pour réserver une offre (stub POC) (`api/src/agent/tools/offers.py`)
- ✅ **Context Management** : ContextService créé pour gérer le contexte (state + UI) avec versioning

#### Services
- ✅ **ConversationService** : service créé dans `api/src/services/conversation_service.py` avec create, get_by_id, get_by_trip
- ✅ **MessageService** : service créé dans `api/src/services/message_service.py` avec create, get_by_conversation (pagination), count
- ✅ **ContextService** : service créé dans `api/src/services/context_service.py` avec get, create, update (versioning), increment_version et optimistic locking

### ✅ Bagtrip (Flutter) - Ce qui existe déjà

#### Architecture
- ✅ **Navigation** (`bagtrip/lib/navigation/`) : système de tabs (Home, Map, Budget, Profile)
- ✅ **BLoC Pattern** : utilisation de flutter_bloc pour state management
- ✅ **HomeFlightBloc** (`bagtrip/lib/home/bloc/home_flight_bloc.dart`) : recherche de vols
- ✅ **LocationService** (`bagtrip/lib/service/LocationService.dart`) : client API basique avec Dio

#### UI
- ✅ **Home Page** (`bagtrip/lib/pages/home_page.dart`) : interface de recherche de vols
- ✅ **Tab Navigation** : 4 tabs fonctionnelles

### ❌ Bagtrip (Flutter) - Ce qui manque

#### Authentification
- ❌ **Auth Service** : pas de service pour login/register
- ❌ **Auth Storage** : pas de stockage du token JWT
- ❌ **Auth Middleware** : pas d'intercepteur Dio pour ajouter le token
- ❌ **Login Screen** : pas d'écran de connexion

#### Trip Management
- ✅ **Trip Service** : service créé pour créer/gérer trips (Epic 4)
- ✅ **Traveler Service** : service créé pour gérer travelers (Epic 4)
- ✅ **Conversation Service** : service créé pour gérer conversations (Epic 5)
- ✅ **Create Trip Screen** : écran créé pour créer un trip (Epic 5)
- ✅ **Travelers Screen** : écran créé pour ajouter travelers (Epic 5)

#### Agent Chat
- ✅ **SSE Client** : client SSE implémenté pour le streaming (Epic 6)
- ✅ **Chat Screen** : interface de chat complète avec streaming, widgets, quick replies (Epic 6)
- ✅ **Chat BLoC** : BLoC complet pour gérer le chat, messages, contexte (Epic 6)
- ✅ **Widget Renderer** : système complet pour rendre les widgets (FlightCard, HotelCard, ItinerarySummary, WarningWidget) (Epic 7)
- ✅ **Context State Management** : gestion du contexte backend avec versioning (Epic 6)

#### API Client
- ❌ **API Base URL Config** : hardcodé dans LocationService
- ❌ **Error Handling** : pas de gestion d'erreurs centralisée
- ❌ **API Service Layer** : LocationService est trop spécifique

---

## Hypothèses POC (pour aller vite, sans se piéger)

* **Un seul agent** "travel-planner".
* Une **conversation par trip** (au départ), extensible plus tard.
* Le `context` = **state minimal** + **UI intents** (widgets) + quelques IDs (flight_offer_id, hotel_offer_id…).
* Le client est "stupid UI" : il n'invente pas d'état métier, il **rend** ce que le backend envoie.

---

# Plan d'implémentation par épics

---

## Epic 1: Core Data Models & Services (API)

### Objectif
Créer les modèles de données et services de base nécessaires pour gérer les conversations, messages et contexte.

### Modèles de données (DB) — à créer

#### Tables à créer

**conversations**

```python
# api/src/models/conversation.py
class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(UUID, primary_key=True)
    trip_id = Column(UUID, ForeignKey("trips.id"), nullable=False, index=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

**messages**

```python
# api/src/models/message.py
class Message(Base):
    __tablename__ = "messages"

    id = Column(UUID, primary_key=True)
    conversation_id = Column(UUID, ForeignKey("conversations.id"), nullable=False, index=True)
    role = Column(String, nullable=False)  # user | assistant | tool
    content = Column(Text, nullable=False)
    message_metadata = Column(JSON, nullable=True)  # tool calls, offer_ids, etc. (renommé de metadata car réservé par SQLAlchemy)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
```

**contexts**

```python
# api/src/models/context.py
class Context(Base):
    __tablename__ = "contexts"

    id = Column(UUID, primary_key=True)
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False, index=True)
    trip_id = Column(UUID, ForeignKey("trips.id"), nullable=False, index=True)
    conversation_id = Column(UUID, ForeignKey("conversations.id"), nullable=False, index=True)
    version = Column(Integer, nullable=False, default=1)  # IMPORTANT pour versioning
    state = Column(JSON, nullable=False)  # LangChain state machine
    ui = Column(JSON, nullable=False)  # Widgets et actions UI
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

#### Tables existantes à utiliser

- ✅ **users** : déjà existant
- ✅ **trips** : déjà existant (ajouter relation vers conversations si besoin)
- ✅ **travelers** : déjà existant
- ✅ **flight_offers** : déjà existant (utilisé pour référencer dans context.ui)
- ✅ **hotel_offers** : déjà existant (utilisé pour référencer dans context.ui)

### Services à créer

**Fichier** : `api/src/services/conversation_service.py`

- ✅ `create_conversation(db, trip_id, user_id, title=None) -> Conversation`
- ✅ `get_conversation_by_id(db, conversation_id, user_id) -> Conversation | None`
- ✅ `get_conversations_by_trip(db, trip_id, user_id) -> list[Conversation]`

**Fichier** : `api/src/services/message_service.py`

- ✅ `create_message(db, conversation_id, role, content, message_metadata=None) -> Message`
- ✅ `get_messages_by_conversation(db, conversation_id, limit=20, offset=0) -> list[Message]`
- ✅ `get_message_count_by_conversation(db, conversation_id) -> int`

**Fichier** : `api/src/services/context_service.py`

- ✅ `get_context(db, user_id, trip_id, conversation_id) -> Context | None`
- ✅ `create_context(db, user_id, trip_id, conversation_id, state, ui) -> Context`
- ✅ `update_context(db, context_id, state, ui, current_version) -> Context`
- ✅ `increment_context_version(db, context_id) -> int`

### Fichiers à créer/modifier

**Modèles** :
- ✅ `api/src/models/conversation.py` (créé)
- ✅ `api/src/models/message.py` (créé - note: `metadata` renommé en `message_metadata`)
- ✅ `api/src/models/context.py` (créé)

**Services** :
- ✅ `api/src/services/conversation_service.py` (créé)
- ✅ `api/src/services/message_service.py` (créé)
- ✅ `api/src/services/context_service.py` (créé)

**Migration DB** :
- ✅ `api/src/migrations/migrate_conversation_tables.py` (créé - idempotent)
- ✅ Intégration dans `api/src/main.py` (lifespan)

---

## Epic 2: Conversation & Message Management API

### Objectif
Créer les endpoints API pour gérer les conversations et récupérer l'historique des messages.

**Statut** : ✅ **Implémenté**

### Endpoints créés

#### Conversations

**Fichier** : `api/src/api/conversations/routes.py`

- ✅ `POST /v1/trips/{tripId}/conversations` → créer conversation
  - Body: `{ "title": "..." }` (optionnel)
  - Response: `{ "conversation": {...} }`
- ✅ `GET /v1/trips/{tripId}/conversations` → lister conversations d'un trip
- ✅ `GET /v1/conversations/{conversationId}` → détail conversation

#### Messages

**Fichier** : `api/src/api/messages/routes.py`

- ✅ `GET /v1/conversations/{conversationId}/messages` → récupérer historique
  - Query params: `?limit=20&offset=0`
  - Response: `{ "items": [...], "total": N, "limit": 20, "offset": 0 }`

### Fichiers créés

**Routes** :
- ✅ `api/src/api/conversations/routes.py` (créé)
- ✅ `api/src/api/messages/routes.py` (créé)

**Schémas** :
- ✅ `api/src/api/conversations/schemas.py` (créé)
- ✅ `api/src/api/messages/schemas.py` (créé)

**Modules** :
- ✅ `api/src/api/conversations/__init__.py` (créé)
- ✅ `api/src/api/messages/__init__.py` (créé)

**Intégration** :
- ✅ Routers enregistrés dans `api/src/main.py`

### Sécurité

- ✅ RBAC minimal : user ne peut accéder qu'à ses trips/convs (vérifié dans chaque endpoint via services)

---

## Epic 3: Agent Enhancement

### Objectif
Améliorer l'agent LangChain avec de nouveaux tools, la gestion du contexte, et améliorer l'endpoint de chat avec support SSE complet.

### Conception du `context` (state machine légère)

#### Champs minimaux (context.state)

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

#### Partie UI (context.ui)

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

✅ Pattern : l'agent écrit surtout dans `state`, et les "tools/services" enrichissent `ui` en fonction des entités (offers).

### Format SSE (simple, standard)

Événements recommandés :

* `message.delta` : tokens texte en streaming
* `message.final` : texte final + message_id
* `context.updated` : snapshot (ou patch) du contexte
* `tool.start` / `tool.end` : notifications d'utilisation d'outils
* `error`

Exemple d'événements :

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

✅ Best practice POC : envoyer **1 snapshot complet de `context`** à chaque update (pas de JSON patch), c'est plus simple côté client.

### Agent Tools — à créer

#### Composants existants

- ✅ **Graph** (`api/src/agent/graph.py`) : LangGraph avec Gemini
- ✅ **State** (`api/src/agent/state.py`) : `AgentState` avec `userid`
- ✅ **Location Tools** (`api/src/agent/tools/locations.py`) : 3 outils de recherche de locations

#### Tools à ajouter

**Fichier** : `api/src/agent/tools/flights.py`

- ✅ `search_flights_tool(requirements) -> offers[]`
  - Utilise `FlightSearchService.create_search()`
  - Retourne liste d'offres avec IDs

**Fichier** : `api/src/agent/tools/hotels.py`

- ✅ `search_hotels_tool(requirements) -> offers[]`
  - Utilise `HotelSearchService.create_search()`
  - Retourne liste d'offres avec IDs

**Fichier** : `api/src/agent/tools/offers.py`

- ✅ `select_offer_tool(offer_id, offer_type) -> success`
  - Met à jour `context.state.selected`
- ✅ `book_offer_tool(offer_id, offer_type) -> booking_intent_id` (POC : stub)

### Agent Chat amélioré — à modifier

**Fichier** : `api/src/api/agent/routes.py` (existe mais à modifier)

**Actuel** :
```python
@router.post("/agent/chat")
async def chat_endpoint(request: ChatRequest):
    # request.message: str
    # request.userid: str
    # ❌ Pas de trip_id, conversation_id, context_version
```

**À modifier** :
- ✅ `POST /v1/agent/chat` (SSE stream)
  - Body :
    ```json
    {
      "trip_id": "...",
      "conversation_id": "...",
      "message": "texte user",
      "context_version": 12
    }
    ```
  - Événements SSE :
    - `message.delta` : tokens texte
    - `message.final` : message final + message_id
    - `context.updated` : snapshot context complet
    - `tool.start` / `tool.end` : notifications outils
    - `error` : erreurs

### Boucle de traitement (serveur) — à modifier

**Fichier** : `api/src/api/agent/routes.py` (modifier `chat_endpoint`)

1. ✅ Valider auth (déjà fait via middleware)
2. ✅ Valider trip/conversation ownership
3. ✅ Charger :
   - `context` (dernier) via `ContextService.get_context()`
   - N derniers messages (ex 20) via `MessageService.get_messages_by_conversation()`
4. ✅ Exécuter agent en streaming SSE (déjà fait)
5. ✅ À chaque "tool call" :
   - appeler adapter (FlightSearchService / HotelSearchService)
   - stocker offers en DB (déjà fait par les services)
   - mettre à jour `context.state` + `context.ui` via `ContextService`
   - émettre `context.updated` via SSE
6. ✅ À la fin :
   - persister message assistant via `MessageService`
   - persister context `version++` via `ContextService`

### Actions rapides (widgets) — à créer

**Fichier** : `api/src/api/agent/routes.py` (nouveau endpoint)

- ✅ `POST /v1/agent/actions`
  - Body :
    ```json
    {
      "trip_id": "...",
      "conversation_id": "...",
      "action": {
        "type": "BOOK_FLIGHT" | "SELECT_FLIGHT" | "BOOK_HOTEL" | "SELECT_HOTEL",
        "offer_id": "..."
      },
      "context_version": 12
    }
    ```
  - Response : SSE ou JSON (POC : JSON OK)

### Mise à jour du graph

- ✅ `api/src/agent/graph.py` (modifié)
  - Ajouter nouveaux tools
  - Mettre à jour `AgentState` si besoin (trip_id, conversation_id)

### Fichiers à créer/modifier

**Tools** :
- ✅ `api/src/agent/tools/flights.py` (créé)
- ✅ `api/src/agent/tools/hotels.py` (créé)
- ✅ `api/src/agent/tools/offers.py` (créé)
- ✅ `api/src/agent/graph.py` (modifié)
- ✅ `api/src/agent/state.py` (modifié - ajout trip_id, conversation_id, context_version)

**Routes** :
- ✅ `api/src/api/agent/routes.py` (modifié)
- ✅ `api/src/api/agent/schemas.py` (créé)

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

---

## Epic 4: Client Authentication & Core Infrastructure

### Objectif
Créer l'infrastructure de base côté client : authentification, client API centralisé, et stockage sécurisé.

### Services à créer

**Fichier** : `bagtrip/lib/service/api_client.dart`

- ✅ Client Dio centralisé avec :
  - Base URL configurable
  - Intercepteur pour JWT token
  - Gestion d'erreurs centralisée
  - Timeout configuré

**Fichier** : `bagtrip/lib/service/auth_service.dart`

- ✅ `login(email, password) -> AuthResponse`
- ✅ `register(email, password) -> AuthResponse`
- ✅ `getCurrentUser() -> User | null`
- ✅ `logout()`

**Fichier** : `bagtrip/lib/service/trip_service.dart`

- ✅ `createTrip(title, originIata?, destinationIata?, startDate?, endDate?) -> Trip`
- ✅ `getTrips() -> List<Trip>`
- ✅ `getTripById(tripId) -> Trip`
- ✅ `updateTrip(tripId, updates) -> Trip`
- ✅ `deleteTrip(tripId) -> void`

**Fichier** : `bagtrip/lib/service/traveler_service.dart`

- ✅ `createTraveler(tripId, travelerData) -> Traveler`
- ✅ `getTravelersByTrip(tripId) -> List<Traveler>`
- ✅ `updateTraveler(tripId, travelerId, updates) -> Traveler`
- ✅ `deleteTraveler(tripId, travelerId) -> void`

**Fichier** : `bagtrip/lib/service/agent_service.dart`

- ✅ `chat(tripId, conversationId, message, contextVersion) -> Stream<SSEEvent>` (implémenté via SSEClient dans Epic 6)
- ✅ `action(tripId, conversationId, action, contextVersion) -> ActionResponse`

### Écrans à créer

**Fichier** : `bagtrip/lib/pages/login_page.dart`

- ✅ Formulaire email/password
- ✅ Appel `POST /v1/auth/login`
- ✅ Stockage token JWT (flutter_secure_storage)
- ✅ Navigation vers Home après login
- ✅ Toggle login/register
- ✅ Validation des champs

### Fichiers créés

**Services** :
- ✅ `bagtrip/lib/service/api_client.dart` (créé)
- ✅ `bagtrip/lib/service/auth_service.dart` (créé)
- ✅ `bagtrip/lib/service/storage_service.dart` (créé)
- ✅ `bagtrip/lib/service/trip_service.dart` (créé)
- ✅ `bagtrip/lib/service/traveler_service.dart` (créé)
- ✅ `bagtrip/lib/service/agent_service.dart` (créé)

**Pages** :
- ✅ `bagtrip/lib/pages/login_page.dart` (créé)

**Modèles** :
- ✅ `bagtrip/lib/models/user.dart` (créé)
- ✅ `bagtrip/lib/models/auth_response.dart` (créé)
- ✅ `bagtrip/lib/models/trip.dart` (créé)
- ✅ `bagtrip/lib/models/traveler.dart` (créé)

**Intégration** :
- ✅ `bagtrip/lib/navigation/app_router.dart` (modifié - ajout route /login et redirect auth)
- ✅ `bagtrip/pubspec.yaml` (modifié - ajout flutter_secure_storage)

---

## Epic 5: Client Trip & Traveler Management

### Objectif
Créer les écrans et la logique pour gérer les trips et travelers côté client.

### Écrans à créer

**Fichier** : `bagtrip/lib/pages/home_page.dart` (modifier)

- ✅ Existe déjà
- ✅ Ajouter bouton "Planifier un voyage IA"

**Fichier** : `bagtrip/lib/pages/create_trip_page.dart`

- ✅ Formulaire nom du trip
- ✅ Appel `POST /v1/trips`
- ✅ Navigation vers Travelers Screen

**Fichier** : `bagtrip/lib/pages/travelers_page.dart`

- ✅ Liste travelers
- ✅ Formulaire ajout traveler
- ✅ Appel `POST /v1/trips/{id}/travelers`
- ✅ Navigation vers Chat Screen

### Fichiers à créer

**Pages** :
- ✅ `bagtrip/lib/pages/home_page.dart` (modifier)
- ✅ `bagtrip/lib/pages/create_trip_page.dart` (nouveau)
- ✅ `bagtrip/lib/pages/travelers_page.dart` (nouveau)

**Modèles** :
- ✅ `bagtrip/lib/models/conversation.dart` (nouveau)

**Services** :
- ✅ `bagtrip/lib/service/conversation_service.dart` (nouveau)

**BLoC (optionnel)** :
- ⚠️ `bagtrip/lib/trip/bloc/trip_bloc.dart` (non implémenté - optionnel, services suffisent)
- ⚠️ `bagtrip/lib/traveler/bloc/traveler_bloc.dart` (non implémenté - optionnel, services suffisent)

---

## Epic 6: Client Chat Interface ✅

### Objectif
Créer l'interface de chat avec support SSE, gestion des messages, et intégration avec le contexte backend.

**Statut** : ✅ **IMPLÉMENTÉ** (2026-01-08)

### Client SSE

**Fichier** : `bagtrip/lib/service/sse_client.dart`

- ✅ Client SSE pour Flutter :
  - Utilise `http` avec stream
  - Parse événements SSE ligne par ligne
  - Émet événements typés `Stream<SSEEvent>`
  - Support authentification automatique via `StorageService`

**Fichier** : `bagtrip/lib/chat/models/sse_event.dart`

- ✅ Modèles pour événements :
  - `MessageDeltaEvent` - chunks de texte en streaming
  - `MessageFinalEvent` - message final avec ID
  - `ContextUpdatedEvent` - mise à jour du contexte
  - `ToolStartEvent` / `ToolEndEvent` - indicateurs d'utilisation d'outils
  - `ErrorEvent` - gestion d'erreurs
  - `UnknownEvent` - événements inconnus

### Chat BLoC

**Fichier** : `bagtrip/lib/chat/bloc/chat_bloc.dart`

- ✅ `ChatBloc` :
  - Events : `SendMessage`, `LoadHistory`, `SelectOffer`, `BookOffer`, `UseQuickReply`, `ResetChat`, `ReconnectStream`
  - States : `ChatInitial`, `ChatLoading`, `ChatLoaded`, `ChatError`
  - Gère SSE stream, messages, widgets, context
  - Accumulation de texte en streaming
  - Gestion du versioning du contexte

**Fichier** : `bagtrip/lib/chat/bloc/chat_event.dart`
- ✅ Tous les événements définis avec Equatable

**Fichier** : `bagtrip/lib/chat/bloc/chat_state.dart`
- ✅ Tous les états définis avec `copyWith` pour mises à jour immutables

### Écran Chat

**Fichier** : `bagtrip/lib/pages/chat_page.dart`

- ✅ Zone messages (scrollable) avec bulles user/assistant
- ✅ Zone widgets (cartes horizontales scrollables)
- ✅ Input message avec bouton send
- ✅ Quick replies (chips cliquables)
- ✅ Indicateur de tool actif
- ✅ Affichage d'erreurs
- ✅ Auto-scroll vers le bas
- ✅ Message en streaming en temps réel

### Services

**Fichier** : `bagtrip/lib/service/message_service.dart`
- ✅ Service pour récupérer l'historique des messages
- ✅ Service pour créer des messages
- ✅ Support pagination

### Fichiers créés

**Services** :
- ✅ `bagtrip/lib/service/sse_client.dart`
- ✅ `bagtrip/lib/service/message_service.dart`

**BLoC** :
- ✅ `bagtrip/lib/chat/bloc/chat_bloc.dart`
- ✅ `bagtrip/lib/chat/bloc/chat_event.dart`
- ✅ `bagtrip/lib/chat/bloc/chat_state.dart`

**Modèles** :
- ✅ `bagtrip/lib/chat/models/sse_event.dart`
- ✅ `bagtrip/lib/chat/models/context.dart` (ChatContext, ContextState, ContextUI, WidgetData, WidgetAction)

**Pages** :
- ✅ `bagtrip/lib/pages/chat_page.dart` (complété, remplace le stub)

**Navigation** :
- ✅ Route `/chat` ajoutée dans `bagtrip/lib/navigation/app_router.dart` avec BlocProvider
- ✅ Navigation depuis `TravelersPage` mise à jour pour utiliser le router

---

## Epic 7: Client Widget System

### Objectif
Créer le système de rendu de widgets dynamiques pilotés par le backend.

### Widgets : contrat simple et extensible

#### Types

* `FLIGHT_OFFER_CARD`
* `HOTEL_OFFER_CARD`
* `ITINERARY_SUMMARY`
* `WARNING` (visa, budget, etc.)

#### Payload minimal

```json
{
  "type": "FLIGHT_OFFER_CARD",
  "title": "Paris → Rome",
  "subtitle": "À partir de 189€",
  "data": { "offer_id": "..." },
  "actions": [
    { "type": "SELECT_FLIGHT", "label": "Choisir" },
    { "type": "BOOK_FLIGHT", "label": "Réserver" }
  ]
}
```

### Widget Renderer

**Fichier** : `bagtrip/lib/chat/widgets/widget_renderer.dart`

- ✅ `WidgetRenderer` : widget factory qui rend selon `widget.type`
  - `FLIGHT_OFFER_CARD` → `FlightOfferCard`
  - `HOTEL_OFFER_CARD` → `HotelOfferCard`
  - `ITINERARY_SUMMARY` → `ItinerarySummary`
  - `WARNING` → `WarningWidget`

### Widgets individuels

**Fichiers** : `bagtrip/lib/chat/widgets/`

- ✅ `flight_offer_card.dart`
- ✅ `hotel_offer_card.dart`
- ✅ `itinerary_summary.dart`
- ✅ `warning_widget.dart`

### Intégration dans Chat

- ✅ Rendu dynamique selon `context.ui.widgets`
- ✅ Gestion des actions (SELECT/BOOK)

### Fichiers à créer

**Widgets** :
- ✅ `bagtrip/lib/chat/widgets/widget_renderer.dart` (créé)
- ✅ `bagtrip/lib/chat/widgets/flight_offer_card.dart` (créé)
- ✅ `bagtrip/lib/chat/widgets/hotel_offer_card.dart` (créé)
- ✅ `bagtrip/lib/chat/widgets/itinerary_summary.dart` (créé)
- ✅ `bagtrip/lib/chat/widgets/warning_widget.dart` (créé)

✅ Best practice POC : **rendu 100% driven by backend** : le client n'essaie pas de reconstruire les offres, il lit `offers` via `offer_id` + payload déjà fourni dans `context.ui`.

---

## Epic 8: Security, Hardening & Polish

### Objectif
Ajouter les mesures de sécurité, gestion d'erreurs robuste, et optimisations finales.

### Sécurité

- ✅ Auth : JWT (existe déjà, 365 jours expiration)
- ✅ RBAC minimal : user ne peut accéder qu'à ses trips/convs (implémenté avec helpers)
- ✅ Rate limit soft sur `/agent/chat` (anti spam) : implémenté (10 req/min)

### Gestion du contexte

- ✅ Gestion `context_version` :
  - Vérification dans `chat_endpoint` et `actions_endpoint`
  - Erreur "stale context, refresh" si mismatch (format structuré avec error: "stale_context")

### Idempotence

- ✅ Idempotence basique tool calls :
  - Hash request/tool params pour éviter doubles (IdempotencyCache avec TTL 5min)

### Timeouts & Fallbacks

- ✅ Timeout tool calls + fallback message agent : implémenté (30s timeout sur flights/hotels)

### Logs & Observabilité

- ✅ Logs structurés : existe déjà (`api/src/utils/logger.py`)

### Tests & Intégration

- ✅ Tester flow complet :
  - Login → Create Trip → Add Travelers → Chat → Widgets → Actions
- ✅ Gérer erreurs :
  - Context version mismatch
  - Tool failures
  - Network errors

### Fichiers modifiés

**API** :
- ✅ `api/src/api/agent/routes.py` (rate limit, versioning, RBAC)
- ✅ `api/src/api/conversations/routes.py` (RBAC avec helpers)
- ✅ `api/src/api/messages/routes.py` (RBAC avec helpers)
- ✅ `api/src/agent/tools/flights.py` (idempotence, timeouts)
- ✅ `api/src/agent/tools/hotels.py` (idempotence, timeouts)
- ✅ `api/src/middleware/rate_limit.py` (nouveau)
- ✅ `api/src/utils/idempotency.py` (nouveau)
- ✅ `api/src/utils/timeout.py` (nouveau)
- ✅ `api/tests/integration/test_full_flow.py` (nouveau)

**Client** :
- ✅ `bagtrip/lib/service/api_client.dart` (gestion d'erreurs améliorée)
- ✅ `bagtrip/lib/chat/bloc/chat_bloc.dart` (erreurs réseau, context mismatch, RefreshContext)
- ✅ `bagtrip/lib/chat/bloc/chat_state.dart` (shouldRefreshContext)
- ✅ `bagtrip/lib/chat/bloc/chat_event.dart` (RefreshContext event)

---

## Bonus POC : "keep it simple" décisions

* Pas de patch diff → **snapshot context complet**
* Pas de multi-agent → **1 agent**
* Booking = **stub** (juste changement de state + message de confirmation)
* 1 conversation par trip au début
* UI = widgets pilotés par backend

---

# Plan de dev "opti" par étapes (ordre recommandé)

## Étape 1 — Epic 1: Fondations DB & Services (API)

1. ✅ Auth (login + middleware) — **DÉJÀ FAIT**
2. ✅ Trips + Travelers CRUD minimal — **DÉJÀ FAIT**
3. ✅ **Créer modèles** : `Conversation`, `Message`, `Context`
   - Fichiers : `api/src/models/conversation.py`, `message.py`, `context.py` (TERMINÉ)
   - Migration DB (Alembic ou script)
4. ❌ **Créer services** :
   - `api/src/services/conversation_service.py` (TERMINÉ)
   - `api/src/services/message_service.py` (TERMINÉ)
   - `api/src/services/context_service.py` (TERMINÉ)

## Étape 2 — Epic 2: Endpoints Conversations & Messages (API)

5. ✅ **Créer endpoints conversations** :
   - `api/src/api/conversations/routes.py` (TERMINÉ)
   - `POST /v1/trips/{tripId}/conversations` (TERMINÉ)
   - `GET /v1/trips/{tripId}/conversations` (TERMINÉ)
   - `GET /v1/conversations/{conversationId}` (TERMINÉ)
6. ✅ **Créer endpoints messages** :
   - `api/src/api/messages/routes.py` (TERMINÉ)
   - `GET /v1/conversations/{conversationId}/messages` (TERMINÉ)

## Étape 3 — Epic 3: Agent Tools (API)

7. ✅ **Créer tools agent** :
   - `api/src/agent/tools/flights.py` : `search_flights_tool` (TERMINÉ)
   - `api/src/agent/tools/hotels.py` : `search_hotels_tool` (TERMINÉ)
   - `api/src/agent/tools/offers.py` : `select_offer_tool`, `book_offer_tool` (TERMINÉ)
8. ✅ **Mettre à jour graph** :
   - `api/src/agent/graph.py` : ajouter nouveaux tools (TERMINÉ)
   - Mettre à jour `AgentState` avec trip_id, conversation_id, context_version (TERMINÉ)

## Étape 4 — Epic 3: Agent Chat amélioré (API)

9. ✅ **Modifier endpoint agent** :
   - `api/src/api/agent/routes.py` : modifier `chat_endpoint` (TERMINÉ)
   - Nouveau schema `ChatRequest` avec `trip_id`, `conversation_id`, `context_version` (TERMINÉ)
   - Intégrer `ContextService`, `MessageService`, `ConversationService` (TERMINÉ)
   - Émettre événements SSE : `context.updated`, `message.final`, `message.delta`, `tool.start/end`, `error` (TERMINÉ)
10. ✅ **Créer endpoint actions** :
    - `api/src/api/agent/routes.py` : `POST /v1/agent/actions` (TERMINÉ)
    - Gérer actions SELECT/BOOK (TERMINÉ)

## Étape 5 — Epic 4: Client : Auth & Services (Bagtrip)

11. ✅ **Créer services client** :
    - ✅ `bagtrip/lib/service/api_client.dart` : client Dio centralisé
    - ✅ `bagtrip/lib/service/storage_service.dart` : stockage sécurisé JWT
    - ✅ `bagtrip/lib/service/auth_service.dart` : login/register
    - ✅ `bagtrip/lib/service/trip_service.dart` : CRUD trips
    - ✅ `bagtrip/lib/service/traveler_service.dart` : CRUD travelers
    - ✅ `bagtrip/lib/service/agent_service.dart` : actions (chat géré par SSEClient dans Epic 6)
12. ✅ **Créer écran login** :
    - ✅ `bagtrip/lib/pages/login_page.dart`
    - ✅ Intégrer `AuthService`
    - ✅ Navigation vers Home après login
    - ✅ Toggle login/register
13. ✅ **Créer modèles de données** :
    - ✅ `bagtrip/lib/models/user.dart`
    - ✅ `bagtrip/lib/models/auth_response.dart`
    - ✅ `bagtrip/lib/models/trip.dart`
    - ✅ `bagtrip/lib/models/traveler.dart`
14. ✅ **Intégrer authentification** :
    - ✅ Router avec redirect basé sur auth
    - ✅ Vérification auth au démarrage
    - ✅ Dépendances ajoutées (flutter_secure_storage)

## Étape 6 — Epic 5: Client : Trip & Travelers (Bagtrip)

13. ✅ **Créer modèle Conversation** :
    - `bagtrip/lib/models/conversation.dart`
    - Support camelCase et snake_case
14. ✅ **Créer ConversationService** :
    - `bagtrip/lib/service/conversation_service.dart`
    - createConversation, getConversationsByTrip, getConversationById
15. ✅ **Modifier HomePage** :
    - `bagtrip/lib/home/view/home_content.dart`
    - Ajouter bouton "Planifier un voyage IA"
16. ✅ **Créer écran create trip** :
    - `bagtrip/lib/pages/create_trip_page.dart`
    - Formulaire + `TripService.createTrip()` + création conversation
17. ✅ **Créer écran travelers** :
    - `bagtrip/lib/pages/travelers_page.dart`
    - Liste + formulaire + `TravelerService`

## Étape 7 — Epic 6: Client : Chat SSE (Bagtrip) ✅

15. ✅ **Créer client SSE** :
    - ✅ `bagtrip/lib/service/sse_client.dart` - Client SSE avec parsing ligne par ligne
    - ✅ `bagtrip/lib/chat/models/sse_event.dart` - Tous les modèles d'événements SSE
    - ✅ `bagtrip/lib/chat/models/context.dart` - Modèles de contexte (ChatContext, ContextState, ContextUI, WidgetData, WidgetAction)
16. ✅ **Créer Chat BLoC** :
    - ✅ `bagtrip/lib/chat/bloc/chat_bloc.dart` - BLoC principal avec gestion SSE stream
    - ✅ `bagtrip/lib/chat/bloc/chat_event.dart` - Tous les événements
    - ✅ `bagtrip/lib/chat/bloc/chat_state.dart` - Tous les états avec copyWith
    - ✅ `bagtrip/lib/service/message_service.dart` - Service pour messages
    - Gère SSE stream, messages, context, actions (SELECT/BOOK), quick replies
17. ✅ **Créer écran chat** :
    - ✅ `bagtrip/lib/pages/chat_page.dart` - Interface complète
    - UI messages (bulles user/assistant) + widgets (cartes horizontales) + input + quick replies
    - Streaming en temps réel, auto-scroll, indicateurs de tool actif
    - ✅ Route `/chat` ajoutée dans `app_router.dart` avec BlocProvider

## Étape 8 — Epic 7: Client : Widgets (Bagtrip)

18. ✅ **Créer widgets** :
    - ✅ `bagtrip/lib/chat/widgets/flight_offer_card.dart`
    - ✅ `bagtrip/lib/chat/widgets/hotel_offer_card.dart`
    - ✅ `bagtrip/lib/chat/widgets/itinerary_summary.dart`
    - ✅ `bagtrip/lib/chat/widgets/warning_widget.dart`
    - ✅ `bagtrip/lib/chat/widgets/widget_renderer.dart`
19. ✅ **Intégrer widgets dans chat** :
    - ✅ Rendu dynamique selon `context.ui.widgets`
    - ✅ Gestion des actions (SELECT/BOOK) via `_handleWidgetAction`

## Étape 9 — Epic 8: Intégration & Tests

20. ✅ **Tester flow complet** :
    - Login → Create Trip → Add Travelers → Chat → Widgets → Actions
    - Tests d'intégration créés dans `api/tests/integration/test_full_flow.py`
21. ✅ **Gérer erreurs** :
    - Context version mismatch (géré avec format structuré)
    - Tool failures (timeouts avec fallback)
    - Network errors (gestion centralisée dans ApiClient)

## Étape 10 — Epic 8: Durcissement (API)

22. ✅ **Gestion `context_version`** :
    - Vérification dans `chat_endpoint` et `actions_endpoint`
    - Erreur "stale context, refresh" si mismatch (format avec error: "stale_context")
23. ✅ **Idempotence basique tool calls** :
    - Hash request/tool params pour éviter doubles (IdempotencyCache)
24. ✅ **Rate limit** :
    - Soft limit sur `/v1/agent/chat` (10 req/min, middleware implémenté)
25. ✅ **Timeout tool calls** :
    - Timeout + fallback message agent (30s timeout sur flights/hotels)
26. ✅ **RBAC** :
    - Helpers verify_trip_ownership et verify_conversation_ownership
    - Appliqué sur tous les endpoints conversations, messages, agent
27. ✅ **Gestion d'erreurs client** :
    - ApiClient avec gestion spécifique 409/429
    - ChatBloc avec RefreshContext event

---

## Fichiers clés à modifier/créer

### API

**Modèles** :
- ✅ `api/src/models/conversation.py` (créé)
- ✅ `api/src/models/message.py` (créé)
- ✅ `api/src/models/context.py` (créé)

**Services** :
- ✅ `api/src/services/conversation_service.py` (créé)
- ✅ `api/src/services/message_service.py` (créé)
- ✅ `api/src/services/context_service.py` (créé)

**Routes** :
- ✅ `api/src/api/conversations/routes.py` (créé)
- ✅ `api/src/api/messages/routes.py` (créé)
- ✅ `api/src/api/agent/routes.py` (modifié - chat endpoint amélioré + actions endpoint)
- ✅ `api/src/api/agent/schemas.py` (créé)

**Tools** :
- ✅ `api/src/agent/tools/flights.py` (créé)
- ✅ `api/src/agent/tools/hotels.py` (créé)
- ✅ `api/src/agent/tools/offers.py` (créé)
- ✅ `api/src/agent/graph.py` (modifié - nouveaux tools ajoutés)
- ✅ `api/src/agent/state.py` (modifié - ajout trip_id, conversation_id, context_version)

### Bagtrip

**Services** :
- ✅ `bagtrip/lib/service/api_client.dart` (créé)
- ✅ `bagtrip/lib/service/storage_service.dart` (créé)
- ✅ `bagtrip/lib/service/auth_service.dart` (créé)
- ✅ `bagtrip/lib/service/trip_service.dart` (créé)
- ✅ `bagtrip/lib/service/traveler_service.dart` (créé)
- ✅ `bagtrip/lib/service/agent_service.dart` (créé - action implémenté, chat stub)
- ✅ `bagtrip/lib/service/conversation_service.dart` (créé - Epic 5)
- ✅ `bagtrip/lib/service/sse_client.dart` (créé - Epic 6)
- ✅ `bagtrip/lib/service/message_service.dart` (créé - Epic 6)

**Modèles** :
- ✅ `bagtrip/lib/models/user.dart` (créé)
- ✅ `bagtrip/lib/models/auth_response.dart` (créé)
- ✅ `bagtrip/lib/models/trip.dart` (créé)
- ✅ `bagtrip/lib/models/traveler.dart` (créé)
- ✅ `bagtrip/lib/models/conversation.dart` (créé - Epic 5)

**Pages** :
- ✅ `bagtrip/lib/pages/login_page.dart` (créé)
- ✅ `bagtrip/lib/pages/create_trip_page.dart` (créé - Epic 5)
- ✅ `bagtrip/lib/pages/travelers_page.dart` (créé - Epic 5)
- ✅ `bagtrip/lib/pages/chat_page.dart` (complété - Epic 6)

**BLoC** :
- ✅ `bagtrip/lib/chat/bloc/chat_bloc.dart` (créé - Epic 6)
- ✅ `bagtrip/lib/chat/bloc/chat_event.dart` (créé - Epic 6)
- ✅ `bagtrip/lib/chat/bloc/chat_state.dart` (créé - Epic 6)

**Modèles Chat** :
- ✅ `bagtrip/lib/chat/models/sse_event.dart` (créé - Epic 6)
- ✅ `bagtrip/lib/chat/models/context.dart` (créé - Epic 6)

**Widgets** :
- ✅ `bagtrip/lib/chat/widgets/widget_renderer.dart` (créé - Epic 7)
- ✅ `bagtrip/lib/chat/widgets/flight_offer_card.dart` (créé - Epic 7)
- ✅ `bagtrip/lib/chat/widgets/hotel_offer_card.dart` (créé - Epic 7)
- ✅ `bagtrip/lib/chat/widgets/itinerary_summary.dart` (créé - Epic 7)
- ✅ `bagtrip/lib/chat/widgets/warning_widget.dart` (créé - Epic 7)
