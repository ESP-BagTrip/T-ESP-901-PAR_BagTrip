# Background Jobs & Notifications

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'API BagTrip execute deux background jobs lances comme `asyncio` tasks dans le lifespan de l'application FastAPI :

1. **Trip Status Job** — Transition automatique des statuts de trips (quotidien)
2. **Notification Job** — Verification et envoi de notifications planifiees (toutes les 30 minutes)

Les jobs s'executent en thread separe via `asyncio.to_thread()` pour ne pas bloquer la boucle d'evenements async principale. Ils sont annules proprement au shutdown via `CancelledError`.

## Trip Status Job

**Fichier** : `api/src/jobs/trip_status_job.py`

### Fonctionnement

Le scheduler verifie quotidiennement (a minuit UTC) si des trips doivent changer de statut automatiquement :

- **PLANNED → ONGOING** : quand `start_date <= today`
- **ONGOING → COMPLETED** : quand `end_date < today`

### Implementation

```python
async def trip_status_scheduler():
    while True:
        run_trip_status_transitions()  # sync, via asyncio.to_thread
        sleep_secs = _seconds_until_midnight_utc()
        await asyncio.sleep(sleep_secs)
```

- **Premiere execution** : au demarrage de l'application
- **Executions suivantes** : a chaque minuit UTC
- **Calcul du delai** : `_seconds_until_midnight_utc()` calcule le nombre de secondes jusqu'au prochain minuit UTC

### Service utilise

`TripsService.auto_transition_statuses(db)` effectue les deux updates en bulk :
1. `UPDATE trips SET status = 'ONGOING' WHERE status = 'PLANNED' AND start_date <= today`
2. `UPDATE trips SET status = 'COMPLETED' WHERE status = 'ONGOING' AND end_date < today`

Retourne un tuple `(planned_to_ongoing_count, ongoing_to_completed_count)`.

### Logging

Tag : `[TRIP_STATUS_JOB]`

Logs a chaque execution :
```
[TRIP_STATUS_JOB] Transitions applied — PLANNED→ONGOING: 3, ONGOING→COMPLETED: 1
[TRIP_STATUS_JOB] Next run in 43200s
```

## Notification Job

**Fichier** : `api/src/jobs/notification_job.py`

### Fonctionnement

Le scheduler execute 5 types de verifications toutes les **30 minutes** :

```python
async def notification_scheduler():
    while True:
        run_notification_checks()  # sync, via asyncio.to_thread
        await asyncio.sleep(30 * 60)  # 30 minutes
```

### Types de notifications

#### 1. Departure Reminder (`DEPARTURE_REMINDER`)

**Condition** : Trip en statut `PLANNED`, `start_date = demain`
**Titre** : "Depart demain !"
**Body** : "Votre voyage << {title} >> commence demain. Bagages : {packed}/{total} prepares."
**Data** : `{screen: "tripHome", tripId: "..."}`
**Deduplication** : 20 heures

Fonctionnement specifique :
- Compte les bagages prepares (`is_packed = True`) vs total
- Si aucun bagage enregistre : "Pensez a preparer vos bagages !"
- Envoie a tous les recipients du trip (owner + viewers via TripShare)

#### 2. Flight H-4 (`FLIGHT_H4`)

**Condition** : FlightOrder `CONFIRMED`, depart dans 3.5h-4.5h
**Titre** : "Vol dans ~4h"
**Body** : "Votre vol pour << {title} >> decolle bientot !"
**Data** : `{screen: "tripHome", tripId: "...", orderId: "...", ticketUrl: "..."}`
**Deduplication** : 5 heures (par orderId)

Enrichissement : si un `ticket_url` existe sur le FlightOrder, il est inclus dans le body et les data.

#### 3. Flight H-1 (`FLIGHT_H1`)

**Condition** : FlightOrder `CONFIRMED`, depart dans 0.5h-1.5h
**Titre** : "Vol dans ~1h"
**Body** : "Votre vol pour << {title} >> decolle bientot ! (Terminal 2E)"
**Data** : `{screen: "tripHome", tripId: "...", orderId: "..."}`
**Deduplication** : 5 heures (par orderId)

Enrichissement : extrait le terminal depuis `offer_json.itineraries[0].segments[0].departure.terminal`.

#### 4. Morning Summary (`MORNING_SUMMARY`)

**Condition** : Trip `ONGOING`, activites aujourd'hui, entre 07:00 et 07:30 UTC
**Titre** : "Programme du jour -- {title}"
**Body** : "{n} activite(s) prevue(s) : {activity1}, {activity2}, {activity3} (+{rest})"
**Data** : `{screen: "activities", tripId: "..."}`
**Deduplication** : 20 heures

Note : ne s'execute que dans la fenetre 07:00-07:30 UTC. Affiche jusqu'a 3 noms d'activites.

#### 5. Activity H-1 (`ACTIVITY_H1`)

**Condition** : Activite aujourd'hui, `start_time` dans 30min-1h30
**Titre** : "Activite dans ~1h"
**Body** : "<< {activity.title} >> commence bientot ! a {location}"
**Data** : `{screen: "activities", tripId: "...", activityId: "..."}`
**Deduplication** : 2 heures (par activityId)

### Extraction des donnees de vol

La fonction `_extract_departure_time()` parse le datetime de depart depuis :
```
FlightOffer.offer_json → itineraries[0] → segments[0] → departure.at
```

