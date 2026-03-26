# Notifications

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le systeme de notifications de BagTrip repose sur deux mecanismes complementaires : les **notifications push server-side** (FCM via un job periodique backend) et les **notifications locales client-side** (programmees via `flutter_local_notifications` + `timezone`). Les notifications couvrent le cycle de vie complet du voyage : rappel de depart, alertes vol, resume matinal, rappels d'activite, alertes budget, rappels check-out, rappels de valise, et detection de fin de voyage. Cote utilisateur, un centre de notifications avec pagination, marquage lu/non-lu, et deep linking vers les ecrans concernes.

## Architecture

### Deux canaux de notification

| Canal | Source | Quand | Exemples |
|-------|--------|-------|----------|
| **Push FCM (server)** | Job backend toutes les 30 min | App fermee ou en background | Depart demain, vol dans 4h/1h, resume matinal, activite dans 1h, alerte budget |
| **Local (client)** | Schedule au moment de la transition ONGOING | App fermee, notifications programmees a l'avance | Resume quotidien 8h, activite dans 30 min, check-out 9h, valise J-2 18h, fin de voyage +24h |

La redondance est voulue : les notifications push couvrent les cas ou l'utilisateur n'ouvre pas l'app, et les notifications locales garantissent la precision temporelle meme sans connectivite.

## Notifications Push (Server-Side)

### Job de notification (`api/src/jobs/notification_job.py`)

Le scheduler `notification_scheduler()` tourne en boucle async toutes les 30 minutes (`INTERVAL_SECONDS = 1800`). Il execute 5 checks sequentiels :

#### 1. Rappel de depart (`DEPARTURE_REMINDER`)

- **Condition** : trip PLANNED avec `start_date = demain`
- **Contenu** : "Depart demain ! Votre voyage [...] commence demain. Bagages : X/Y prepares."
- **Enrichissement** : comptage des items bagages packed/total via `BaggageItem`
- **Deep link** : `screen: "tripHome"`
- **Deduplication** : `_already_sent` avec fenetre 20h

#### 2. Alerte vol H-4 (`FLIGHT_H4`)

- **Condition** : `FlightOrder` confirme dont le vol decolle dans 3.5h-4.5h
- **Contenu** : "Vol dans ~4h. Votre vol pour [...] decolle bientot !"
- **Enrichissement** : URL du billet (`ticket_url`) si disponible
- **Deep link** : `screen: "tripHome"`, `orderId`, `ticketUrl`
- **Deduplication** : 5h par `orderId`

#### 3. Alerte vol H-1 (`FLIGHT_H1`)

- **Condition** : `FlightOrder` confirme dont le vol decolle dans 0.5h-1.5h
- **Contenu** : "Vol dans ~1h" + info terminal/porte si disponible
- **Enrichissement** : terminal extrait de `offer_json.itineraries[0].segments[0].departure.terminal`
- **Deep link** : `screen: "tripHome"`, `orderId`

#### 4. Resume matinal (`MORNING_SUMMARY`)

- **Condition** : trip ONGOING, activites aujourd'hui, entre 7h00 et 7h30 UTC
- **Contenu** : "Programme du jour — {destination}. X activite(s) prevue(s) : nom1, nom2, nom3 (+N)"
- **Limite** : affiche les 3 premieres activites
- **Deep link** : `screen: "activities"`
- **Deduplication** : 20h

#### 5. Rappel activite H-1 (`ACTIVITY_H1`)

- **Condition** : activite aujourd'hui avec `start_time` dans 30min-90min
- **Contenu** : "Activite dans ~1h. « {titre} » commence bientot ! [a {lieu}]"
- **Deep link** : `screen: "activities"`, `activityId`
- **Deduplication** : 2h par `activityId`

### Alerte budget (`BUDGET_ALERT`)

Declenchee a la demande par `NotificationService.check_and_send_budget_alert()` (pas dans le job periodique mais appelee depuis le service budget) :
- **Niveaux** : WARNING et CRITICAL
- **Contenu** : "Alerte budget" ou "Budget depasse !" + pourcentage consomme
- **Deep link** : `screen: "budget"`, `alertLevel`
- **Deduplication** : 1h par niveau

### Service de notification (`api/src/services/notification_service.py`)

`NotificationService` gere :

| Methode | Description |
|---------|-------------|
| `create_and_send()` | Cree en DB + envoie FCM unicast |
| `create_and_send_bulk()` | Cree pour plusieurs users + envoie FCM multicast |
| `get_for_user()` | Liste paginee + comptage non-lus |
| `get_unread_count()` | Comptage non-lus pour badge |
| `mark_as_read()` | Marque une notification comme lue |
| `mark_all_as_read()` | Marque toutes comme lues (update bulk) |
| `_get_trip_recipients()` | Owner + viewers via `TripShare` |
| `_send_fcm()` | Envoi FCM via `firebase_admin.messaging` |
| `_already_sent()` | Deduplication temporelle par type/trip/data |

