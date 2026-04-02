# Analyse des gaps BagTrip

> Derniere mise a jour : 2026-03-26
> Source : inspection automatisee du code par 10 agents de documentation

Ce document consolide tous les gaps identifies. Chaque element est classe par priorite (P0 = critique/bloquant, P1 = important, P2 = amelioration) et reference les fichiers source concernes.

---

## P0 — Critiques (bloquants / securite / features cassees)

### ~~Securite~~ ✅ Resolu


| Element                        | Description                                                                           | Fichier                                           | Statut |
| ------------------------------ | ------------------------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| JWT_SECRET par defaut en prod  | ~~Valeur `"dev-secret-key-change-in-production"` sans validation bloquante au demarrage~~ | `api/src/config/env.py:54-63`                 | ✅ `field_validator` bloque le demarrage en prod si valeur par defaut |
| `.env` potentiellement commite | ~~Le fichier `.env` est visible dans le repo (git status)~~                           | `.gitignore`                                      | ✅ Deja gitignore, non track |
| Endpoint test expose en prod   | ~~`/payment/confirm-test` utilise `pm_card_visa` en dur sans guard production~~       | `api/src/api/payments/routes.py:118-119`          | ✅ Guard `NODE_ENV == production` → 404 |


### Infrastructure


| Element                            | Description                                                  | Fichier                                                        |
| ---------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------- |
| Aucun Dockerfile de production     | Seuls les `Dockerfile.dev` existent (API et admin)           | `api/Dockerfile.dev`, `admin-panel/application/Dockerfile.dev` |
| Aucun compose de production        | Pas de health checks Docker, restart policies, reverse proxy | `compose.yml`                                                  |
| Aucun pipeline de deploiement (CD) | Zero workflow de deploy automatise                           | `.github/workflows/`                                           |
| Tests backend API absents          | Aucun fichier de test dans `api/`                            | `api/`                                                         |


### ~~Features cassees~~ ✅ Resolu

| Element | Description | Statut |
|---------|-------------|--------|
| ~~`getInspiration()` est un stub~~ | ~~Retourne `const Success([])`~~ | ✅ Utilise `planTripStream(mode: 'destinations_only')` pour retourner les suggestions IA |
| ~~Parametres SSE incomplets~~ | ~~`_buildSseParams()` ne transmet que 4/14 champs~~ | ✅ Transmet tous les champs (nbTravelers, originCity, dateMode, budgetPreset, travelTypes, companions, constraints) |
| ~~Mot de passe oublie~~ | ~~Bouton "Forgot password" avec `onPressed` vide~~ | ✅ Page forgot password + endpoints `POST /forgot-password` et `POST /reset-password` |
| ~~Suppression de compte absente~~ | ~~Obligation RGPD non respectee~~ | ✅ `DELETE /v1/auth/me` avec cascade donnees + suppression Stripe + bouton profil avec confirmation |
| ~~Pas de Stripe SDK mobile~~ | ~~`clientSecret` jamais utilise dans PaymentSheet~~ | ✅ Fix URLs booking service + `CreateBookingIntent` event + bouton "Reserver" dans flight details |
| ~~Pas de BLoC paiements~~ | ~~Pages statiques sans verification~~ | ✅ `PaymentSuccessPage` accepte `intentId`, affiche reference booking, route enrichie |

### ~~UX critique~~ ✅ Resolu


| Element                         | Description                                                                      | Fichier                                           | Statut |
| ------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| ~~Changement de langue inoperant~~  | ~~`SettingsBloc.selectedLanguage` n'est pas connecte a `MaterialApp.locale`~~        | `bagtrip/lib/main.dart:~185`                      | ✅ `BlocBuilder` + `locale` param + picker UI |
| ~~Theme non persiste~~              | ~~Le choix dark/light est perdu au redemarrage~~                                     | `bagtrip/lib/settings/bloc/settings_bloc.dart`    | ✅ `SettingsStorage` persiste theme + langue |
| ~~Budget summary stale apres CRUD~~ | ~~Le bloc ne recharge pas le summary apres Create/Update/Delete — donnees perimees~~ | `bagtrip/lib/budget/bloc/budget_bloc.dart:49-125` | ✅ `RefreshBudgetSummary` event re-fetch le summary apres chaque CRUD |
| ~~Pas de route 404~~                | ~~Aucun `errorBuilder` dans GoRouter — URL invalide = crash~~                        | `bagtrip/lib/navigation/app_router.dart`          | ✅ `NotFoundPage` + `errorBuilder` dans GoRouter + l10n FR/EN |


