# Notifications

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Le systeme de notifications de BagTrip est **entierement pilote par le backend** (refactor SMP-326 : `localized notifications` + nettoyage FCM cote mobile). Le serveur decide *quoi* envoyer, *quand* l'envoyer et *dans quelle langue*, puis pousse le payload via Firebase Cloud Messaging. Le client Flutter se contente d'afficher, de relayer en foreground et de deep-linker vers l'ecran cible.

Trois canaux co-existent :

- **Push FCM (backend)** — un scheduler Python (`notification_job.py`) tourne toutes les 30 minutes, protege par un lock Redis distribue, et balaie les voyages pour declencher les rappels temporels (depart demain, vol H-4/H-1, resume matinal, activite H-1). Les transitions de statut (`PLANNED -> ONGOING`, `ONGOING -> COMPLETED`) emettent `TRIP_STARTED` / `TRIP_ENDED` depuis `TripsService.auto_transition_statuses`. Les alertes budget partent en hook depuis le service budget.
- **In-app history (backend)** — chaque push est persiste dans la table `notifications`. Le mobile expose une liste paginee + badge non-lu via `/v1/notifications`.
- **Local notifications (mobile, periphrastique)** — `flutter_local_notifications` n'est plus utilise pour *programmer* des rappels. Il sert uniquement a **relayer en foreground** une push FCM recue alors que l'app est ouverte (Android/iOS suppriment la banniere automatique dans ce cas), et a propager le payload au tap handler. Aucun ID stable, aucun scheduling cote client.

La localisation est resolue par le backend a partir du `locale` stocke sur le `DeviceToken` le plus recent du destinataire (`DeviceTokenService.get_locale_for_user`). Fallback vers `en` si absent. Catalogue de strings dans `src/services/notification_messages.py` (un dict `{cle.title|body: {fr, en}}`), rendu via `render_notification(key, locale, **ctx)` qui fait un simple `.format(**ctx)` sur le template choisi. Le scheduler n'assemble jamais de phrases manuellement — il ne fournit que le `ctx` (titres voyage, comptages, suffixes).

**Pourquoi backend-owned ?** Le timing des notifications depend de donnees serveur (statut du voyage, ordre de vol confirme, items budget) qui evoluent independamment du device. Le scheduler centralise la dedup, la resolution des destinataires (owner + viewers via `TripShare`) et la localisation. Le client n'a aucun etat a maintenir : pas de queue d'IDs locaux a invalider sur changement de trip, pas de re-scheduling apres edit, pas de risque de drift entre devices.

## Cote Backend

### Endpoints REST

