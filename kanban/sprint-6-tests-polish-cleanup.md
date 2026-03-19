# Sprint 6 — Tests Complets, Polish Final & Cleanup Legacy

> **Objectif** : Ecrire les tests manquants, finaliser le polish (context menus, accessibility), optimiser les performances, supprimer le code legacy, et preparer la release.
> **Dependances** : Tous les sprints precedents

**Ce sprint est le seul sprint de "finalisation"** car le polish principal (animations, haptics, skeletons) a ete integre dans chaque sprint precedent. Ce qui reste ici, c'est :
1. Les tests de couverture manquants
2. Les optimisations de performance
3. L'accessibilite
4. Les context menus iOS
5. La suppression du code legacy
6. Les tests E2E finaux
7. Le CI/CD

---

## 6.1 — Tests de couverture manquants

> Objectif : couverture BLoCs > 80%, widgets > 60%.

### Tests unitaires P0 — BLoCs

| Test | Module | Scenarios |
| --- | --- | --- |
| `plan_trip_bloc_full_test.dart` | PlanTripBloc | Flow complet 6 steps |
| `trip_detail_bloc_full_test.dart` | TripDetailBloc | Load, refresh, validate, add, role-gating |
| `home_bloc_all_states_test.dart` | HomeBloc | NewUser, ActiveTrip, TripManager, Error, Refresh |
| `accommodation_bloc_test.dart` | AccommodationBloc | CRUD + hotel search + suggestions |
| `baggage_bloc_test.dart` | BaggageBloc | Create/update/delete, suggestions, completion |
| `transport_bloc_test.dart` | TransportBloc | Flight/train/car/bus management |
| `flight_search_bloc_test.dart` | FlightSearchBloc | 25+ event handlers, validation, search |
| `flight_search_result_bloc_test.dart` | FlightSearchResultBloc | Filters, sorting, pagination |
| `flight_result_details_bloc_test.dart` | FlightResultDetailsBloc | Detail display |
| `personalization_bloc_test.dart` | PersonalizationBloc | Step progression, storage |
| `connectivity_bloc_test.dart` | ConnectivityBloc | Online/offline transitions |

### Tests unitaires P1 — Services & Repositories

| Test | Module | Scenarios |
| --- | --- | --- |
| `api_client_test.dart` | ApiClient | Auth headers, 401 refresh, error mapping, timeouts |
| `ai_service_test.dart` | AiService | SSE stream, accept, errors, quota |
| `auth_service_test.dart` | AuthService | Login, logout, token management |
| `trip_service_test.dart` | TripService | CRUD via API |
| `activity_service_test.dart` | ActivityService | CRUD via API |
| `accommodation_service_test.dart` | AccommodationService | CRUD + search |
| `budget_service_test.dart` | BudgetService | Budget operations |
| `baggage_item_service_test.dart` | BaggageItemService | CRUD operations |
| `booking_service_test.dart` | BookingService | Flight/transport bookings, Stripe |
| `transport_service_test.dart` | TransportService | Flight/train/car data |
| `traveler_service_test.dart` | TravelerService | Traveler management |
| `subscription_service_test.dart` | SubscriptionService | Payment/subscription |
| `profile_api_service_test.dart` | ProfileApiService | Profile operations |
| `notification_service_full_test.dart` | NotificationService | Push, local, device token |
| `trip_share_service_test.dart` | TripShareService | Sharing, revocation |
| `feedback_service_test.dart` | FeedbackService | Feedback submission |
| `cached_trip_repo_test.dart` | CachedTripRepository | Cache hit, miss, invalidation, offline fallback |

### Tests unitaires P1 — Models restants

| Test | Model | Scenarios |
| --- | --- | --- |
| `accommodation_model_test.dart` | Accommodation | JSON round-trip, nullability |
| `baggage_item_model_test.dart` | BaggageItem | JSON round-trip |
| `manual_flight_model_test.dart` | ManualFlight | JSON round-trip |
| `traveler_model_test.dart` | Traveler | JSON round-trip |
| `notification_model_test.dart` | AppNotification | JSON round-trip |
| `booking_response_model_test.dart` | BookingResponse | JSON round-trip |
| `payment_models_test.dart` | PaymentCard, PaymentAuthorizeResponse | JSON round-trip |
| `flight_info_model_test.dart` | FlightInfo | JSON round-trip |
| `budget_estimation_model_test.dart` | BudgetEstimation | JSON round-trip |
| `trip_share_model_test.dart` | TripShare | JSON round-trip |
| `feedback_model_test.dart` | TripFeedback | JSON round-trip |