**Gestion FCM** :
- Unicast via `messaging.send(Message)` pour 1 token
- Multicast via `messaging.send_each_for_multicast(MulticastMessage)` pour N tokens
- Nettoyage automatique des tokens invalides (`UnregisteredError` -> suppression du `DeviceToken` en DB)
- `sent_at` est mis a jour apres envoi reussi

### Modele Notification (DB)

`api/src/models/notification.py` — table `notifications` :

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | PK |
| `user_id` | UUID FK | Destinataire |
| `trip_id` | UUID FK | Trip associe (optionnel) |
| `type` | String | Type de notification (enum) |
| `title` | String | Titre |
| `body` | String | Corps |
| `data` | JSON | Donnees de deep link |
| `is_read` | Boolean | Lu/non-lu |
| `sent_at` | DateTime | Date d'envoi FCM |
| `created_at` | DateTime | Date de creation |

### Types de notification (enum)

Definis dans `api/src/enums.py` :

| Type | Description |
|------|-------------|
| `DEPARTURE_REMINDER` | Depart demain |
| `FLIGHT_H4` | Vol dans 4h |
| `FLIGHT_H1` | Vol dans 1h |
| `MORNING_SUMMARY` | Resume matinal |
| `ACTIVITY_H1` | Activite dans 1h |
| `TRIP_STARTED` | Voyage demarre |
| `TRIP_ENDED` | Voyage termine |
| `BUDGET_ALERT` | Alerte budget |
| `TRIP_SHARED` | Trip partage |
| `ADMIN` | Notification admin |

## Notifications Locales (Client-Side)

### LocalNotificationService

`bagtrip/lib/service/local_notification_service.dart` — wrapper statique autour de `FlutterLocalNotificationsPlugin` :

- **Initialisation** : timezone database + settings Android/iOS (permissions demandees separement)
- **Canaux Android** : `bagtrip_notifications` (generique) et `bagtrip_trip_reminders` (rappels programmes)
- **show()** : notification immediate
- **zonedSchedule()** : notification programmee a une `TZDateTime` precise, avec `AndroidScheduleMode.inexactAllowWhileIdle`
- **cancel(id)** / **cancelAll()** : annulation
- **Tap handling** : callback `onDidReceiveNotificationResponse` avec payload JSON

### TripNotificationScheduler

`bagtrip/lib/service/trip_notification_scheduler.dart` — service metier qui schedule les notifications en fonction de l'etat du trip :

#### scheduleOngoingNotifications(trip)

Idempotent (annule puis reschedule). Programme :

1. **Resumes quotidiens a 8h** : pour chaque jour restant du trip, titre "Bonjour !", corps "Jour X a {destination}", deep link `tripHome`
2. **Rappels activite 30 min avant** : pour chaque activite avec `startTime`, titre "Bientot : {titre}", corps "Dans 30 minutes [a {lieu}]", deep link `activities`
3. **Rappels check-out a 9h** : pour chaque hebergement avec `checkOut`, titre "Rappel check-out", corps "N'oubliez pas de quitter {nom}", deep link `tripHome`

#### schedulePackingReminder(trip)

Programme a J-2 18h avant le depart :
- Compte les items bagages non-packed
- Si count > 0 : "C'est l'heure de faire les valises ! {count} articles restants pour {destination}"
- Deep link : `baggage`

#### scheduleCompletionReminder(trip)

Programme a now + 24h (apres un dismiss de la completion) :
- "Voyage termine ? Votre voyage a {destination} semble termine. Voulez-vous le cloturer ?"
- Deep link : `tripHome`

#### cancelTripNotifications(trip)

Annule toutes les notifications d'un trip en recalculant les IDs : packing, completion, daily summaries (par jour), activity reminders (par activity ID), checkout reminders (par accommodation ID).

#### Algorithme d'ID stable

`stableId(key)` utilise un hash djb2 sur la cle string pour generer un ID 31-bit positif deterministe. Cela evite de persister une liste d'IDs de notifications.

### NotificationStrings

`bagtrip/lib/service/notification_strings.dart` — textes bilingues (FR/EN) resolus via `Intl.defaultLocale` au moment du scheduling :

| Notification | FR | EN |
|-------------|----|----|
| Daily summary | "Bonjour !" / "Jour X a Y" | "Good morning!" / "Day X in Y" |
| Activity reminder | "Bientot : {titre}" | "Coming up: {title}" |
| Checkout | "Rappel check-out" | "Checkout reminder" |
| Packing | "C'est l'heure de faire les valises !" | "Time to pack!" |
| Completion | "Voyage termine ?" | "Trip over?" |

## Device Tokens FCM

### API (`api/src/api/device_tokens/routes.py`)

