# Epic 8: Security, Hardening & Polish - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Ajouter les mesures de sécurité, gestion d'erreurs robuste, et optimisations finales pour rendre le système production-ready.

**Durée estimée** : 4-5 jours de développement

**Dépendances** : 
- Epic 1-7 (tous les composants doivent être fonctionnels)
- Epic 3 (Agent chat doit être opérationnel)
- Epic 6 (Chat client doit être fonctionnel)

**Livrables** :
- RBAC (Role-Based Access Control) sur tous les endpoints
- Rate limiting sur les endpoints critiques
- Gestion robuste du versioning du contexte
- Idempotence pour les tool calls
- Timeouts et fallbacks pour les outils
- Gestion d'erreurs améliorée côté client et serveur
- Tests d'intégration du flow complet
- Documentation des mesures de sécurité

**Statut** : ✅ **COMPLÉTÉ**

---

## 🎯 Objectifs détaillés

1. **Sécurité** : Implémenter RBAC minimal et rate limiting pour protéger les endpoints
2. **Versioning** : Gérer correctement le versioning du contexte pour éviter les conflits
3. **Idempotence** : Éviter les appels dupliqués aux outils
4. **Robustesse** : Ajouter timeouts et fallbacks pour les opérations longues
5. **Gestion d'erreurs** : Améliorer la gestion d'erreurs côté client et serveur
6. **Tests** : Valider le flow complet de bout en bout
7. **Observabilité** : S'assurer que les logs sont suffisants pour le debugging

---

## 📦 Structure des tâches

### Tâche 8.1 : Implémenter RBAC (Role-Based Access Control)
**Fichiers** : `api/src/api/conversations/routes.py`, `api/src/api/messages/routes.py`, `api/src/api/agent/routes.py`

**Spécifications** :

Vérifier que chaque utilisateur ne peut accéder qu'à ses propres ressources (trips, conversations, messages).

**Fichier** : `api/src/api/conversations/routes.py`

```python
# Ajouter une fonction helper pour vérifier l'ownership
async def verify_trip_ownership(db: Session, trip_id: str, user_id: str) -> Trip:
    """Vérifie que le trip appartient à l'utilisateur."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return trip

async def verify_conversation_ownership(db: Session, conversation_id: str, user_id: str) -> Conversation:
    """Vérifie que la conversation appartient à l'utilisateur."""
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return conversation

# Modifier chaque endpoint pour utiliser ces vérifications
@router.post("/trips/{trip_id}/conversations")
async def create_conversation(
    trip_id: str,
    request: CreateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Vérifier ownership du trip
    trip = await verify_trip_ownership(db, trip_id, current_user.id)
    
    # Créer la conversation
    conversation = conversation_service.create_conversation(
        db, trip_id=trip_id, user_id=current_user.id, title=request.title
    )
    return {"conversation": conversation}

@router.get("/trips/{trip_id}/conversations")
async def get_conversations_by_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Vérifier ownership du trip
    await verify_trip_ownership(db, trip_id, current_user.id)
    
    # Récupérer les conversations
    conversations = conversation_service.get_conversations_by_trip(db, trip_id, current_user.id)
    return {"conversations": conversations}

@router.get("/conversations/{conversation_id}")
async def get_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Vérifier ownership de la conversation
    conversation = await verify_conversation_ownership(db, conversation_id, current_user.id)
    return {"conversation": conversation}
```

**Fichier** : `api/src/api/messages/routes.py`

```python
# Ajouter vérification d'ownership
@router.get("/conversations/{conversation_id}/messages")
async def get_messages(
    conversation_id: str,
    limit: int = 20,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Vérifier ownership de la conversation
    await verify_conversation_ownership(db, conversation_id, current_user.id)
    
    # Récupérer les messages
    messages = message_service.get_messages_by_conversation(
        db, conversation_id, limit=limit, offset=offset
    )
    total = message_service.get_message_count_by_conversation(db, conversation_id)
    
    return {
        "items": messages,
        "total": total,
        "limit": limit,
        "offset": offset,
    }
```

**Fichier** : `api/src/api/agent/routes.py`

```python
# Ajouter vérifications dans chat_endpoint et actions_endpoint
@router.post("/agent/chat")
async def chat_endpoint(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Vérifier ownership du trip
    trip = await verify_trip_ownership(db, request.trip_id, current_user.id)
    
    # Vérifier ownership de la conversation
    conversation = await verify_conversation_ownership(
        db, request.conversation_id, current_user.id
    )
    
    # Vérifier que la conversation appartient au trip
    if conversation.trip_id != request.trip_id:
        raise HTTPException(
            status_code=400, 
            detail="Conversation does not belong to this trip"
        )
    
    # ... reste de l'implémentation
```

