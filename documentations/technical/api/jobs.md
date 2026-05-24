# Background Jobs & Schedulers

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'API BagTrip embarque cinq background jobs dans `api/src/jobs/`. Tous suivent
le meme pattern : une coroutine `*_scheduler()` lancee via
`asyncio.create_task()` dans le lifespan FastAPI (`src/main.py`), une boucle
infinie qui execute une fonction sync (`run_*`, `cancel_*`, `downgrade_*`,
`refresh_*`) via `asyncio.to_thread()`, et un verrou Redis distribue qui
garantit l'execution single-worker dans une deploiement multi-worker
(`uvicorn --workers N`).

Trois decisions structurantes :

- **`asyncio.to_thread()` partout** : les jobs ouvrent une `SessionLocal()`
  synchrone et tapent SQLAlchemy en bloquant. Les sortir du thread principal
  evite de bloquer la boucle event qui sert les requetes HTTP.
- **Verrou Redis CAS-released** : sans Redis, le fallback est best-effort
  (`yield True` + warn). En mono-worker (dev), aucune duplication. En
  multi-worker SANS Redis, attention aux doublons.
- **Shutdown propre** : chaque `asyncio.Task` est `cancel()` au teardown du
  lifespan, et la `CancelledError` est consommee via `contextlib.suppress` apres
  un `await` qui laisse au scheduler le temps de logguer sa sortie.

Tous les jobs respectent les regles du `CLAUDE.md` backend : lock distribue
obligatoire pour les jobs multi-workers, dispatch logue mais ne propage pas les
exceptions (sinon la boucle meurt apres une seule erreur), et eager loading
sur les requetes qui traversent des relations.

## Liste des jobs

| Job | Frequence | Lock | Description |
|-----|-----------|------|-------------|
| `trip_status_job` | Quotidien (minuit UTC) | `lock:job:trip_status` (10 min) | Transitions PLANNED -> ONGOING -> COMPLETED + GC des trips DRAFT abandonnees |
| `notification_job` | Toutes les 30 min | `lock:job:notification` (60 min) | Push FCM : DEPARTURE_REMINDER, FLIGHT_H4/H1, MORNING_SUMMARY, ACTIVITY_H1 |
| `plan_expiration_job` | Toutes les heures | `lock:job:plan_expiration` (5 min) | Downgrade PREMIUM -> FREE si `plan_expires_at < now` et pas de Stripe sub |
| `zombie_payment_intents_job` | Quotidien | `lock:job:zombie_payment_intents` (10 min) | Cancel des BookingIntents AUTHORIZED bloques > 6 jours (avant que Stripe ne le fasse a J+7) |
| `currency_refresh_job` | Toutes les 12h | `lock:currency_refresh_job` (5 min) | Refresh des taux ECB pour le service de conversion |

## trip_status_job

**Fichier** : `api/src/jobs/trip_status_job.py`
**Tag log** : `[TRIP_STATUS_JOB]`

Le scheduler tick une fois au boot puis toutes les nuits a minuit UTC. La
fonction `_seconds_until_midnight_utc()` recalcule le delai a chaque iteration
pour ne pas deriver avec le temps.

Deux operations dans un meme tick, chacune dans son propre `try/except` pour
qu'un echec sur la seconde n'efface pas le travail de la premiere :

1. **`TripsService.auto_transition_statuses(db)`** : retourne `(p2o, o2c)`,
   compte des trips passees de PLANNED vers ONGOING et de ONGOING vers
   COMPLETED. Bulk `UPDATE` SQL, pas de loop Python.
2. **`TripsService.gc_stale_drafts(db, max_age_hours=24)`** (SMP-324) : purge
   des trips restees en statut DRAFT plus de 24h. Couvre le cas ou un user
   ferme le wizard SSE de planification sans confirmer.

Le TTL du lock (10 min) est largement superieur a la duree reelle d'un tick
mais bien inferieur a l'intervalle (24h), donc un worker qui crashe pendant
l'execution liberera son lock au plus tard le lendemain.

## notification_job

**Fichier** : `api/src/jobs/notification_job.py`
**Tag log** : `[NOTIFICATION_JOB]`