### Tests widgets P0

| Test | Widget | Scenarios |
| --- | --- | --- |
| `home_views_full_test.dart` | 3 home views | Chaque state rend correctement |
| `plan_trip_wizard_test.dart` | PlanTripFlowPage | Navigation 6 steps, back, header recap |
| `trip_detail_sections_test.dart` | Toutes les sections | Rendu, interactions, role-gating |

### Tests widgets P1

| Test | Widget | Scenarios |
| --- | --- | --- |
| `dark_mode_test.dart` | Tous les ecrans | Pas de texte invisible, contraste suffisant |
| `accessibility_test.dart` | Tous les ecrans | Semantic labels, touch targets 44px |

---

## 6.2 — Performance Optimization

### Taches

- [ ] **P1 — Image caching et optimisation**
  - Utiliser `cached_network_image` partout
  - Max placeholder size (eviter decode 4K)
  - Trip covers : max 800px. Activity images : max 400px.
  - **Test** : Mesurer temps de chargement avant/apres

- [ ] **P2 — Lazy loading des sections trip detail**
  - Les sections ne chargent leurs donnees que quand visibles
  - `VisibilityDetector` ou `SliverLayoutBuilder`
  - Timeline charge toujours. Budget, Sharing chargent au scroll.
  - **Test** : API calls au bon moment

- [ ] **P3 — Optimisation HomeBloc**
  - Verifier que les appels paralleles fonctionnent
  - Mesurer temps de chargement (objectif < 1.5s)
  - Identifier et corriger le bottleneck si > 1.5s
  - **Test** : Performance test avec Timer

- [ ] **P4 — Memory leak audit final**
  - Verifier tous les BLoCs disposes
  - Verifier les `Timer.periodic` annules (now indicator)
  - Verifier les `StreamSubscription` annulees (SSE, FCM)
  - Utiliser DevTools Memory profiler
  - **Test** : Naviguer entre 10 trips sans crash, memory stable

- [ ] **P5 — Flutter analyze strict**
  - `flutter analyze` = 0 issues sur tout le projet
  - Corriger les warnings restants
  - **Test** : CI gate sur `flutter analyze`

---

## 6.3 — Context Menus iOS

- [ ] **CM1 — Context menus sur les trip cards**
  - Long press → `CupertinoContextMenu` avec preview + actions (Voir, Partager, Archiver)
  - iOS uniquement
  - **Test** : Menu apparait, actions fonctionnent

- [ ] **CM2 — Context menus sur les activity cards**
  - Long press → context menu (Editer, Valider, Supprimer)
  - iOS uniquement, OWNER only
  - **Test** : Menu, actions, role-gating

---

## 6.4 — Accessibility

### Taches

- [ ] **AX1 — Semantic labels**
  - Tous les boutons/icons ont `Semantics(label:)` ou `tooltip`
  - Images ont `semanticLabel`
  - Trip cards : "Voyage a Barcelona, 15-22 avril"
  - **Test** : Accessibility test automatise

- [ ] **AX2 — Touch targets 44x44pt minimum**
  - Audit tous les elements interactifs
  - Timeline boutons, chips, checkboxes
  - **Test** : Audit automatique des tailles

- [ ] **AX3 — Dynamic Type support**
  - Textes s'adaptent au `textScaleFactor`
  - Verifier que rien ne deborde a 1.5x
  - **Test** : Widget test avec `MediaQuery(textScaler: TextScaler.linear(1.5))`

- [ ] **AX4 — Contrast ratio >= 4.5:1 (AA)**
  - Light ET dark mode
  - **Test** : Audit couleurs

---

## 6.5 — Suppression du code legacy

### Taches