**Critères d'acceptation** :
- ✅ Fonction helper `verify_trip_ownership` créée
- ✅ Fonction helper `verify_conversation_ownership` créée
- ✅ Tous les endpoints conversations vérifient l'ownership
- ✅ Tous les endpoints messages vérifient l'ownership
- ✅ Endpoints agent vérifient l'ownership du trip et de la conversation
- ✅ Tests unitaires pour vérifier le refus d'accès non autorisé
- ✅ Retourne 403 (Forbidden) si l'utilisateur n'est pas propriétaire
- ✅ Retourne 404 (Not Found) si la ressource n'existe pas

**Estimation** : 3h

---

### Tâche 8.2 : Implémenter Rate Limiting
**Fichier** : `api/src/api/agent/routes.py`, `api/src/middleware/rate_limit.py` (nouveau)

**Spécifications** :

Implémenter un rate limiting "soft" sur l'endpoint `/v1/agent/chat` pour éviter le spam et protéger les ressources.

**Fichier** : `api/src/middleware/rate_limit.py` (nouveau)

```python
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Dict, Tuple
import time

class RateLimiter:
    """Rate limiter simple basé sur le user_id."""
    
    def __init__(self, max_requests: int = 10, window_seconds: int = 60):
        """
        Args:
            max_requests: Nombre maximum de requêtes par fenêtre
            window_seconds: Durée de la fenêtre en secondes
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: Dict[str, list] = defaultdict(list)
    
    def is_allowed(self, user_id: str) -> Tuple[bool, int]:
        """
        Vérifie si une requête est autorisée.
        
        Returns:
            Tuple[bool, int]: (is_allowed, remaining_requests)
        """
        now = time.time()
        user_requests = self.requests[user_id]
        
        # Nettoyer les requêtes anciennes
        cutoff = now - self.window_seconds
        user_requests[:] = [req_time for req_time in user_requests if req_time > cutoff]
        
        # Vérifier la limite
        if len(user_requests) >= self.max_requests:
            return False, 0
        
        # Ajouter la nouvelle requête
        user_requests.append(now)
        
        remaining = self.max_requests - len(user_requests)
        return True, remaining
    
    def get_retry_after(self, user_id: str) -> int:
        """Retourne le nombre de secondes avant de pouvoir refaire une requête."""
        if not self.requests[user_id]:
            return 0
        
        oldest_request = min(self.requests[user_id])
        window_end = oldest_request + self.window_seconds
        now = time.time()
        
        return max(0, int(window_end - now))

# Instance globale (pour POC, en production utiliser Redis)
agent_chat_rate_limiter = RateLimiter(max_requests=10, window_seconds=60)

async def rate_limit_middleware(request: Request, call_next):
    """Middleware pour appliquer le rate limiting."""
    # Appliquer uniquement sur /agent/chat
    if request.url.path.endswith("/agent/chat") and request.method == "POST":
        # Récupérer user_id depuis le token JWT (déjà validé par auth middleware)
        user_id = request.state.user_id if hasattr(request.state, "user_id") else None
        
        if user_id:
            is_allowed, remaining = agent_chat_rate_limiter.is_allowed(user_id)
            
            if not is_allowed:
                retry_after = agent_chat_rate_limiter.get_retry_after(user_id)
                return JSONResponse(
                    status_code=429,
                    content={
                        "detail": "Rate limit exceeded. Please try again later.",
                        "retry_after": retry_after,
                    },
                    headers={"Retry-After": str(retry_after)},
                )
            
            # Ajouter header avec remaining requests
            response = await call_next(request)
            response.headers["X-RateLimit-Remaining"] = str(remaining)
            response.headers["X-RateLimit-Limit"] = str(agent_chat_rate_limiter.max_requests)
            return response
    
    return await call_next(request)
```

**Fichier** : `api/src/main.py`

```python
# Ajouter le middleware dans l'app FastAPI
from api.middleware.rate_limit import rate_limit_middleware

app = FastAPI(...)

# Ajouter après auth middleware
app.middleware("http")(rate_limit_middleware)
```

**Critères d'acceptation** :
- ✅ RateLimiter créé avec fenêtre glissante
- ✅ Middleware appliqué uniquement sur `/v1/agent/chat`
- ✅ Retourne 429 (Too Many Requests) si limite dépassée
- ✅ Headers `X-RateLimit-Remaining` et `X-RateLimit-Limit` ajoutés
- ✅ Header `Retry-After` dans la réponse 429
- ✅ Nettoyage automatique des anciennes requêtes
- ✅ Tests unitaires pour vérifier le rate limiting