| Methode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/v1/notifications` | Liste paginee (`page`, `limit`) + comptage non-lus |
| `GET` | `/v1/notifications/unread-count` | Compteur badge |
| `PATCH` | `/v1/notifications/{notificationId}/read` | Marquer une notif lue |
| `POST` | `/v1/notifications/read-all` | Marquer toutes lues (retourne `{updated: N}`) |
| `POST` | `/v1/device-tokens` | Enregistrer un token FCM (upsert sur `fcmToken`) |
| `DELETE` | `/v1/device-tokens` | Supprimer un token (token dans le body, jamais l'URL, pour ne pas fuiter dans les logs) |

Toutes les routes passent par `get_current_user` et `@handle_app_errors`. Pagination via la dependency standard `PaginationParams`.

### NotificationService (`src/services/notification_service.py`)

| Methode | Role |
|---------|------|
| `create_and_send()` | Insert DB + push unicast FCM. Met a jour `sent_at` si l'envoi reussit. |
| `create_and_send_bulk()` | Insert N rows + multicast FCM. Nettoie les tokens invalides. |
| `send_localized()` | **Point d'entree unique pour le scheduler** — resout le `locale` du destinataire, rend `title`/`body` depuis le catalogue i18n via `render_notification(notif_key, locale, **ctx)`, delegue a `create_and_send`. Le `notif_key` (catalogue) peut differer du `notif_type` (enum DB) — utile pour les variantes budget (`BUDGET_ALERT_WARNING` / `BUDGET_ALERT_EXCEEDED` partagent le type `BUDGET_ALERT`). |
| `get_for_user()` | Liste paginee + total + total_pages + unread_count en une passe. |
| `get_unread_count()` | Compteur badge. |
| `mark_as_read()` / `mark_all_as_read()` | Update simple / bulk. |
| `check_and_send_budget_alert()` | Appele depuis `BudgetItemService` apres une mutation de depense. Dedup sur `BUDGET_ALERT` + `data.alertLevel` (un `WARNING` ne supprime pas un `EXCEEDED`). |
| `_get_trip_recipients()` | Owner + viewers via `trip.shares` (lit la relation, eager-loaded par les callers). |
| `_send_fcm()` | Envoi FCM (`messaging.send` ou `messaging.send_each_for_multicast`). Sur `UnregisteredError`, supprime le `DeviceToken` correspondant. Si Firebase n'est pas initialise, log un warn et skip silencieusement. |
| `_already_sent()` | Deduplication temporelle par `(user, trip, type)` + filtre optionnel sur une cle JSON (`orderId`, `activityId`, `alertLevel`). |

### DeviceTokenService

`register()` fait un upsert : si le `fcm_token` existe deja, met a jour `user_id`, `platform`, `locale` (normalise via `normalize_locale`). Sinon insertion. `get_locale_for_user()` lit le `DeviceToken` le plus recemment mis a jour ; fallback `"en"`.

### Scheduler (`src/jobs/notification_job.py`)

Boucle `asyncio` lancee depuis le lifespan FastAPI, intervalle 30 min. Chaque tick :

1. Acquiert `redis_lock("job:notification", ttl_seconds=2*INTERVAL)`. Si un autre worker tient deja le lock, log et skip.
2. Lance `run_notification_checks()` dans un thread pool (`asyncio.to_thread`) — le code DB est sync.
3. Execute 5 checks dans l'ordre : `departure_reminders` -> `flight_h4` -> `flight_h1` -> `morning_summary` -> `activity_h1`.

Chaque check :
- Filtre les voyages eligibles avec un eager loading explicite (`selectinload(Trip.shares)`, `joinedload(FlightOrder.flight_offer)`, `selectinload(Activity.trip).selectinload(Trip.shares)`) pour eviter le N+1 sur les listes de destinataires.
- Resout les destinataires via `_get_trip_recipients()` (owner + viewers).
- Pour chaque destinataire : test `_already_sent()`, resolution `locale`, appel `send_localized()` avec le contexte rendu (titre voyage, statut bagages, suffixe terminal, etc.). Le rendu i18n est entierement deportable cote catalogue (`notification_messages.py`).

Specificite **MORNING_SUMMARY** : la fenetre 07h-10h est evaluee dans le **fuseau horaire de la destination** (`trip.destination_timezone`) et non en UTC. La dedup 20h + la largeur 3h absorbent le drift +/- 30 min du scheduler.

Le job **TRIP_STARTED / TRIP_ENDED** vit ailleurs : `trip_status_job.py` tourne une fois par jour a minuit UTC, sous un autre lock (`job:trip_status`, TTL 10 min). Il delegue a `TripsService.auto_transition_statuses` qui (1) bulk-update les statuts via `UPDATE trips SET status = ...`, (2) capture les voyages affectes *avant* l'update, (3) emet `TRIP_STARTED` (`screen: tripHome`) ou `TRIP_ENDED` (`screen: feedback`) via `_dispatch_trip_notification` aux owners + viewers.

### Distributed lock (`src/utils/distributed_lock.py`)

`redis_lock(name, ttl_seconds)` est un async context manager qui yield un `bool` "lock acquis". Implementation :

- `SET lock:{name} {uuid} NX EX {ttl}` — atomique, un seul worker reussit.
- Release via script Lua CAS : `if get(KEYS[1]) == ARGV[1] then del(KEYS[1])` — empeche un worker en retard de liberer le lock d'un successeur qui le tient deja (foot-gun classique "lock TTL expire pendant que worker A boucle, worker B prend le lock, worker A le release").
- **Fallback Redis indisponible** : yield `True` quand-meme, log un warn une seule fois par nom de lock. Mono-worker dev OK ; multi-workers sans Redis = duplications acceptees (warn explicite).

### Catalogue i18n (`src/services/notification_messages.py`)

Dictionnaire plat `{cle.title|body: {fr, en}}` avec helpers de rendu (`render_notification`) et de suffixe contextuel (`baggage_status`, `activity_location_suffix`, `flight_ticket_suffix`, `flight_gate_suffix`, `untitled_trip`, `normalize_locale`). Cles principales :

- `DEPARTURE_REMINDER.title|body` — utilise `{trip_title}`, `{baggage_status}`
- `FLIGHT_H4.body|FLIGHT_H1.body` — utilise `{trip_title}`, `{ticket_suffix}`, `{gate_suffix}`
- `MORNING_SUMMARY.body` — utilise `{trip_title}`, `{count}`, `{activity_names}`
- `ACTIVITY_H1.body` — utilise `{activity_title}`, `{location_suffix}`
- `TRIP_STARTED.title|body` / `TRIP_ENDED.title|body`
- `BUDGET_ALERT_WARNING.*` / `BUDGET_ALERT_EXCEEDED.*` — note le decouplage entre la cle catalogue et la valeur enum `BUDGET_ALERT` persistee en DB

Toute modification d'un libelle se fait uniquement dans ce fichier — pas de string-en-dur dans les jobs ni dans `NotificationService`. Le `locale` recu est normalise (`fr-FR -> fr`, `en-US -> en`, defaut `en`).

### Firebase (`src/integrations/firebase/__init__.py`)

Init globale au boot via `FIREBASE_SERVICE_ACCOUNT_PATH`. `get_firebase_app()` retourne `None` si le path est absent ou si l'init a echoue — `_send_fcm` log "Firebase not initialized" et skip. Pas de crash au boot quand la cle n'est pas montee (env dev).

### Modele DB (`notifications`)

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `id` | UUID | non | PK |
| `user_id` | UUID FK `users.id` | non | Destinataire, indexe |
| `trip_id` | UUID FK `trips.id` | oui | Voyage associe, indexe |
| `type` | String | non | Valeur de `NotificationType` |
| `title` / `body` | String | non | Texte rendu (deja localise) |
| `data` | JSONB | oui | Payload deep-link (`screen`, `tripId`, `orderId`, `activityId`, `alertLevel`, `ticketUrl`...) |
| `is_read` | Boolean | non | Defaut `False` |
| `sent_at` | DateTime tz | oui | Renseigne apres envoi FCM reussi |
| `created_at` | DateTime tz | non | `server_default=func.now()` |

## Cote Mobile

### NotificationBloc (`bagtrip/lib/notifications/bloc/notification_bloc.dart`)

Gere uniquement la **liste paginee** (events `LoadNotifications`, `LoadMoreNotifications`, `MarkNotificationRead`, `MarkAllRead`, `ResetNotifications`). Le badge non-lu vit dans `NotificationCountCubit` separe — separation explicite ajoutee en SMP-326. Pattern matching `Result<T>` partout, optimistic update sur `MarkNotificationRead` (decremente `unreadCount` localement avant la prochaine list refresh).

`NotificationsPage` fire `LoadNotifications()` au build et installe un `BlocListener` qui synchronise `NotificationCountCubit` depuis chaque `NotificationsLoaded` (un load et un mark-as-read re-emettent un compteur frais — la cubic et le bloc restent ainsi en phase sans event ad-hoc).

`NotificationsView` rend un `PaginatedList<AppNotification>` avec :
- Bouton AppBar "Tout marquer comme lu" visible quand `unreadCount > 0`.
- Groupement par date (`notificationsToday`, `notificationsYesterday`, `notificationsDaysAgo(n)`, `dd/mm/yyyy`).
- `ElegantEmptyState` si vide.
- Padding iOS adaptatif (100 px pour la GlassBottomBar).

### FCM init (`main.dart`)

Au cold start :
- `Firebase.initializeApp()` + handler background top-level (`_firebaseMessagingBackgroundHandler`) annote `@pragma('vm:entry-point')`.
- `LocalNotificationService.initialize(onNotificationTap: _handleLocalNotificationTap)`.
- Aucune demande de permission a froid — elle est demandee **apres** authentification (cf. `AuthBloc`).

Au `_setupFCMListeners()` dans `_MyAppState` :
- `FirebaseMessaging.onMessage` (foreground) : appelle `LocalNotificationService.show(...)` pour relayer une banniere (FCM n'en dessine pas en foreground) avec le `message.data` comme payload, puis `_countCubit.refresh()`.
- `FirebaseMessaging.onMessageOpenedApp` (tap depuis background) : route via `_handleRemoteMessageTap(message)`.
- `FirebaseMessaging.instance.getInitialMessage()` (cold start depuis push terminee) : meme handler.
- `FirebaseMessaging.instance.onTokenRefresh` : re-enregistre le nouveau token via `NotificationRepository.registerDeviceToken(token, platform, locale)`. Le `locale` provient de `PlatformDispatcher.instance.locale.languageCode` — c'est ce qui alimente la resolution `DeviceTokenService.get_locale_for_user` cote backend.

### LocalNotificationService (`bagtrip/lib/service/local_notification_service.dart`)

Wrapper minimaliste autour de `flutter_local_notifications`. Apres SMP-326 le scope est strictement reduit :
- `initialize({onNotificationTap})` : settings Android `@mipmap/ic_launcher` + iOS sans demande de permission (la permission FCM la couvre).
- `show({id, title, body, payload})` : banniere immediate, payload JSON-encode pour le tap handler. Utilise par le seul cas "FCM foreground relay".
- **Plus de `zonedSchedule`, plus de canal `bagtrip_trip_reminders`, plus de `TripNotificationScheduler`** — le backend possede toute la logique de timing.

### Deep link (`bagtrip/lib/notifications/notification_deep_link.dart`)

`resolveNotificationRoute(Map<String, dynamic>? data) -> String?` est la **single source of truth** pour mapper un payload vers une route GoRouter. Utilise par les 4 entry points : tap sur notif locale (foreground), tap sur push background, cold start depuis push, tap dans la liste in-app.

Vocabulaire `screen` (impose par le backend) :

| `data.screen` | Route |
|---------------|-------|
| `tripHome` (defaut) | `TripHomeRoute(tripId)` |
| `feedback` | `FeedbackRoute(tripId)` |
| `post-trip` | `PostTripRoute(tripId)` |
| `baggage` | `BaggageRoute(tripId)` |
| `accommodations` | `AccommodationsRoute(tripId)` |
| `map` | `MapRoute(tripId)` |
| `activities` / `budget` / inconnu | retombe sur `TripHomeRoute(tripId)` (la surface trip detail) |

Sans `tripId` exploitable, retourne `null` : le caller ne navigue pas plutot que de naviguer au mauvais endroit.

## Types de notifications

| `NotificationType` | Source | Deep link `screen` | Dedup |
|--------------------|--------|--------------------|-------|
| `DEPARTURE_REMINDER` | `notification_job._check_departure_reminders` (J-1) | `tripHome` | 20h par trip |
| `FLIGHT_H4` | `notification_job._check_flight_alerts(4h)` | `tripHome` (+ `ticketUrl` si dispo) | 5h par `orderId` |
| `FLIGHT_H1` | `notification_job._check_flight_alerts(1h)` | `tripHome` (+ terminal si dispo) | 5h par `orderId` |
| `MORNING_SUMMARY` | `notification_job._check_morning_summary` (07h-10h locale destination) | `activities` | 20h par trip |
| `ACTIVITY_H1` | `notification_job._check_activity_reminders` (T-30min a T-1h30) | `activities` (+ `activityId`) | 2h par `activityId` |
| `TRIP_STARTED` | `TripsService.auto_transition_statuses` (PLANNED -> ONGOING) | `tripHome` | une fois (transition unique) |
| `TRIP_ENDED` | `TripsService.auto_transition_statuses` (ONGOING -> COMPLETED) | `feedback` | une fois (transition unique) |
| `BUDGET_ALERT` | `NotificationService.check_and_send_budget_alert` (hook post-mutation) | `budget` (+ `alertLevel`) | 1h par `alertLevel` |
| `TRIP_SHARED` | (defini dans l'enum, pas encore emis) | n/a | n/a |
| `ADMIN` | broadcast manuel depuis l'admin panel | configurable | n/a |

## Flux

### Push backend -> mobile

1. Le scheduler detecte une condition (ex: vol dans ~4h pour un `FlightOrder` confirme).
2. Pour chaque destinataire (`owner + viewers`), check `_already_sent`. Si OK, resolution `locale` via `DeviceTokenService.get_locale_for_user`.
3. `send_localized()` rend `title`/`body` depuis le catalogue, insert un `Notification` en DB, recupere les `fcm_token` de l'utilisateur, push via FCM unicast/multicast.
4. Sur succes : update `sent_at`. Sur `UnregisteredError` : delete du `DeviceToken` orphelin.
5. FCM delivre le message au device.

### Enregistrement du token au login

1. L'utilisateur s'authentifie -> `AuthBloc` demande la permission FCM (iOS uniquement, Android la donne par defaut < 13).
2. Recupere le token via `FirebaseMessaging.instance.getToken()`.
3. POST `/v1/device-tokens` avec `{fcmToken, platform: 'ios'|'android', locale: <languageCode>}`. Upsert cote backend.
4. Listener `onTokenRefresh` re-poste a chaque rotation FCM (changement d'app reinstall, restore de backup, expiration cote Firebase). Best-effort, erreurs silencieuses (logguees).
5. Au logout : DELETE `/v1/device-tokens` avec `{fcmToken}` dans le body. Token reste exploitable par d'autres users si re-login sur le meme device.

### Reception et navigation cote mobile

- **App ouverte (foreground)** : `onMessage` -> `LocalNotificationService.show` avec `message.data` en payload + `NotificationCountCubit.refresh()`. Si l'utilisateur tape la banniere relayee, `onDidReceiveNotificationResponse` decode le JSON et appelle `_handleLocalNotificationTap` -> `resolveNotificationRoute` -> `appRouter.go(route)`.
- **App en background** : la banniere systeme s'affiche directement (FCM). Tap -> `onMessageOpenedApp` -> `_handleRemoteMessageTap(message)` -> `resolveNotificationRoute(message.data)` -> navigation.
- **App tuee** : tap depuis le centre de notifications systeme -> cold start, `getInitialMessage()` retourne le payload, meme handler que background.
- **Liste in-app** : tap sur une `NotificationCard` -> dispatch `MarkNotificationRead(id)` + `resolveNotificationRoute(notification.data)`.

### Cycle de vie d'une `NotificationCard`

1. Render depuis `NotificationsLoaded.notifications` (paginated). Le style change selon `isRead` : titre gras + point bleu si non-lu.
2. Tap -> `NotificationBloc.add(MarkNotificationRead(id))` + `resolveNotificationRoute(notification.data)` -> `appRouter.go(route)` si non-null.
3. Optimistic update : le bloc decremente `unreadCount` localement (pas de roundtrip avant la nav).
4. La cubic `NotificationCountCubit` recupere la nouvelle valeur via le `BlocListener` de la page.
5. Le push backend (PATCH `/v1/notifications/{id}/read`) persiste l'etat. Echec = `NotificationError` (silencieux apres navigation).

### Lock multi-worker

`uvicorn --workers N` lance N copies du lifespan, donc N copies des schedulers. Sans lock, chaque tick a 30 min emet N pushes au lieu d'un. Sequence avec `redis_lock` :

1. Worker A `SET lock:job:notification {tokenA} NX EX 3600` -> OK (acquired=True).
2. Worker B `SET ... NX EX ...` -> NULL (acquired=False), log "Lock held by peer worker, skipping tick".
3. Worker A execute `run_notification_checks`, puis Lua CAS release (`del` seulement si la valeur est encore `tokenA`).
4. Au tick suivant, n'importe quel worker peut prendre le lock — pas d'affinite.

Si Redis tombe : fallback "yield True", warn une seule fois par lock name. Acceptable en dev mono-worker, dangereux en prod multi-workers (cf. notes du module).

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `TRIP_SHARED` non emis | Le type est dans l'enum + un libelle existe dans le catalogue, mais aucun appelant ne le dispatche depuis le service de partage. | P2 |
| Pas de suppression cote utilisateur | Pas d'endpoint `DELETE /v1/notifications/{id}` ni de swipe-to-delete dans la liste. | P2 |
| Pas de preferences par type | Aucun ecran pour desactiver une categorie (ex: couper `MORNING_SUMMARY`). Tout-ou-rien via la permission systeme. | P2 |
| Badge applicatif (iOS) | Le `NotificationCountCubit` met l'UI a jour mais ne propage pas le compteur au badge de l'icone iOS (manque `FlutterAppBadger` ou equivalent). | P2 |
| Flight times en UTC force | `_extract_departure_time` force `tzinfo=UTC` sur le `at` d'Amadeus alors que la valeur est souvent en heure locale aeroport. Risque de decalage des H-4 / H-1 selon le fuseau. | P0 |
| Catalogue i18n FR incomplet | Certaines cles tombent en fallback EN. Verifier la couverture complete dans `notification_messages.py`. | P1 |
| Tests scheduler | Pas de tests dedies au lock distribue (mode acquired / busy / fallback Redis down) ni a la boucle complete du scheduler. | P1 |
| Limite copy FCM | Les libelles longs peuvent etre tronques par iOS (~178 chars) — pas de garde de longueur cote rendu. | P2 |