La fonction `_extract_flight_info()` extrait :
- `ticket_url` depuis `FlightOrder.ticket_url`
- `terminal_gate` depuis `offer_json → segments[0] → departure.terminal`

### Logging

Tag : `[NOTIFICATION_JOB]`

```
[NOTIFICATION_JOB] Sent 5 notifications: {departure_reminders: 2, flight_h4: 1, flight_h1: 0, morning_summary: 1, activity_h1: 1}
[NOTIFICATION_JOB] No notifications to send
```

## Notification Service

**Fichier** : `api/src/services/notification_service.py`

### Methodes principales

| Methode | Description |
|---------|-------------|
| `create_and_send()` | Cree une notification en DB + envoi FCM |
| `create_and_send_bulk()` | Cree des notifications pour N users + envoi FCM multicast |
| `get_for_user()` | Notifications paginee pour un user (items, total, total_pages, unread_count) |
| `get_unread_count()` | Nombre de non-lues (pour badge app) |
| `mark_as_read()` | Marquer une notification lue |
| `mark_all_as_read()` | Marquer toutes les notifications lues |
| `check_and_send_budget_alert()` | Alerte si seuil budget franchi |

### Deduplication (`_already_sent`)

Avant chaque envoi, la methode `_already_sent()` verifie si une notification du meme type a deja ete envoyee recemment :

- Filtre par `user_id`, `notif_type`, `created_at >= cutoff`
- Optionnellement filtre par `trip_id` et un champ JSON specifique (`data_key`/`data_value`)
- Chaque type de notification a sa propre fenetre de deduplication

### Recipients (`_get_trip_recipients`)

Collecte l'owner du trip + tous les viewers (via `TripShare`) :
```python
[trip.user_id] + [share.user_id for share in TripShares]
```

### Push FCM (`_send_fcm`)

- Utilise `firebase_admin.messaging`
- **1 destinataire** : `messaging.Message` + `messaging.send()`
- **N destinataires** : `messaging.MulticastMessage` + `messaging.send_each_for_multicast()`
- **Nettoyage automatique** : les tokens invalides (`UnregisteredError`) sont supprimes de la DB
- **Degradation gracieuse** : si Firebase n'est pas initialise, le push est ignore (notification quand meme creee en DB)

### Budget Alert (`check_and_send_budget_alert`)

Declenchee a chaque creation/maj/suppression de budget item :

1. Calcule le summary du budget via `BudgetItemService.get_budget_summary()`
2. Si `alert_level` est present (WARNING ou DANGER) :
   - Verifie la deduplication (1h par niveau)
   - Envoie une notification avec le pourcentage consomme

Notification type : `BUDGET_ALERT`

## Notifications declenchees par les routes

En plus du scheduler, certaines notifications sont envoyees directement depuis les routes :

| Declencheur | Type | Route |
|-------------|------|-------|
| Changement statut ONGOING→COMPLETED | `TRIP_ENDED` | `PATCH /v1/trips/{tripId}/status` |
| Creation/maj/suppression budget item | `BUDGET_ALERT` | Routes budget-items |
| Partage de trip | `TRIP_SHARED` | `POST /v1/trips/{tripId}/shares` (via TripShareService) |
| Admin notification manuelle | `ADMIN` | `POST /admin/notifications/send` |

## Enum des types de notifications

Defini dans `api/src/enums.py` :

```python
class NotificationType(StrEnum):
    DEPARTURE_REMINDER = "DEPARTURE_REMINDER"
    FLIGHT_H4 = "FLIGHT_H4"
    FLIGHT_H1 = "FLIGHT_H1"
    MORNING_SUMMARY = "MORNING_SUMMARY"
    ACTIVITY_H1 = "ACTIVITY_H1"
    TRIP_STARTED = "TRIP_STARTED"
    TRIP_ENDED = "TRIP_ENDED"
    BUDGET_ALERT = "BUDGET_ALERT"
    TRIP_SHARED = "TRIP_SHARED"
    ADMIN = "ADMIN"
```

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `TRIP_STARTED` jamais envoye | Le type `TRIP_STARTED` est defini dans l'enum mais n'est jamais utilise dans le notification_job ni dans les routes. Devrait etre envoye quand un trip passe en ONGOING (dans `trip_status_job.py`). Fichier : `api/src/jobs/trip_status_job.py` | P1 |
| Pas de scheduler distribue | Les jobs tournent en `asyncio.create_task()` dans le process Uvicorn. En multi-worker, chaque worker execute ses propres jobs (deduplication partielle via `_already_sent`). Un vrai scheduler (Celery, APScheduler) serait plus robuste. Fichiers : `api/src/main.py` lignes 66-73 | P1 |
| Morning summary timezone | Le morning summary est envoye entre 07:00-07:30 UTC pour tous les utilisateurs. Pas de gestion du fuseau horaire de l'utilisateur ou de la destination. Fichier : `api/src/jobs/notification_job.py` lignes 177-178 | P2 |
| Pas de retry FCM | Si l'envoi FCM echoue (erreur reseau), pas de retry. La notification est creee en DB mais `sent_at` reste `None`. Fichier : `api/src/services/notification_service.py` | P2 |
| Pas de cleanup des vieux tokens FCM | Les tokens FCM ne sont supprimes que sur `UnregisteredError`. Pas de job de nettoyage periodique des tokens potentiellement expires. Fichier : `api/src/services/notification_service.py` | P2 |
| Pas de metriques de delivery | Pas de tracking du taux de delivrance des notifications push (sent vs received). | P2 |