**Estimation** : 2h

---

### Tâche 8.3 : Gestion du versioning du contexte
**Fichier** : `api/src/api/agent/routes.py`, `api/src/services/context_service.py`

**Spécifications** :

Vérifier que le `context_version` envoyé par le client correspond à la version actuelle. Si mismatch, retourner une erreur claire.

**Fichier** : `api/src/api/agent/routes.py`

```python
@router.post("/agent/chat")
async def chat_endpoint(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # ... vérifications ownership ...
    
    # Charger le contexte actuel
    context = context_service.get_context(
        db, 
        user_id=current_user.id,
        trip_id=request.trip_id,
        conversation_id=request.conversation_id
    )
    
    # Vérifier le versioning
    if context and request.context_version:
        if context.version != request.context_version:
            raise HTTPException(
                status_code=409,  # Conflict
                detail={
                    "error": "stale_context",
                    "message": "Context version mismatch. Please refresh and try again.",
                    "current_version": context.version,
                    "client_version": request.context_version,
                }
            )
    
    # ... reste de l'implémentation ...
```

**Fichier** : `api/src/api/agent/routes.py` (actions endpoint)

```python
@router.post("/agent/actions")
async def actions_endpoint(
    request: ActionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # ... vérifications ownership ...
    
    # Charger le contexte actuel
    context = context_service.get_context(
        db,
        user_id=current_user.id,
        trip_id=request.trip_id,
        conversation_id=request.conversation_id
    )
    
    if not context:
        raise HTTPException(status_code=404, detail="Context not found")
    
    # Vérifier le versioning
    if request.context_version and context.version != request.context_version:
        raise HTTPException(
            status_code=409,  # Conflict
            detail={
                "error": "stale_context",
                "message": "Context version mismatch. Please refresh and try again.",
                "current_version": context.version,
                "client_version": request.context_version,
            }
        )
    
    # ... traitement de l'action avec optimistic locking ...
    
    # Mettre à jour le contexte avec versioning
    try:
        updated_context = context_service.update_context(
            db,
            context_id=context.id,
            state=new_state,
            ui=new_ui,
            current_version=context.version,  # Optimistic locking
        )
    except ValueError as e:
        # Version mismatch détecté lors de l'update
        raise HTTPException(
            status_code=409,
            detail={
                "error": "stale_context",
                "message": str(e),
                "current_version": context.version,
            }
        )
    
    # ... retourner la réponse ...
```

**Fichier** : `api/src/services/context_service.py`

```python
def update_context(
    db: Session,
    context_id: str,
    state: dict,
    ui: dict,
    current_version: int,
) -> Context:
    """
    Met à jour le contexte avec optimistic locking.
    
    Raises:
        ValueError: Si la version ne correspond pas (concurrent update)
    """
    context = db.query(Context).filter(Context.id == context_id).first()
    if not context:
        raise ValueError("Context not found")
    
    # Vérifier la version
    if context.version != current_version:
        raise ValueError(
            f"Context version mismatch: expected {current_version}, "
            f"got {context.version}. Another update occurred."
        )
    
    # Mettre à jour
    context.state = state
    context.ui = ui
    context.version += 1
    context.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(context)
    
    return context
```

**Critères d'acceptation** :
- ✅ Vérification de `context_version` dans `chat_endpoint`
- ✅ Vérification de `context_version` dans `actions_endpoint`
- ✅ Retourne 409 (Conflict) avec détails si mismatch
- ✅ Optimistic locking dans `update_context`
- ✅ Message d'erreur clair pour le client
- ✅ Tests unitaires pour vérifier le versioning

**Estimation** : 2h

---

### Tâche 8.4 : Idempotence pour les tool calls
**Fichier** : `api/src/agent/tools/flights.py`, `api/src/agent/tools/hotels.py`, `api/src/agent/tools/offers.py`

**Spécifications** :

Éviter les appels dupliqués aux outils en utilisant un hash des paramètres de requête.

**Fichier** : `api/src/utils/idempotency.py` (nouveau)