### Notifications critiques


| Element                           | Description                                                                  | Fichier                                               |
| --------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------- |
| Resume matinal en UTC             | Envoye a 7h UTC pour tous — Tokyo le recoit a 16h locale                     | `api/src/jobs/notification_job.py:178`                |
| Alertes vol timezone incorrecte   | Horaires Amadeus en heure locale forces en UTC — decalage alertes H-4/H-1    | `api/src/jobs/notification_job.py:142`                |
| Tap notification locale non route | Callback `onNotificationTap` non connecte a GoRouter — le tap ne navigue pas | `bagtrip/lib/service/local_notification_service.dart` |


---

## P1 — Importants (gaps fonctionnels significatifs)

### Auth & compte


| Element                           | Description                                                 | Fichier                                     |
| --------------------------------- | ----------------------------------------------------------- | ------------------------------------------- |
| Pas de verification d'email       | L'utilisateur est directement authentifie apres inscription | `api/src/api/auth/routes.py`                |
| Pas de changement de mot de passe | Aucun endpoint pour changer le mot de passe                 | `api/src/api/auth/routes.py`                |
| Pas de rate limiting auth         | Risque de brute force sur `/login`, `/register`, `/refresh` | `api/src/api/auth/routes.py`                |
| CGU/politique de confidentialite  | Liens placeholder vides dans login page                     | `bagtrip/lib/pages/login_page.dart:137-143` |


### ~~Donnees non persistees~~ ✅ Resolu


| Element                                                | Description                                             | Fichier                                                          | Statut |
| ------------------------------------------------------ | ------------------------------------------------------- | ---------------------------------------------------------------- | ------ |
| ~~`travelFrequency` et `constraints` non envoyes a l'API~~ | ~~Stockes uniquement en SharedPreferences local~~           | `bagtrip/lib/personalization/bloc/personalization_bloc.dart:260` | ✅ `updateProfile()` transmet `travelFrequency` + `medicalConstraints` a l'API, migration 0022 ajoute `travel_frequency` |
| ~~`travelFrequency` absent du modele backend~~             | ~~Le champ n'existe pas dans `TravelerProfile` SQLAlchemy~~ | `api/src/models/traveler_profile.py`                             | ✅ Colonne `travel_frequency` ajoutee + schemas/routes/service mis a jour |
| ~~Persistance de la langue perdue~~                        | ~~Choix de langue perdu au redemarrage~~                    | `bagtrip/lib/settings/bloc/settings_bloc.dart`                   | ✅ `SettingsStorage` (SharedPreferences) + `LoadSettings` hydratation au demarrage + `locale` connecte a `MaterialApp` + picker langue dans profil |


### ~~Creation voyage & IA~~ ✅ Resolu