- [ ] **LC1 — Supprimer l'ancien flow de creation manuel**
  - Fichiers a supprimer :
    - `bagtrip/lib/trip_creation/bloc/trip_creation_bloc.dart`
    - `bagtrip/lib/trip_creation/bloc/trip_creation_state.dart`
    - `bagtrip/lib/trip_creation/bloc/trip_creation_event.dart`
    - `bagtrip/lib/trip_creation/view/trip_creation_flow_page.dart`
    - `bagtrip/lib/trip_creation/view/step_destination_view.dart`
    - `bagtrip/lib/trip_creation/view/step_dates_view.dart`
    - `bagtrip/lib/trip_creation/view/step_travelers_view.dart`
    - `bagtrip/lib/trip_creation/view/step_review_view.dart`
    - Tout `bagtrip/lib/trip_creation/widgets/`
  - Supprimer toute reference a `TripCreationBloc`
  - **Test** : `flutter analyze` = 0, `grep -r "TripCreationBloc"` = 0

- [ ] **LC2 — Supprimer l'ancien flow AI**
  - Fichiers a supprimer :
    - `bagtrip/lib/create_trip_ai/bloc/*`
    - `bagtrip/lib/create_trip_ai/view/*`
    - `bagtrip/lib/create_trip_ai/models/*`
    - `bagtrip/lib/pages/create_trip_ai_*`
  - Supprimer toute reference a `CreateTripAiBloc`
  - **Test** : `flutter analyze` = 0, `grep -r "CreateTripAi"` = 0

- [ ] **LC3 — Supprimer les pages legacy**
  - Verifier que les remplacements existent
  - Supprimer : `trip_home_page.dart`, vues legacy
  - Garder les widgets reutilises
  - **Test** : Navigation fonctionne, pas de 404

- [ ] **LC4 — Nettoyer les routes**
  - Supprimer les routes des anciens flows (TripCreationRoute, CreateTripAiRoutes)
  - Regenerer `route_definitions.g.dart`
  - **Test** : `build_runner build` passe, navigation complete

- [ ] **LC5 — Nettoyer le service locator**
  - Supprimer les registrations de services obsoletes
  - Verifier que toutes les nouvelles dependencies sont enregistrees
  - **Test** : `setupServiceLocator()` ne throw pas

- [ ] **LC6 — Supprimer les endpoints API deprecated**
  - Supprimer `POST /v1/ai/inspire` et `POST /v1/ai/inspire/accept`
  - Garder les nouveaux endpoints stream/accept
  - **Test** : Anciens endpoints → 404

- [ ] **LC7 — Supprimer le composant `EmptyState`**
  - Fichier : `bagtrip/lib/components/empty_state.dart`
  - Plus aucune reference ne devrait exister (fixe au Sprint 1)
  - **Test** : `grep -r "empty_state.dart"` = 0

---

## 6.6 — Tests E2E Finaux

### Taches

- [ ] **FT1 — Test E2E : Nouveau utilisateur → premier voyage (AI flow)**
  ```
  1. Login
  2. Home = OnboardingView
  3. "Planifier un voyage"
  4. Step 1 : Dates exactes (15-22 avril)
  5. Step 2 : 2 voyageurs, budget "Comfortable"
  6. Step 3 : "Inspire-moi"
  7. Step 4 : Select Barcelona
  8. Step 5 : Generation SSE (6 etapes)
  9. Step 6 : Review → "Creer mon voyage"
  10. → TripDetailPage
  11. Home → HomeTripManager avec trip en hero
  ```
  - **Verification** : Trip en BDD avec IATA, activites, bagages, cover image

- [ ] **FT2 — Test E2E : Creation manuelle**
  ```
  1. Home → "Planifier"
  2. Dates par mois (Juin 2026)
  3. 1 voyageur, budget "Backpacker"
  4. Recherche "Lisbonne" → select
  5. Generation
  6. Review → Creer
  7. Trip detail → ajouter vol manuel
  8. Ajouter hebergement
  9. Valider 2 activites IA
  10. Checker 5 bagages
  ```
  - **Verification** : Completion bar progresse