```python
import hashlib
import json
from typing import Any, Dict
from datetime import datetime, timedelta
from collections import defaultdict

class IdempotencyCache:
    """Cache simple pour éviter les appels dupliqués."""
    
    def __init__(self, ttl_seconds: int = 300):  # 5 minutes
        self.ttl_seconds = ttl_seconds
        self.cache: Dict[str, Tuple[Any, datetime]] = {}
    
    def _generate_key(self, tool_name: str, params: Dict[str, Any]) -> str:
        """Génère une clé unique basée sur le nom de l'outil et ses paramètres."""
        # Normaliser les paramètres (trier les clés, convertir en JSON)
        normalized = json.dumps(params, sort_keys=True, default=str)
        key_string = f"{tool_name}:{normalized}"
        return hashlib.sha256(key_string.encode()).hexdigest()
    
    def get(self, tool_name: str, params: Dict[str, Any]) -> Any | None:
        """Récupère le résultat d'un appel précédent."""
        key = self._generate_key(tool_name, params)
        
        if key in self.cache:
            result, timestamp = self.cache[key]
            # Vérifier TTL
            if datetime.utcnow() - timestamp < timedelta(seconds=self.ttl_seconds):
                return result
            else:
                # Expiré, supprimer
                del self.cache[key]
        
        return None
    
    def set(self, tool_name: str, params: Dict[str, Any], result: Any):
        """Stocke le résultat d'un appel."""
        key = self._generate_key(tool_name, params)
        self.cache[key] = (result, datetime.utcnow())
        
        # Nettoyer les entrées expirées (simple cleanup)
        self._cleanup()
    
    def _cleanup(self):
        """Nettoie les entrées expirées."""
        now = datetime.utcnow()
        expired_keys = [
            key for key, (_, timestamp) in self.cache.items()
            if now - timestamp >= timedelta(seconds=self.ttl_seconds)
        ]
        for key in expired_keys:
            del self.cache[key]

# Instance globale (pour POC, en production utiliser Redis)
idempotency_cache = IdempotencyCache(ttl_seconds=300)
```

**Fichier** : `api/src/agent/tools/flights.py`

```python
from api.utils.idempotency import idempotency_cache

def search_flights_tool(requirements: dict) -> list:
    """Recherche des vols avec idempotence."""
    # Vérifier le cache
    cached_result = idempotency_cache.get("search_flights", requirements)
    if cached_result is not None:
        logger.info(f"Returning cached result for search_flights")
        return cached_result
    
    # Appel réel
    try:
        result = flight_search_service.create_search(
            origin=requirements.get("origin"),
            destination=requirements.get("destination"),
            departure_date=requirements.get("departure_date"),
            # ... autres paramètres
        )
        
        # Stocker dans le cache
        idempotency_cache.set("search_flights", requirements, result)
        
        return result
    except Exception as e:
        logger.error(f"Error in search_flights_tool: {e}")
        raise
```

**Fichier** : `api/src/agent/tools/hotels.py`

```python
from api.utils.idempotency import idempotency_cache

def search_hotels_tool(requirements: dict) -> list:
    """Recherche des hôtels avec idempotence."""
    # Vérifier le cache
    cached_result = idempotency_cache.get("search_hotels", requirements)
    if cached_result is not None:
        logger.info(f"Returning cached result for search_hotels")
        return cached_result
    
    # Appel réel
    try:
        result = hotel_search_service.create_search(
            city_code=requirements.get("city_code"),
            check_in=requirements.get("check_in"),
            check_out=requirements.get("check_out"),
            # ... autres paramètres
        )
        
        # Stocker dans le cache
        idempotency_cache.set("search_hotels", requirements, result)
        
        return result
    except Exception as e:
        logger.error(f"Error in search_hotels_tool: {e}")
        raise
```

**Critères d'acceptation** :
- ✅ `IdempotencyCache` créé avec TTL
- ✅ Hash des paramètres pour générer une clé unique
- ✅ Cache appliqué sur `search_flights_tool`
- ✅ Cache appliqué sur `search_hotels_tool`
- ✅ Nettoyage automatique des entrées expirées
- ✅ Logs pour les hits de cache
- ✅ Tests unitaires pour vérifier l'idempotence

**Estimation** : 2h

---

### Tâche 8.5 : Timeouts et fallbacks pour les tool calls
**Fichier** : `api/src/agent/tools/flights.py`, `api/src/agent/tools/hotels.py`, `api/src/agent/graph.py`

**Spécifications** :

Ajouter des timeouts sur les appels d'outils et un fallback si l'outil échoue.

**Fichier** : `api/src/utils/timeout.py` (nouveau)