| Methode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/v1/device-tokens` | Enregistrer un token FCM |
| `DELETE` | `/v1/device-tokens/{token}` | Supprimer un token |

### Schema

- `DeviceTokenRegisterRequest` : `fcmToken` (requis), `platform` (optionnel)
- `DeviceTokenResponse` : `id`, `fcmToken`, `platform`, `createdAt`

### Cote mobile

`NotificationRepositoryImpl` (`bagtrip/lib/service/notification_service.dart`) expose :
- `registerDeviceToken(fcmToken, platform)` : POST best-effort (erreurs silencieuses)
- `unregisterDeviceToken(fcmToken)` : DELETE best-effort

## Centre de Notifications (Mobile)

### NotificationBloc

`bagtrip/lib/notifications/bloc/notification_bloc.dart` — gere 6 events :

| Event | Description |
|-------|-------------|
| `LoadNotifications` | Charge la premiere page |
| `LoadMoreNotifications` | Pagination |
| `LoadUnreadCount` | Comptage badge |
| `MarkNotificationRead` | Marquer une notif lue |
| `MarkAllRead` | Marquer toutes lues |
| `NotificationReceived` | Push recue -> refresh count |

Le `NotificationBloc` est instancie au niveau app (persistant).

### NotificationsView

`bagtrip/lib/notifications/view/notifications_view.dart` — ecran avec :
- AppBar avec bouton "Tout marquer comme lu" (visible si `unreadCount > 0`)
- `PaginatedList<AppNotification>` avec groupement par date (Aujourd'hui, Hier, Il y a X jours)
- `ElegantEmptyState` si vide
- Padding iOS adaptatif (100px)

### NotificationCard

`bagtrip/lib/notifications/widgets/notification_card.dart` — affiche :
- Icone circulaire coloree par type (avion, soleil, event, wallet, check)
- Titre en gras si non-lu, normal sinon
- Corps (2 lignes max)
- Temps relatif ("A l'instant", "Il y a Xmin", "Il y a Xh", "Il y a Xj")
- Indicateur point bleu pour non-lu

### Deep Linking

Au tap sur une notification :
1. Marque comme lue (`MarkNotificationRead`)
2. Parse le champ `data` pour extraire `screen` et `tripId`
3. Navigation selon `screen` :

| Screen | Route |
|--------|-------|
| `tripHome` | `TripHomeRoute(tripId)` |
| `activities` | `ActivitiesRoute(tripId)` |
| `budget` | `BudgetRoute(tripId)` |
| `feedback` | `FeedbackRoute(tripId)` |
| default | `TripHomeRoute(tripId)` |

### Modele AppNotification (Flutter)

`bagtrip/lib/models/notification.dart` (Freezed) : `id`, `type`, `title`, `body`, `data` (Map?), `isRead`, `tripId`, `sentAt`, `createdAt`.

## Fichier ActivityPage (doublon)

`bagtrip/lib/notifications/view/activity_page.dart` est un doublon de `NotificationsPage` qui fait exactement la meme chose (fire `LoadNotifications` et rend `NotificationsView`). Son nom est trompeur.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Temps relatif en dur | `NotificationCard._relativeTime()` utilise des strings francais en dur ("A l'instant", "Il y a X min") au lieu de l10n (`bagtrip/lib/notifications/widgets/notification_card.dart` l.171-175) | P1 |
| Fichier doublon activity_page.dart | `bagtrip/lib/notifications/view/activity_page.dart` est un doublon exact de `notifications_page.dart` avec un nom trompeur — devrait etre supprime | P1 |
| Pas de suppression de notifications | L'utilisateur ne peut pas supprimer une notification individuelle — pas d'endpoint DELETE ni de swipe-to-delete | P2 |
| Pas de preferences de notification | L'utilisateur ne peut pas desactiver certains types de notifications (ex: desactiver les alertes budget) — pas de page de settings notifications | P2 |
| Resume matinal timezone | Le check `_check_morning_summary` utilise 7h-7h30 UTC sans ajustement au fuseau horaire de la destination — un utilisateur a Tokyo (UTC+9) recoit son resume a 16h locales (`api/src/jobs/notification_job.py` l.178) | P0 |
| Alertes vol timezone | `_extract_departure_time` parse le `at` de l'itineraire et force UTC, mais les horaires Amadeus sont souvent en heure locale — risque de decalage des alertes H-4/H-1 (`api/src/jobs/notification_job.py` l.142) | P0 |
| Deep link baggage/map manquants | Les notifications locales de packing et checkout deeplink vers `tripHome` ou `baggage`, mais `baggage` et `map` ne sont pas geres dans `NotificationCard._onTap()` (`bagtrip/lib/notifications/widgets/notification_card.dart` l.151-166) | P1 |
| Pas de badge d'app | Le compteur non-lu met a jour l'UI mais ne met pas a jour le badge de l'icone de l'app (iOS badge number via `FlutterAppBadger` ou equivalent) | P2 |
| Tests notifications | Pas de tests pour `NotificationBloc`, `TripNotificationScheduler` dans le repertoire test | P1 |
| Notification locale tap non-routed | Le payload JSON des notifications locales contient `screen` et `tripId`, mais le callback `onNotificationTap` dans `LocalNotificationService.initialize()` n'est pas connecte au routeur GoRouter — le tap sur une notification locale ne navigue pas | P0 |
| TRIP_STARTED non-utilise | Le type `TRIP_STARTED` est defini dans l'enum mais n'est envoye nulle part dans le code | P2 |
| TRIP_SHARED non-implemente | Le type `TRIP_SHARED` est defini dans l'enum mais la notification n'est pas envoyee lors du partage d'un trip | P2 |