Le scheduler tick toutes les 30 min. Le TTL du lock (60 min, soit 2x
l'intervalle) absorbe les ticks lents sans risquer de bloquer le suivant.

`run_notification_checks()` ouvre une session DB unique et execute cinq verifs
en serie, retourne un dict de comptes :

| Verif | Trigger | Dedup | Destinataires |
|-------|---------|-------|---------------|
| `_check_departure_reminders` | Trip PLANNED, `start_date = demain` | 20h par trip | Owner + viewers (`TripShare`) |
| `_check_flight_alerts(4h)` | FlightOrder CONFIRMED, depart dans 3.5h-4.5h | 5h par `orderId` | Owner + viewers |
| `_check_flight_alerts(1h)` | FlightOrder CONFIRMED, depart dans 0.5h-1.5h | 5h par `orderId` | Owner + viewers |
| `_check_morning_summary` | Trip ONGOING, activites aujourd'hui, 07h-10h LOCAL destination | 20h par trip | Owner + viewers |
| `_check_activity_reminders` | Activite aujourd'hui, `start_time` dans 30-90 min | 2h par `activityId` | Owner + viewers |

Notes d'implementation importantes :

- **Locale par destinataire** : aucune string n'est construite cote scheduler.
  La copie est resolue via `NotificationService.send_localized(...)` qui rend
  des templates Jinja2 par locale. Le scheduler injecte uniquement le
  `context` (titre du trip, suffixes calcules par `notification_messages.py`).
  La locale par user est recuperee via
  `DeviceTokenService.get_locale_for_user(db, uid)` qui prend le token le plus
  recent.
- **Eager loading systematique** : tout endpoint qui itere sur
  `trip.baggage_items` ou `trip.shares` charge la relation en `selectinload`,
  et `FlightOrder.flight_offer` en `joinedload`. Sans ca, le scheduler
  produit un orage N+1 sur chaque trip actif toutes les 30 min.
- **Morning summary timezone-aware** : depuis la migration `destination_timezone`
  sur `Trip`, le check 07h-10h se fait dans le fuseau de la destination via
  `_safe_zone(trip.destination_timezone)` (fallback UTC sur IANA invalide).
  La fenetre 3h + le dedup 20h absorbent la derive de 30 min du scheduler.
- **`_already_sent()`** : second garde-fou au niveau DB pour le cas
  multi-worker sans Redis OU pour les ticks rapproches sur le meme worker.

## plan_expiration_job

**Fichier** : `api/src/jobs/plan_expiration_job.py`
**Tag log** : `[PLAN_EXPIRATION_JOB]`

Filet de securite pour la subscription Stripe. Tick horaire. Selectionne les
users qui matchent toutes ces conditions et les passe en FREE :

- `plan == "PREMIUM"`
- `plan_expires_at IS NOT NULL`
- `plan_expires_at < now()`
- `stripe_subscription_id IS NULL` (un sub actif renouvellera
  `plan_expires_at` via webhook au prochain billing cycle, on ne le touche pas)

Sans ce job, un user dont la subscription est annulee hors-Stripe (dispute,
suppression manuelle, dunning failure non remonte par webhook) garde son
acces Premium indefiniment.

Le job est conditionnel : `settings.ENABLE_PLAN_EXPIRATION_JOB`. Quand
desactive, le scheduler logue et retourne sans demarrer la boucle.

## zombie_payment_intents_job

**Fichier** : `api/src/jobs/zombie_payment_intents_job.py`
**Tag log** : `[ZOMBIE_PI_JOB]`

Stripe annule automatiquement les `PaymentIntent` non captures apres 7 jours.
On les annule a 6 jours pour controler le message renvoye a l'utilisateur et
mettre a jour notre DB AVANT que Stripe ne force la main.

Selectionne les `BookingIntent` ou :

- `status == AUTHORIZED`
- `created_at < now() - 6 jours`
- `stripe_payment_intent_id IS NOT NULL`

Pour chaque ligne :

1. `StripeClient.cancel_payment_intent(pi_id, idempotency_key="zombie-cleanup-{intent_id}-v1")`
   — la cle d'idempotence garantit qu'un retry n'envoie pas deux cancels.
2. Update local `status = CANCELLED`, `last_error = {"reason":
   "zombie_cleanup", "cancelled_after_days": 6}`.

Si Stripe renvoie une erreur (PI deja annule, deja capture par un autre code
path), on log en `warn` et on update quand meme la ligne locale pour que la
DB n'ait pas de zombie indefiniment. Le webhook `payment_intent.canceled`
reste branche en parallele et fait son boulot si Stripe annule en premier.

Conditionnel : `settings.ENABLE_ZOMBIE_PI_JOB`.

## currency_refresh_job

**Fichier** : `api/src/jobs/currency_refresh_job.py`
**Tag log** : `[CURRENCY_REFRESH_JOB]`

Refresh des taux ECB pour le service de conversion devise (topic 04b, phase
3). Intervalle 12h, aligne sur le TTL du cache in-process pour que le cache
ne tombe jamais en cold-fallback en conditions nominales.

La premiere iteration ne `sleep` pas : `_refresh_with_lock()` est appele
immediatement au boot pour warm le cache avant la premiere requete HTTP
entrante. Ensuite la boucle alterne `await asyncio.sleep(12h)` et un nouveau
refresh.

`refresh_rates_async()` (dans `currency_service.py`) avale ses propres
exceptions et retourne `0` en cas d'echec — le scheduler ne reagit donc qu'aux
problemes de scheduling (cancellation, lock detenu par un pair) et logue
`unexpected error, continuing` plutot que de propager.

## Distributed lock Redis

**Fichier** : `api/src/utils/distributed_lock.py`

`redis_lock(name, ttl_seconds)` est un async context manager qui yield un
`bool` (lock acquis ou pas). Tous les schedulers wrappent le corps de leur
tick dedans :

```python
async with redis_lock("job:notification", ttl_seconds=3600) as acquired:
    if not acquired:
        logger.info(f"{TAG} Lock held by peer worker, skipping tick")
    else:
        # run the tick
```

### Acquisition : SET NX EX

```
SET lock:{name} {uuid_token} NX EX {ttl_seconds}
```

Atomique. `NX` garantit qu'on ne pose pas le lock si une autre cle existe
deja, `EX` pose le TTL dans la meme commande pour qu'on ne puisse pas
crasher entre `SET` et `EXPIRE` en laissant un lock immortel.

Le token est un `uuid4().hex` genere par worker, stocke en valeur de la cle.

### Liberation : Lua CAS

```lua
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
```

Eval atomique. On ne `DEL` que si la valeur correspond a notre token —
indispensable pour eviter le scenario "worker A est trop lent, son TTL
expire, worker B prend le lock, worker A termine et `DEL` le lock de B".

Si l'eval echoue (Redis qui flap a la liberation), on log en `warn` et on
laisse le TTL expirer naturellement. Aucune cle ne reste "stuck forever".

### Fallback sans Redis

Si `get_redis_client()` retourne `None` (`REDIS_URL` non set, paquet `redis`
absent, ping qui echoue), le context manager yield `True` et logue UN warn
par nom de lock (`_warned_fallback` set pour eviter le spam). Mono-worker en
dev : aucun risque. Multi-worker en prod sans Redis : doublons garantis,
d'ou le warn proeminent.

### Choix des TTL

Regle du `CLAUDE.md` : `max(runtime * 2, 2 * intervalle)`. Tous les TTLs
choisis dans les jobs respectent cette regle (10 min sur trip_status pour un
bulk UPDATE de quelques secondes, 60 min sur notification pour un tick qui
prend ~10s, etc).

## Lifecycle asyncio

**Fichier** : `api/src/main.py`, lifespan FastAPI.

Au boot, apres l'init HTTP client + check DB + seeds Stripe / admin :

```python
scheduler_task        = asyncio.create_task(trip_status_scheduler())
notif_scheduler_task  = asyncio.create_task(notification_scheduler())
plan_expiration_task  = asyncio.create_task(plan_expiration_scheduler())
zombie_pi_task        = asyncio.create_task(zombie_payment_intents_scheduler())
currency_task         = asyncio.create_task(currency_refresh_scheduler())
```

Cinq `asyncio.Task` fire-and-forget. Le lifespan `yield` ensuite et l'app
sert les requetes pendant que les schedulers tournent en parallele.

Au teardown :

```python
scheduler_task.cancel()
notif_scheduler_task.cancel()
plan_expiration_task.cancel()
zombie_pi_task.cancel()
currency_task.cancel()
with contextlib.suppress(asyncio.CancelledError):
    await scheduler_task
# ... idem pour les autres
```

Le pattern `cancel()` + `await` + `suppress(CancelledError)` est important :

- `cancel()` envoie une `CancelledError` au point ou la coroutine est en
  attente (typiquement le `await asyncio.sleep(...)`).
- L'`await` permet a la coroutine de remonter dans son `except
  asyncio.CancelledError`, logguer `Scheduler stopped`, et re-raise.
- `contextlib.suppress(CancelledError)` autour de l'`await` evite que la
  cancellation ne fasse remonter une erreur dans le lifespan.

Sans le `await`, le scheduler serait tue brutalement sans avoir le temps
de logguer ni de fermer ses sessions DB ouvertes.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| `TRIP_STARTED` notification non envoyee | Le type est defini dans `NotificationType` mais `trip_status_job` n'envoie aucun push quand un trip passe PLANNED -> ONGOING. Devrait etre branche apres `auto_transition_statuses` quand `p2o > 0`. | P1 |
| Pas de retry FCM | Si l'envoi FCM echoue (timeout, erreur reseau), la notification est creee en DB mais `sent_at` reste `None`. Pas de retry queue. | P2 |
| Pas de cleanup periodique des tokens FCM | Suppression uniquement sur `UnregisteredError` au moment de l'envoi. Les tokens d'apps desinstallees depuis longtemps mais qui n'ont jamais re-tente d'envoi restent en DB. | P3 |
| Pas de metriques de delivery | Aucun tracking sent vs received cote FCM. On ne sait pas si un push est effectivement arrive. | P2 |
| Pas de scheduler externe | Tous les jobs vivent dans le process FastAPI. Pour un crash de tout le process, plus aucun job ne tourne tant que l'app n'est pas relancee. Une migration vers APScheduler ou Celery beat (process dedie) ameliorerait la resilience. | P2 |
| Pas de circuit-breaker sur les jobs Stripe | `zombie_payment_intents_job` continue de taper Stripe meme si l'API est down. Un circuit-breaker (ou un backoff exponentiel) eviterait de flood Stripe en cas d'incident. | P3 |