```python
import asyncio
from typing import Callable, Any, Optional
from functools import wraps
import logging

logger = logging.getLogger(__name__)

def with_timeout(timeout_seconds: float, fallback_value: Any = None):
    """
    Décorateur pour ajouter un timeout à une fonction.
    
    Args:
        timeout_seconds: Timeout en secondes
        fallback_value: Valeur à retourner si timeout
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=timeout_seconds
                )
            except asyncio.TimeoutError:
                logger.warning(
                    f"Function {func.__name__} timed out after {timeout_seconds}s"
                )
                return fallback_value
            except Exception as e:
                logger.error(f"Error in {func.__name__}: {e}")
                return fallback_value
        
        return wrapper
    return decorator

def with_timeout_sync(timeout_seconds: float, fallback_value: Any = None):
    """
    Décorateur pour ajouter un timeout à une fonction synchrone.
    Utilise ThreadPoolExecutor pour exécuter dans un thread séparé.
    """
    from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
    
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            executor = ThreadPoolExecutor(max_workers=1)
            future = executor.submit(func, *args, **kwargs)
            
            try:
                result = future.result(timeout=timeout_seconds)
                executor.shutdown(wait=False)
                return result
            except FutureTimeoutError:
                logger.warning(
                    f"Function {func.__name__} timed out after {timeout_seconds}s"
                )
                executor.shutdown(wait=False)
                return fallback_value
            except Exception as e:
                logger.error(f"Error in {func.__name__}: {e}")
                executor.shutdown(wait=False)
                return fallback_value
        
        return wrapper
    return decorator
```

**Fichier** : `api/src/agent/tools/flights.py`

```python
from api.utils.timeout import with_timeout_sync

@with_timeout_sync(timeout_seconds=30.0, fallback_value=[])
def search_flights_tool(requirements: dict) -> list:
    """Recherche des vols avec timeout."""
    # ... implémentation existante ...
    # Si timeout, retourne [] (fallback_value)
```

**Fichier** : `api/src/agent/graph.py`

```python
# Dans la fonction qui appelle les tools, gérer les erreurs
async def execute_tool_with_fallback(tool_name: str, tool_func: Callable, *args, **kwargs):
    """Exécute un outil avec gestion d'erreur et fallback."""
    try:
        result = await tool_func(*args, **kwargs)
        return result
    except Exception as e:
        logger.error(f"Tool {tool_name} failed: {e}")
        # Retourner un message d'erreur pour l'agent
        return {
            "error": True,
            "message": f"Tool {tool_name} encountered an error. Please try again or rephrase your request.",
        }
```

**Critères d'acceptation** :
- ✅ Décorateur `with_timeout` créé pour fonctions async
- ✅ Décorateur `with_timeout_sync` créé pour fonctions sync
- ✅ Timeout appliqué sur `search_flights_tool` (30s)
- ✅ Timeout appliqué sur `search_hotels_tool` (30s)
- ✅ Fallback retourne une valeur par défaut si timeout
- ✅ Logs appropriés pour les timeouts
- ✅ Tests unitaires pour vérifier les timeouts

**Estimation** : 2h

---

### Tâche 8.6 : Améliorer la gestion d'erreurs côté client
**Fichier** : `bagtrip/lib/service/api_client.dart`, `bagtrip/lib/chat/bloc/chat_bloc.dart`

**Spécifications** :

Améliorer la gestion d'erreurs dans le client Flutter pour gérer les erreurs réseau, context mismatch, et autres erreurs serveur.

**Fichier** : `bagtrip/lib/service/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:bagtrip/service/storage_service.dart';

class ApiClient {
  late Dio _dio;
  final StorageService _storageService = StorageService();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8000/v1', // TODO: config
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Intercepteur pour ajouter le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion centralisée des erreurs
          final apiError = _handleError(error);
          return handler.reject(apiError);
        },
      ),
    );
  }

  DioError _handleError(DioException error) {
    // Créer une erreur personnalisée avec message clair
    String message;
    int? statusCode;

    if (error.response != null) {
      statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          message = data['detail'] ?? 'Requête invalide';
          break;
        case 401:
          message = 'Non authentifié. Veuillez vous reconnecter.';
          break;
        case 403:
          message = 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
          break;
        case 404:
          message = 'Ressource non trouvée';
          break;
        case 409:
          // Context version mismatch
          if (data['error'] == 'stale_context') {
            message = 'Le contexte a été mis à jour. Veuillez rafraîchir.';
          } else {
            message = data['detail'] ?? 'Conflit de version';
          }
          break;
        case 429:
          message = 'Trop de requêtes. Veuillez patienter.';
          break;
        case 500:
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
          break;
        default:
          message = data['detail'] ?? 'Une erreur est survenue';
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Timeout. Vérifiez votre connexion internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Erreur de connexion. Vérifiez votre connexion internet.';
    } else {
      message = 'Une erreur inattendue est survenue';
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: message,
    );
  }

  Dio get dio => _dio;
}
```

**Fichier** : `bagtrip/lib/chat/bloc/chat_bloc.dart`

