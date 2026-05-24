---

## Rapport d'audit complet

### Vue d'ensemble

L'investigation a revele **3 categories de problemes** repartis sur **l'ensemble du stack**, pas uniquement sur la recherche de destination.

---

### A. API Backend — Gestion d'erreurs faible

#### A1. Exceptions generiques sans status code (28 instances)

Tous les fichiers d'integration Amadeus levent des `Exception` generiques sans distinguer le type d'erreur :

| Fichier | Instances | Exemples de status perdus |
|---------|-----------|--------------------------|
| `integrations/amadeus/locations.py` | 7 | 429 → Exception, 404 → Exception |
| `integrations/amadeus/flights.py` | 10 | 429, 401, 503 → tous Exception |
| `integrations/amadeus/hotels.py` | 4 | Idem |
| `integrations/amadeus/auth.py` | 3 | Token 429/401 → Exception |

**Impact** : Un 429 "Too Many Requests" d'Amadeus est impossible a distinguer d'une vraie erreur serveur.

#### A2. Routes : catch-all `Exception → 500` (40+ instances)

| Fichier | Endpoints affectes |
|---------|-------------------|
| `api/travel/routes.py` | 6 endpoints (locations, flights, cheapest dates) |
| `api/booking/routes.py` | 2 endpoints (confirm_price, create_booking) |
| `api/admin/routes.py` | 30+ endpoints |
| `api/auth/routes.py` | google_sign_in, apple_sign_in |

Pattern systematique :
```python
except Exception as e:
    raise HTTPException(status_code=500, detail=str(e))  # TOUT → 500
```

#### A3. Aucune strategie de retry/rate-limit pour les APIs externes

- **Zero retry** sur les appels Amadeus (locations, flights, hotels)
- **Zero detection** du header `Retry-After` sur les 429
- **Zero backoff** exponentiel
- Le seul retry existant est dans `agent/retry.py` pour le graph LangGraph, pas pour les routes API

#### A4. Echecs Stripe silencieux (3 instances)

`auth/routes.py` : lors du register/google_sign_in/apple_sign_in, si la creation du Stripe customer echoue, c'est **silencieusement ignore**. L'utilisateur est cree sans compte Stripe → les paiements echoueront plus tard.

---

### B. Flutter Services — Parsing et messages d'erreur

#### B1. Liste vide traitee comme erreur (1 fichier, 2 occurrences)

**`location_service.dart:157-170`** : Quand l'API retourne `{ "locations": [], "count": 0 }` (200 OK, 0 resultats), le code retourne `ServerError("Unexpected response shape")` au lieu de `Success([])`. Cela arrive **a chaque frappe intermediaire** (ex: "mars", "marse", "marseil").

#### B2. Messages Dio bruts exposes (5 instances dans 3 fichiers)

| Fichier | Ligne | Message expose |
|---------|-------|---------------|
| `service/location_service.dart` | 88 | `'Error searching flights: ${e.message}'` |
| `service/location_service.dart` | 218 | `'Error searching locations: ${e.message}'` |
| `service/auth_service.dart` | 99 | `NetworkError(e.message ?? 'Network error')` |
| `service/agent_service.dart` | 63 | `'Error executing action: ${e.message}'` |

**Contraste** : Les autres services (trip, activity, accommodation, budget, etc.) utilisent correctement `ApiClient.mapDioError(e)` qui sanitize le message.

---

### C. Flutter BLoC/UI — Erreurs brutes affichees

#### C1. BLoCs emettant `error.message` brut (9 instances dans 3 fichiers)

| Fichier | Lignes | Context |
|---------|--------|---------|
| `plan_trip_bloc.dart` | 183, 507, 552 | Recherche destination, creation trip |
| `plan_trip_bloc.dart` | 285, 375 | `e.toString()` pour AI suggestions et SSE stream |
| `flight_search_bloc.dart` | 72, 98, 261 | Recherche de vols |
| `flight_search_result_bloc.dart` | 98, 289 | Resultats de vols |

#### C2. Views affichant des erreurs brutes (4 instances)

| Fichier | Ligne | Type d'affichage |
|---------|-------|-----------------|
| `step_destination_view.dart` | 242 | `Text(state.error!)` en rouge |
| `step_review_view.dart` | 40 | `SnackBar(content: Text(state.error!))` |
| `flight_search_form.dart` | 31 | `state.errorMessage` avec fallback FR hardcode |
| `flight_search_result_widget.dart` | 28 | `state.message` passe a l10n |

#### C3. Pattern correct existant (pour reference)

`toUserFriendlyMessage()` dans `utils/error_display.dart` mappe correctement les `AppError` → messages l10n. Il est **deja utilise dans 14+ views** (trips, activities, budget, baggage, login, profile, etc.) mais **absent** des modules plan_trip et flight_search.

---

### Synthese

| Severite | Categorie | Instances | Impact |
|----------|-----------|-----------|--------|
| **CRITIQUE** | API : Exception generique sans status | 28 | 429 Amadeus → 500 renvoyee au client |
| **CRITIQUE** | Flutter : Liste vide = erreur | 2 | Faux positifs a chaque frappe |
| **HAUTE** | API : catch-all → 500 | 40+ | Client ne peut pas distinguer les erreurs |
| **HAUTE** | Flutter : error.message brut dans BLoC | 9 | Messages techniques exposes a l'utilisateur |
| **HAUTE** | Flutter : erreur brute dans UI | 4 | UX degradee (screenshot du bug) |
| **MOYENNE** | Flutter : Dio message non sanitize | 5 | Messages techniques dans les logs/erreurs |
| **MOYENNE** | API : Zero retry/backoff | Systeme | Fragilite face au rate-limiting |
| **BASSE** | API : Stripe silencieux | 3 | Comptes sans Stripe customer |

Veux-tu que je corrige tout ca ? Je peux commencer par les corrections critiques (les 6 points initiaux du bug destination) puis enchainer sur les problemes connexes.