| Element                              | Description                                                        | Fichier                                                  | Statut |
| ------------------------------------ | ------------------------------------------------------------------ | -------------------------------------------------------- | ------ |
| ~~`originCity` non transmis au SSE~~     | ~~Recherches de vols impossibles sans ville de depart~~                | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:577-596` | ✅ Transmis dans `_buildSseParams()` |
| ~~Mode `destinations_only` non utilise~~ | ~~L'API le supporte mais Flutter ne l'appelle jamais~~                 | `api/src/agent/graph.py`                                 | ✅ Appele via `getInspiration()` dans `ai_service.dart` |
| ~~Pas de timeout global sur le graph~~   | ~~Stream ouvert indefiniment si noeud bloque~~                         | `api/src/api/ai/plan_trip_routes.py`                     | ✅ `async_generator_with_timeout` (5min) + timeouts LLM (60s) + timeout nodes (120s) |
| ~~Cache IA in-memory~~                   | ~~`IdempotencyCache` non partage en multi-instance~~                   | `api/src/utils/idempotency.py:67`                        | ✅ Backend Redis avec fallback memoire + service Redis dans compose.yml |
| ~~Pas de tests ReAct executor~~          | ~~Parsing regex sans tests unitaires~~                                 | `api/src/agent/react_executor.py`                        | ✅ 30 tests (parse_react_output + react_execute + timeouts) dans `tests/agent/test_react_executor.py` |
| ~~Annulation SSE non propre~~            | ~~`emit.forEach` non interrompu quand l'utilisateur quitte le wizard~~ | `bagtrip/lib/plan_trip/bloc/plan_trip_bloc.dart:322-377` | ✅ Souscription manuelle + `_cancelSseStream()` dans back/retry/close |


### ~~Home & Trip Detail~~ ✅ Resolu


| Element                             | Description                                                                  | Fichier                                                      | Statut |
| ----------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------ | ------ |
| ~~Quick Actions stubs~~             | ~~Weather, photo, AI suggestion, tomorrow — callbacks `() {}`~~              | `bagtrip/lib/home/widgets/quick_actions_bar.dart:62-104`     | ✅ Weather bottom sheet, camera launcher, AI→activities nav, tomorrow scroll |
| ~~Transition offline non syncee~~   | ~~Transition PLANNED->ONGOING optimiste jamais rejoouee au retour de connexion~~ | `bagtrip/lib/home/helpers/trip_mode_detector.dart:46`    | ✅ HomeBloc ecoute `onConnectivityChanged`, replay transitions pending au retour |
| ~~Section Carte placeholder~~       | ~~Affiche "Bientot disponible"~~                                             | `bagtrip/lib/trip_detail/view/trip_detail_view.dart:613-639` | ✅ `TripLocationsPage` avec lieux tappables → Maps natif |
| ~~Erreurs sections differees ignorees~~ | ~~`dataOrNull ?? []` — aucun feedback utilisateur sur echec~~            | `bagtrip/lib/trip_detail/bloc/trip_detail_bloc.dart:106-146` | ✅ `sectionErrors` map + `SectionErrorIndicator` widget + retry par section |
| ~~Rollback sans feedback~~          | ~~Etat restaure apres echec API sans snackbar ni feedback (10+ handlers)~~   | `bagtrip/lib/trip_detail/bloc/trip_detail_bloc.dart`         | ✅ `operationError` dans state + snackbar via `AppSnackBar.showError` (13 handlers) |
| ~~Budget viewer incoherent~~        | ~~`totalExpenses` masque mais items individuels accessibles~~                | `api/src/api/trips/routes.py:188`                            | ✅ VIEWER: `totalExpenses=0` home, liste vide budget-items, 403 detail, summary masque |


### ~~Activites & In-Trip~~ ✅ Resolu


| Element                                 | Description                                                                          | Fichier                                                | Statut |
| --------------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------ | ------ |
| ~~Timezone activites~~                      | ~~Compare en heure locale du device, pas de la destination~~                             | `bagtrip/lib/home/helpers/today_activities.dart:35-36` | ✅ `destination_timezone` sur Trip (API + Flutter), `nowInDestination()` utility, `TodayTickCubit` timezone-aware, fix HomeBloc + TripDetailState |
| ~~Pas de validation `endTime > startTime`~~ | ~~Horaires incoherents acceptes~~                                                        | `bagtrip/lib/activities/widgets/activity_form.dart`    | ✅ Validation Flutter dans `_submit()` + `@model_validator` Pydantic sur `ActivityCreateRequest`/`ActivityUpdateRequest` |
| ~~Pas de confirmation de suppression~~      | ~~`DeleteActivity` fire directement sans dialogue~~                                      | `bagtrip/lib/activities/view/activities_view.dart:191` | ✅ `showAdaptiveAlertDialog` avec `isDestructive: true` avant `DeleteActivity` |
| ~~Pas de tests helpers in-trip~~            | ~~`classifyTodayActivities`, `detectAndTransitionTrips`, `detectEndedTrips` non testes~~ | `bagtrip/test/`                                        | ✅ Tests existants + 9 nouveaux tests timezone (`destination_time_test.dart` + groupe timezone-aware dans `today_activities_test.dart`) |


### ~~Vols & Transports~~ ✅ Resolu


| Element                   | Description                                                       | Fichier                                        | Statut |
| ------------------------- | ----------------------------------------------------------------- | ---------------------------------------------- | ------ |
| ~~Multi-destination backend~~ | ~~Formulaire Flutter complet mais backend ne prend qu'un segment~~    | `api/src/api/flights/searches/routes.py` | ✅ `POST /searches/multi` avec N appels Amadeus paralleles + persistence + UI tabs par segment |
| ~~Pas de PATCH vol manuel~~   | ~~Vols manuels non modifiables~~                                      | `api/src/api/flights/manual/routes.py`         | ✅ `PATCH /{tripId}/flights/manual/{flightId}` + form edit mode + sync BudgetItem |
| ~~Recherches non persistees~~ | ~~Mobile utilise le proxy non-persiste au lieu du endpoint persiste~~ | `bagtrip/lib/flight_search/`                   | ✅ Flutter utilise `POST /trips/{tripId}/flights/searches` (persiste) quand tripId disponible, fallback proxy sinon |


### ~~Hebergements~~ ✅ Resolu


| Element                      | Description                                  | Fichier                                  | Statut |
| ---------------------------- | -------------------------------------------- | ---------------------------------------- | ------ |
| ~~Pas de booking hotel Amadeus~~ | ~~Search only — pas de reservation~~     | `api/src/integrations/amadeus/hotels.py` | ✅ Search-only by design. Vestiges booking admin-panel supprimes. Docstrings clarifies. |
| ~~Suggestions IA hebergement~~   | ~~Endpoint backend non visible dans les routes~~ | `api/src/api/accommodations/routes.py`   | ✅ `POST /v1/trips/{tripId}/accommodations/suggest` + LLM prompt + quota guard |


### ~~Bagages & Budget~~ ✅ Resolu


| Element                         | Description                                                        | Fichier                                      | Statut |
| ------------------------------- | ------------------------------------------------------------------ | -------------------------------------------- | ------ |
| ~~Edition item bagages impossible~~ | ~~PATCH existe cote API mais mobile ne l'utilise que pour `isPacked`~~ | `bagtrip/lib/baggage/bloc/baggage_bloc.dart` | ✅ `UpdateBaggageItem` event + `BaggageEditForm` bottom sheet (name, qty, category) + tap-to-edit + `AdaptiveContextMenu` iOS |
| ~~Endpoint estimation IA budget~~   | ~~Non visible dans les routes budget~~                                 | `api/src/api/budget_items/routes.py`         | ✅ `POST /v1/trips/{tripId}/budget/estimate` (AI quota guard + budget_node) + `POST /v1/trips/{tripId}/budget/estimate/accept` (set trip budget_total) |


### ~~Notifications~~ ✅ Resolu


| Element                              | Description                                                    | Fichier                                                            | Statut |
| ------------------------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------ | ------ |
| ~~Temps relatif en dur en francais~~     | ~~"A l'instant", "Il y a X min" hardcodes~~                        | `bagtrip/lib/notifications/widgets/notification_card.dart:171-175` | ✅ l10n keys `notificationsJustNow`, `notificationsMinutesAgo`, `notificationsHoursAgo`, `notificationsShortDaysAgo` + `_relativeTime()` utilise `AppLocalizations` |
| ~~Fichier doublon `activity_page.dart`~~ | ~~Copie exacte de `notifications_page.dart`~~                      | `bagtrip/lib/notifications/view/activity_page.dart`                | ✅ Fichier supprime, `ActivityRoute` utilise `NotificationsPage` directement |
| ~~Deep links incomplets~~                | ~~Baggage/map non geres dans `_onTap()`~~                          | `bagtrip/lib/notifications/widgets/notification_card.dart:151-166` | ✅ Cases `baggage`, `map`, `accommodations`, `transports` ajoutes + icones/couleurs `TRIP_STARTED` et `TRIP_SHARED` |
| ~~`TRIP_STARTED` non envoye~~            | ~~Defini dans l'enum mais jamais utilise~~                         | `api/src/jobs/`                                                    | ✅ Deja implemente dans `trips_service.py:414-431` (PLANNED→ONGOING) + fix screen `"tripHome"` coherent |
| ~~Tests notifications absents~~          | ~~Pas de tests `NotificationBloc` ni `TripNotificationScheduler`~~ | `bagtrip/test/`                                                    | ✅ Tests existants : `notification_bloc_test.dart` (361 lignes), `trip_notification_scheduler_test.dart` (309 lignes), `notification_model_test.dart` (82 lignes) |


### ~~Partage~~ ✅ Resolu


| Element                        | Description                                       | Fichier                                        | Statut |
| ------------------------------ | ------------------------------------------------- | ---------------------------------------------- | ------ |
| ~~Role EDITOR absent~~             | ~~Seuls OWNER et VIEWER — pas de role intermediaire~~ | `api/src/enums.py:48-49`                       | ✅ `EDITOR` ajoute a `ShareRole` + `TripRole`, `get_trip_editor_access` dependency, 27 endpoints migres, role picker dans invite sheet, `canEdit` getter Flutter |
| ~~Invitation par lien impossible~~ | ~~Email uniquement — erreur si non-inscrit~~          | `api/src/services/trip_share_service.py:33-35` | ✅ `PendingInvite` model + migration 0024, token UUID, auto-claim a l'inscription (3 chemins auth), `POST /v1/invites/{token}/accept`, pending invite UI |


### ~~Paiements~~ ✅ Resolu


| Element                         | Description                                               | Fichier                                       | Statut |
| ------------------------------- | --------------------------------------------------------- | --------------------------------------------- | ------ |
| ~~Pas de refund Stripe~~            | ~~Aucun endpoint ni service pour les remboursements~~         | `api/src/services/stripe_payments_service.py` | ✅ `REFUNDED` enum, `StripeClient.create_refund()`, `refund_payment()` service, `POST /{intentId}/payment/refund` route, `charge.refunded` webhook handling |
| ~~Tests backend paiements absents~~ | ~~Aucun test pour les routes paiement/subscription/webhooks~~ | `api/`                                        | ✅ Tests subscription routes (6), subscription service (7), webhook subscription events (5), refund route/service/webhook (9), Stripe client refund (2) = 29 nouveaux tests |


### Post-trip


| Element                               | Description                                                       | Fichier                                                            |
| ------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------ |
| CTA "Creer ce voyage" non fonctionnel | Fait juste `Navigator.pop()` au lieu de pre-remplir un formulaire | `bagtrip/lib/feedback/view/post_trip_suggestion_view.dart:104-106` |
| `activitiesCompleted` trompeur        | Base sur `isBooked` au lieu d'un champ "done"                     | `bagtrip/lib/post_trip/bloc/post_trip_bloc.dart:61`                |
| Navigation post-completion non geree  | `completedTripId` emis mais navigation non implementee            | `bagtrip/lib/home/bloc/home_bloc.dart:273-286`                     |
| Tests post-trip absents               | Pas de tests `FeedbackBloc` ni `PostTripBloc`                     | `bagtrip/test/`                                                    |
| Strings en dur FeedbackListView       | "Points forts", "A ameliorer", "Recommande", "Aucun avis"         | `bagtrip/lib/feedback/view/feedback_list_view.dart`                |


### Profil


| Element                         | Description                              | Fichier                 |
| ------------------------------- | ---------------------------------------- | ----------------------- |
| Pas de photo de profil / avatar | L'avatar est genere depuis les initiales | `bagtrip/lib/profile/`  |
| Tests profil absents            | Ni Flutter ni backend                    | `bagtrip/test/`, `api/` |


### CI/CD


| Element                          | Description                                              | Fichier                    |
| -------------------------------- | -------------------------------------------------------- | -------------------------- |
| Admin-panel absent du CI         | Ni lint, ni tests, ni type-check                         | `.github/workflows/ci.yml` |
| Pre-commit admin-panel absent    | `.pre-commit-config.yaml` ne couvre que api/ et bagtrip/ | `.pre-commit-config.yaml`  |
| Branch protection non configuree | Quality gate defini mais pas de protection GitHub        | `.github/`                 |
| E2E non executes en CI           | Tests integration Flutter non lances en CI               | `.github/workflows/ci.yml` |


### Technique mobile


| Element                               | Description                                              | Fichier                                                    |
| ------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------- |
| Cache activites/bagages/budget absent | Seuls trips et weather sont caches                       | `bagtrip/lib/config/service_locator.dart`                  |
| Queue d'ecriture offline absente      | Ecritures echouent silencieusement en offline            | `bagtrip/lib/core/cache/`                                  |
| `PersonalizationColors` sans dark     | Couleurs uniquement light — illisible en dark mode       | `bagtrip/lib/design/personalization_colors.dart`           |
| `AppColors` statique non theme-aware  | Couleurs `static const` — ne s'adaptent pas au dark mode | `bagtrip/lib/design/app_colors.dart`                       |
| Golden tests light-only               | Aucune variante dark mode                                | `bagtrip/test/goldens/golden_helpers.dart`                 |
| Tests parite ARB absents              | Pas de test automatise EN/FR                             | `bagtrip/test/`                                            |
| Semantics formulaires absents         | Pas de labels VoiceOver sur les champs de saisie         | `bagtrip/lib/components/adaptive/`                         |
| Deep links notifications limites      | 3 ecrans sur ~10 geres                                   | `bagtrip/lib/notifications/widgets/notification_card.dart` |
| MapRoute placeholder                  | Pointe vers `MapComingSoonView`                          | `bagtrip/lib/navigation/route_definitions.dart:330`        |
| `AgentService` non implemente         | Deux methodes marquees TODO                              | `bagtrip/lib/service/agent_service.dart`                   |
| Tests integration repositories cached | Pas de tests verifiant le fallback offline               | `bagtrip/test/`                                            |


### Technique API


| Element                    | Description                                              | Fichier                                  |
| -------------------------- | -------------------------------------------------------- | ---------------------------------------- |
| Rate limiter in-memory     | Non distribue en multi-instance                          | `api/src/middleware/rate_limit.py:62-66` |
| IdempotencyCache in-memory | Commentaire : "pour POC, en production utiliser Redis"   | `api/src/utils/idempotency.py:67`        |
| Pas de circuit breaker     | Aucun circuit breaker sur Amadeus, AirLabs, Unsplash     | `api/src/integrations/`                  |
| Amadeus en mode test       | URL de base `test.api.amadeus.com`                       | `api/src/integrations/amadeus/`          |
| Pas de retry 429 Amadeus   | Pas de backoff sur rate limit Amadeus                    | `api/src/agent/tools.py`                 |
| Scheduler non distribue    | `asyncio.create_task()` — chaque worker execute ses jobs | `api/src/main.py:66-73`                  |


### Admin panel


| Element                    | Description                                                   | Fichier                                     |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------- |
| Tests unitaires absents    | Pas de Jest/Vitest                                            | `admin-panel/application/`                  |
| Pas d'i18n                 | Tout en francais en dur                                       | `admin-panel/application/src/`              |
| Pas de RBAC frontend       | Middleware verifie uniquement le cookie, pas le role          | `admin-panel/application/src/middleware.ts` |
| Search/filtres non exposes | `QueryParams` supporte search/sort mais non utilise dans l'UI | `admin-panel/application/src/features/`     |


---

## P2 — Nice to have (ameliorations)

### Base de donnees

- Soft delete non uniforme (seulement `trips.archived_at`)
- Index manquants sur certaines FK (`flight_orders.flight_offer_id`, `bookings.user_id`)
- Migration 0004 downgrade impossible (`NotImplementedError`)
- Table `bookings` deprecated encore presente (heritage Prisma camelCase)
- Pas de purge refresh tokens / Amadeus API logs

### Fonctionnel

- Pas de batch add suggestions IA activites (une a la fois)
- Bottom sheet suggestions iOS non-standard
- Batch update activites non utilise cote mobile
- Duplication `_groupByDay` dans `ActivityBloc` et `ActivitiesView`
- Couleurs categories activites en hex brut
- Pas de swipe entre jours dans la timeline
- Activite sans `endTime` = en cours indefiniment
- Pas de galerie photos post-trip
- Pas de pagination feedback API
- Pas de suppression/edition de feedback
- Pas d'export PDF (itineraire, budget, checklist bagages)
- Pas de tri/filtrage bagages par categorie
- Reordonnancement bagages non persiste (pas de champ `position`)
- Partage checklist entre voyageurs impossible
- Multi-devise budget absente
- Graphiques repartition budget absents
- Historique alertes budget non historise
- Pas de plan annuel Premium
- Pas de trial period Stripe
- Pas de receipts/factures
- Polling subscription fragile (5 tentatives 2s)
- Notification preferences/mute absentes
- Pas de suppression de notification
- Pas de badge d'app (compteur non-lus)
- `TRIP_SHARED` defini mais non implemente
- Notification revocation non envoyee
- Acceptation/refus invitation absents
- Badge de role non affiche dans l'UI partage
- Permissions granulaires manuelles (pas de middleware centralise)
- Listing "trips partages avec moi" non separe
- Pas de lien hotel → formulaire accommodation
- Photos hotels absentes
- Pas de carte map hebergements
- Streaming review partiel absent (attente event `complete`)
- Image destination non affichee dans la review wizard
- Pas de persistence brouillon wizard
- Pas de validation etape 1 (bouton Continuer toujours actif)
- `_sseSubscription` jamais assigne (trompeur)
- Weather fallback sans altitude/cotes/microclimats
- Booking model deprecated encore route
- Quick Action "Tomorrow" noop
- Endpoint `GET /{id}/home` non utilise (7 appels separes a la place)
- `FlightOrder` non exploite dans la vue detail
- Gestion erreurs Stripe avancee manquante (retry)
- Boarding pass sans QR code

### Technique mobile

- Typo `cornerRaidus` dans `tokens.dart`
- `AdaptiveIndicator` ignore ses parametres (`radius`, `color`)
- `CustomCalendarPicker` non adaptatif (Material brut partout)
- Pas de composant `AdaptiveSwitch`
- `DestinationCarousel` hauteur fixe 320px
- `ConnectivityService.dispose()` async dans dispose synchrone
- Pas de `BlocObserver` centralise
- Pas de retry automatique sur `NetworkError` dans `ApiClient`
- `$extra` perdu au refresh (fallback silencieux sur HomePage)
- `NavigationBloc` potentiellement inutilise
- Pas de guard role-based dans le redirect GoRouter
- Listener GoRouter dans `dispose()` potentiellement invalide
- Swipe-back non garanti sur `CustomTransitionPage` wizard
- Cache : pas de limite de taille / politique d'eviction LRU
- Cache : pas de prefetch au demarrage
- Test OfflineBanner absent
- Pas de tests multi-resolution (iPhone SE, tablettes)
- Pas de tests deep link en E2E complet
- Pas de tests concurrence cache
- Pas de tests performance / benchmark
- Mock MethodChannel absents
- Tests widget en FR absents
- Formatage dates non localise
- Contraste dark mode insuffisamment audite
- Focus management absent (navigation clavier/switch control)
- Support Dynamic Type au-dela de 1.5x non teste
- Labels bottom sheets VoiceOver absents
- Transition theme instantanee (pas d'animation)
- `GlassPanel` Android invisible en dark mode
- Couleur en dur `FeedbackFormView` (`0xFFF0F7FF`)
- `PremiumPaywall` titre hardcode en francais
- Hint "Hotel Marriott, Airbnb Le Marais..." non localise
- "Type to search" en anglais en dur
- "Ajouter vos filtres" en francais en dur
- Countdown "J-X" et "Jour X" en francais en dur

### Technique API

- `AmadeusApiLog` modele present mais jamais utilise
- AirLabs client synchrone (pas async)
- Cache Unsplash in-memory non distribue
- Monitoring webhooks Stripe sans alerte
- SSE deduplication fragile (`event_key`)
- Post-trip AI sans contexte activites (seulement feedbacks)
- Streaming LLM par noeud, pas token par token
- Fallback LLM basique (listes vides)
- Health check `/health` ne verifie pas la DB ni services externes
- Structured logging / correlation ID absent
- Graceful shutdown sessions DB absent
- Routes travel sans authentification
- Pagination manquante (accommodations, baggage, shares, feedback, manual flights)
- Validation schemas incomplete (format dates)
- Routes depreciees `/v1/booking/*` encore actives
- Documentation OpenAPI incomplete (manque summary/description)
- Apple Sign-In dev mode trop permissif
- Brute-force protection limitee (per-IP, pas per-account)
- Logging connexions absent (audit)
- Dependabot/Renovate non configure
- Cache Docker layers en CI absent
- Notifications d'echec CI non configurees
- Couverture API non configuree (seuil)

### Admin panel

- Dark mode supporte dans le store mais non utilise dans l'UI
- Sidebar dans le store mais non implementee
- Export CSV : service existe mais non accessible dans l'UI
- Pagination taille fixe (10) sans configuration utilisateur
- Tests securite middleware absents
- Monitoring/observabilite absent (Sentry, logging)
- Documentation endpoints `/admin/*` absente

---

## Statistiques

| Priorite | Nombre |
|----------|--------|
| P0 | 3 (17 - 3 securite ✅ - 6 features ✅ - 4 UX critique ✅ - 1 home & trip detail ✅) |
| P1 | 31 (62 - 6 creation voyage & IA ✅ - 6 home & trip detail ✅ - 3 donnees non persistees ✅ - 4 activites & in-trip ✅ - 3 vols & transports ✅ - 5 notifications ✅ - 2 partage ✅ - 2 paiements ✅) |
| P2 | 80+ |
| **Total** | **~160** |


### Repartition par domaine

| Domaine | P0 | P1 | P2 |
|---------|----|----|-----|
| Securite | ~~3~~ 0 ✅ | 1 | 3 |
| Infrastructure / CI/CD | 4 | 4 | 3 |
| Auth & compte | ~~2~~ 0 ✅ | 4 | 3 |
| Creation voyage & IA | ~~2~~ 0 ✅ | ~~6~~ 0 ✅ | 6 |
| Home & Trip Detail | ~~1~~ 0 ✅ | ~~5~~ 0 ✅ | 5 |
| Activites & In-Trip | 0 | ~~4~~ 0 ✅ | 5 |
| Vols & Transports | 0 | ~~3~~ 0 ✅ | 5 |
| Hebergements | 0 | 2 | 4 |
| Bagages & Budget | 1 | 2 | 7 |
| Notifications | 3 | ~~5~~ 0 ✅ | 5 |
| Partage | 0 | ~~2~~ 0 ✅ | 6 |
| Paiements | ~~2~~ 0 ✅ | ~~2~~ 0 ✅ | 5 |
| Post-trip | 0 | 5 | 3 |
| Profil | 0 | 2 | 2 |
| Technique mobile | 1 | 11 | 25+ |
| Technique API | 0 | 6 | 15+ |
| Admin panel | 0 | 4 | 7 |