```dart
// Dans le handler de SendMessage
Stream<ChatState> _mapSendMessageToState(
  SendMessage event,
  ChatLoaded state,
) async* {
  try {
    // ... logique existante ...
    
    // Gérer les erreurs spécifiques
    await for (final sseEvent in sseStream) {
      if (sseEvent is ErrorEvent) {
        // Gérer l'erreur selon le type
        if (sseEvent.message.contains('stale_context') ||
            sseEvent.message.contains('Context version mismatch')) {
          yield ChatError(
            message: 'Le contexte a été mis à jour. Veuillez rafraîchir.',
            shouldRefreshContext: true,
          );
        } else {
          yield ChatError(message: sseEvent.message);
        }
        return;
      }
      // ... traitement des autres événements ...
    }
  } on DioException catch (e) {
    // Gérer les erreurs réseau
    String message = e.error?.toString() ?? 'Erreur de connexion';
    
    if (e.response?.statusCode == 409) {
      // Context mismatch
      yield ChatError(
        message: 'Le contexte a été mis à jour. Veuillez rafraîchir.',
        shouldRefreshContext: true,
      );
    } else if (e.response?.statusCode == 429) {
      // Rate limit
      yield ChatError(
        message: 'Trop de requêtes. Veuillez patienter quelques instants.',
      );
    } else {
      yield ChatError(message: message);
    }
  } catch (e) {
    yield ChatError(message: 'Une erreur inattendue est survenue');
  }
}

// Ajouter un event pour rafraîchir le contexte
class RefreshContext extends ChatEvent {
  final String tripId;
  final String conversationId;

  RefreshContext({
    required this.tripId,
    required this.conversationId,
  });
}

// Handler pour RefreshContext
Stream<ChatState> _mapRefreshContextToState(
  RefreshContext event,
  ChatState state,
) async* {
  // Recharger le contexte depuis le backend
  // ... implémentation ...
}
```

**Critères d'acceptation** :
- ✅ Gestion centralisée des erreurs dans `ApiClient`
- ✅ Messages d'erreur clairs et en français
- ✅ Gestion spécifique du code 409 (context mismatch)
- ✅ Gestion spécifique du code 429 (rate limit)
- ✅ Gestion des erreurs réseau (timeout, connection error)
- ✅ Event `RefreshContext` dans ChatBloc
- ✅ Affichage des erreurs dans l'UI
- ✅ Tests pour vérifier la gestion d'erreurs

**Estimation** : 3h

---

### Tâche 8.7 : Tests d'intégration du flow complet
**Fichier** : `api/tests/integration/test_full_flow.py` (nouveau), `bagtrip/integration_test/` (nouveau)

**Spécifications** :

Créer des tests d'intégration pour valider le flow complet : Login → Create Trip → Add Travelers → Chat → Widgets → Actions.

**Fichier** : `api/tests/integration/test_full_flow.py`

```python
import pytest
from fastapi.testclient import TestClient
from api.main import app
from api.models.user import User
from api.models.trip import Trip
from api.models.traveler import TripTraveler
from api.models.conversation import Conversation
from api.models.message import Message
from api.models.context import Context

client = TestClient(app)

@pytest.fixture
def test_user(db):
    """Créer un utilisateur de test."""
    user = User(
        email="test@example.com",
        password_hash="hashed_password",
        full_name="Test User",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@pytest.fixture
def auth_token(test_user):
    """Obtenir un token JWT pour l'utilisateur de test."""
    response = client.post(
        "/v1/auth/login",
        json={"email": test_user.email, "password": "test_password"},
    )
    return response.json()["access_token"]

def test_full_flow(auth_token, db):
    """Test du flow complet."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. Créer un trip
    trip_response = client.post(
        "/v1/trips",
        headers=headers,
        json={"title": "Voyage à Paris"},
    )
    assert trip_response.status_code == 200
    trip_id = trip_response.json()["trip"]["id"]
    
    # 2. Ajouter un traveler
    traveler_response = client.post(
        f"/v1/trips/{trip_id}/travelers",
        headers=headers,
        json={
            "first_name": "John",
            "last_name": "Doe",
            "date_of_birth": "1990-01-01",
            "gender": "M",
        },
    )
    assert traveler_response.status_code == 200
    traveler_id = traveler_response.json()["traveler"]["id"]
    
    # 3. Créer une conversation
    conv_response = client.post(
        f"/v1/trips/{trip_id}/conversations",
        headers=headers,
        json={"title": "Planification"},
    )
    assert conv_response.status_code == 200
    conversation_id = conv_response.json()["conversation"]["id"]
    
    # 4. Envoyer un message au chat
    chat_response = client.post(
        "/v1/agent/chat",
        headers=headers,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Je veux aller à Paris du 1er au 5 janvier",
            "context_version": None,
        },
        stream=True,
    )
    assert chat_response.status_code == 200
    
    # Vérifier les événements SSE
    events = []
    for line in chat_response.iter_lines():
        if line.startswith("event:"):
            event_type = line.split(":")[1].strip()
            events.append(event_type)
    
    assert "message.delta" in events
    assert "message.final" in events
    
    # 5. Vérifier que les messages sont persistés
    messages_response = client.get(
        f"/v1/conversations/{conversation_id}/messages",
        headers=headers,
    )
    assert messages_response.status_code == 200
    messages = messages_response.json()["items"]
    assert len(messages) >= 2  # user message + assistant message
    
    # 6. Vérifier que le contexte est créé
    # (nécessite un endpoint pour récupérer le contexte, ou vérifier en DB)
    # ...

def test_context_version_mismatch(auth_token, db):
    """Test de gestion du context version mismatch."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # Créer trip, conversation, et envoyer un message
    # ... setup ...
    
    # Envoyer un deuxième message avec un context_version incorrect
    chat_response = client.post(
        "/v1/agent/chat",
        headers=headers,
        json={
            "trip_id": trip_id,
            "conversation_id": conversation_id,
            "message": "Quels sont les hôtels disponibles?",
            "context_version": 999,  # Version incorrecte
        },
    )
    
    assert chat_response.status_code == 409
    assert "stale_context" in chat_response.json()["detail"]["error"]

def test_rate_limiting(auth_token):
    """Test du rate limiting."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # Envoyer plus de 10 requêtes rapidement
    responses = []
    for i in range(12):
        response = client.post(
            "/v1/agent/chat",
            headers=headers,
            json={
                "trip_id": trip_id,
                "conversation_id": conversation_id,
                "message": f"Message {i}",
            },
        )
        responses.append(response.status_code)
    
    # Les 10 premières doivent être 200, les 2 suivantes 429
    assert responses[:10].count(200) == 10
    assert 429 in responses[10:]
```