- [ ] **FT3 — Test E2E : Voyage en cours**
  ```
  1. Trip avec start_date = today
  2. Launch → ActiveTripHomeView
  3. Timeline du jour avec activites
  4. "Now" indicator visible
  5. Ajouter depense rapide
  6. Naviguer vers activite
  7. Preview demain
  ```
  - **Verification** : Mode detecte, timeline correcte

- [ ] **FT4 — Test E2E : Partage et lecture seule**
  ```
  1. User A cree trip
  2. User A partage avec User B
  3. User B login → voit trip partage
  4. User B → badge "Lecture seule"
  5. Boutons edition disabled
  6. User A revoque → User B no access
  ```
  - **Verification** : Permissions, revocation

- [ ] **FT5 — Test E2E : Fin de voyage**
  ```
  1. Trip avec end_date = yesterday
  2. Launch → dialog "Voyage termine"
  3. Confirmer → ecran post-trip stats
  4. Donner feedback
  5. Home → trip dans "Passes"
  ```
  - **Verification** : Transition COMPLETED, stats, feedback

---

## 6.7 — CI/CD Quality Gates

### Taches

- [ ] **CI1 — Pipeline de tests**
  - `flutter analyze` → 0 issues
  - `flutter test` → tous passent
  - Coverage report genere
  - Pipeline CI bloque les PR si echec
  - **Test** : CI fonctionnel

- [ ] **CI2 — Golden tests baseline**
  - Generer goldens pour composants cles
  - Commiter dans le repo
  - `flutter test --update-goldens=false` echoue si golden change
  - **Test** : Goldens stables

---

## 6.8 — Documentation & Handoff

### Taches

- [ ] **DOC1 — Mettre a jour CLAUDE.md**
  - Ajouter les nouveaux patterns (PlanTripBloc, TripDetailBloc)
  - Documenter la nouvelle architecture
  - Supprimer les references aux anciens BLoCs

- [ ] **DOC2 — Verifier les strings l10n**
  - Tous les nouveaux textes dans `app_en.arb` et `app_fr.arb`
  - Aucun texte hardcode restant
  - Scan : `grep -rn '"[A-Za-z].*"' bagtrip/lib/ --include="*.dart" | grep -v '/gen/' | grep -v 'import ' | grep -v 'const '`

- [ ] **DOC3 — Git cleanup**
  - Branche propre
  - `.gitignore` couvre les fichiers generes

---

## Tests API Backend

| Test | Module | Priorite |
| --- | --- | --- |
| `test_trip_lifecycle_complete.py` | Trip lifecycle | P0 |
| `test_ai_pipeline_complete.py` | Agent graph | P0 |
| `test_trip_validation_strict.py` | Trip schemas | P0 |
| `test_share_quota.py` | Share service | P1 |
| `test_notification_scheduling.py` | Notification job | P1 |
| `test_batch_status_transition.py` | Trip status job | P1 |
| `test_full_trip_lifecycle.py` | Trip lifecycle E2E | P0 |
| `test_ai_flow_complete.py` | AI flow E2E | P0 |

---

## Criteres d'acceptation Sprint 6

- [ ] Couverture tests BLoCs > 80%
- [ ] Couverture tests widgets > 60%
- [ ] 5 tests E2E passent
- [ ] Zero reference aux anciens BLoCs (TripCreationBloc, CreateTripAiBloc)
- [ ] Zero fichier legacy dans trip_creation/ et create_trip_ai/
- [ ] Zero fichier `empty_state.dart`
- [ ] `flutter analyze` = 0 issues
- [ ] `flutter test` → tous passent
- [ ] Pas de memory leak detecte (10 navigations sans crash)
- [ ] Home charge en < 1.5s
- [ ] Images cachees et optimisees
- [ ] Accessibilite : touch targets 44pt, semantic labels, contrast AA
- [ ] Context menus iOS sur trip cards et activity cards
- [ ] CLAUDE.md mis a jour
- [ ] Tous les textes en l10n (EN + FR)
- [ ] Build iOS/Android compile sans erreur
- [ ] App fonctionne de bout en bout sur device physique
- [ ] CI/CD pipeline fonctionnel
- [ ] Anciens endpoints API → 404