**Critères d'acceptation** :
- ✅ Test du flow complet créé
- ✅ Test de context version mismatch créé
- ✅ Test de rate limiting créé
- ✅ Tous les tests passent
- ✅ Couverture des cas d'erreur

**Estimation** : 4h

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers API

```
api/src/
  ├── middleware/
  │   └── rate_limit.py              [NOUVEAU]
  ├── utils/
  │   ├── idempotency.py             [NOUVEAU]
  │   └── timeout.py                 [NOUVEAU]
  └── tests/
      └── integration/
          └── test_full_flow.py      [NOUVEAU]
```

### Fichiers à modifier API

```
api/src/
  ├── api/
  │   ├── agent/
  │   │   └── routes.py              [MODIFIER - RBAC, versioning, rate limit]
  │   ├── conversations/
  │   │   └── routes.py              [MODIFIER - RBAC]
  │   └── messages/
  │       └── routes.py              [MODIFIER - RBAC]
  ├── agent/
  │   └── tools/
  │       ├── flights.py             [MODIFIER - idempotence, timeout]
  │       ├── hotels.py             [MODIFIER - idempotence, timeout]
  │       └── offers.py             [MODIFIER - idempotence]
  ├── services/
  │   └── context_service.py         [MODIFIER - optimistic locking]
  └── main.py                        [MODIFIER - ajouter rate limit middleware]
```

### Fichiers à modifier Client

```
bagtrip/lib/
  ├── service/
  │   └── api_client.dart             [MODIFIER - gestion d'erreurs]
  └── chat/
      └── bloc/
          └── chat_bloc.dart          [MODIFIER - gestion erreurs, refresh context]
```

---

## 🔄 Flux de données

### Gestion du versioning

```
1. Client envoie requête avec context_version = 12
2. Serveur charge le contexte actuel (version = 13)
3. Serveur compare : 12 != 13
4. Serveur retourne 409 avec détails
5. Client reçoit l'erreur et affiche message "Context mis à jour, veuillez rafraîchir"
6. Client envoie RefreshContext event
7. Client recharge le contexte et réessaie
```

### Rate limiting

```
1. Client envoie requête à /v1/agent/chat
2. Middleware vérifie le rate limit pour user_id
3. Si < 10 requêtes dans la fenêtre : autoriser, incrémenter compteur
4. Si >= 10 requêtes : retourner 429 avec Retry-After
5. Client reçoit 429 et affiche message d'erreur
```

### Idempotence

```
1. Agent appelle search_flights_tool avec params {origin: "CDG", destination: "FCO", ...}
2. Tool génère hash des params
3. Tool vérifie le cache avec cette clé
4. Si hit : retourner résultat en cache
5. Si miss : exécuter recherche, stocker résultat, retourner résultat
```

---

## ✅ Checklist de validation

### Sécurité
- [x] RBAC implémenté sur tous les endpoints
- [x] Rate limiting fonctionnel sur /v1/agent/chat
- [x] Tests pour vérifier le refus d'accès non autorisé
- [x] Tests pour vérifier le rate limiting

### Versioning
- [x] Vérification de context_version dans chat_endpoint
- [x] Vérification de context_version dans actions_endpoint
- [x] Optimistic locking dans update_context
- [x] Tests pour vérifier le versioning

### Idempotence
- [x] IdempotencyCache créé
- [x] Cache appliqué sur search_flights_tool
- [x] Cache appliqué sur search_hotels_tool
- [x] Tests pour vérifier l'idempotence

### Timeouts
- [x] Décorateur with_timeout créé
- [x] Timeout appliqué sur les tool calls
- [x] Fallback fonctionnel
- [x] Tests pour vérifier les timeouts

### Gestion d'erreurs client
- [x] Gestion centralisée dans ApiClient
- [x] Messages d'erreur clairs
- [x] Gestion du context mismatch
- [x] Gestion du rate limit
- [x] Event RefreshContext dans ChatBloc

### Tests
- [x] Test du flow complet
- [x] Test de context version mismatch
- [x] Test de rate limiting
- [x] Tous les tests passent

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 8.1** : Implémenter RBAC (fondation sécurité)
2. **Tâche 8.2** : Implémenter Rate Limiting (protection)
3. **Tâche 8.3** : Gestion du versioning (robustesse)
4. **Tâche 8.4** : Idempotence (optimisation)
5. **Tâche 8.5** : Timeouts et fallbacks (robustesse)
6. **Tâche 8.6** : Gestion d'erreurs client (UX)
7. **Tâche 8.7** : Tests d'intégration (validation)

---

## 📝 Notes importantes

### Performance

- **Rate Limiting** : Pour la production, utiliser Redis au lieu d'un cache en mémoire
- **Idempotence** : Pour la production, utiliser Redis avec TTL au lieu d'un cache en mémoire
- **Timeouts** : Ajuster les valeurs selon les performances réelles des APIs externes

### Sécurité

- **RBAC** : S'assurer que tous les endpoints vérifient l'ownership
- **Rate Limiting** : Ajuster les limites selon les besoins (10 req/min est un exemple)
- **Versioning** : Le versioning est critique pour éviter les race conditions

### Extensibilité

- **Rate Limiting** : Le middleware peut être étendu pour d'autres endpoints
- **Idempotence** : Le cache peut être étendu pour d'autres outils
- **Timeouts** : Les timeouts peuvent être configurés par outil

---

## 🔗 Liens avec les épics précédents

- **Epic 1-7** : Tous les composants doivent être fonctionnels avant d'implémenter Epic 8
- **Epic 3** : Le versioning du contexte est géré dans l'agent
- **Epic 6** : La gestion d'erreurs client améliore l'UX du chat

---

## 📚 Références

- FastAPI Security : https://fastapi.tiangolo.com/tutorial/security/
- Rate Limiting : https://en.wikipedia.org/wiki/Rate_limiting
- Optimistic Locking : https://en.wikipedia.org/wiki/Optimistic_concurrency_control
- Idempotence : https://en.wikipedia.org/wiki/Idempotence
- Dio Error Handling : https://pub.dev/packages/dio

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ **COMPLÉTÉ** (2026-01-08)

## 📝 Notes d'implémentation

### Fichiers créés
- `api/src/middleware/rate_limit.py` - Rate limiting middleware
- `api/src/utils/idempotency.py` - Cache d'idempotence
- `api/src/utils/timeout.py` - Décorateurs de timeout
- `api/tests/integration/test_full_flow.py` - Tests d'intégration complets

### Fichiers modifiés
- `api/src/api/conversations/routes.py` - Helpers RBAC ajoutés
- `api/src/api/messages/routes.py` - Utilisation des helpers RBAC
- `api/src/api/agent/routes.py` - RBAC renforcé, format erreurs 409 amélioré
- `api/src/agent/tools/flights.py` - Idempotence et timeout ajoutés
- `api/src/agent/tools/hotels.py` - Idempotence et timeout ajoutés
- `api/src/main.py` - Middleware rate limiting intégré
- `bagtrip/lib/service/api_client.dart` - Gestion d'erreurs améliorée
- `bagtrip/lib/chat/bloc/chat_bloc.dart` - Gestion erreurs 409/429, RefreshContext
- `bagtrip/lib/chat/bloc/chat_state.dart` - shouldRefreshContext ajouté
- `bagtrip/lib/chat/bloc/chat_event.dart` - RefreshContext event ajouté
