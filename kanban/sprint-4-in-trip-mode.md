# Sprint 4 — Mode In-Trip & Notifications

> **Objectif** : L'app se transforme automatiquement quand un voyage est en cours. Timeline temps reel, actions contextuelles, meteo live, notifications, post-trip.
> **Dependances** : Sprint 3 (Home ActiveTripView + Trip Detail)
> **Branch** : `feat/SMP-340-in-trip-mode`
> **Ref design** : TripIt Pro real-time, Tripsy today view, Apple Maps transit mode

**Pourquoi ce sprint est ici (Sprint 4, pas Sprint 8)** : Le mode in-trip est le differenciateur du produit. C'est la raison pour laquelle un utilisateur garderait l'app installee. Il doit etre prototype et valide tot, pas relegue en fin de roadmap.

---

## 4.1 — Auto-detection du mode "En voyage"

### Logique

```
Quand l'app s'ouvre ou revient au premier plan :
1. Fetch les trips de l'utilisateur
2. Si un trip a status == ONGOING (ou start_date <= today <= end_date pour un PLANNED)
   → Activer le mode "En voyage"
   → La home affiche l'ActiveTripHomeView (Sprint 3)
3. Si le batch job n'a pas encore transitionne le trip :
   → Le mobile detecte localement et fire une update de statut
```

### Taches

- [ ] **IT1 — Detection locale de trip en cours**
  - Fichier : `bagtrip/lib/home/helpers/trip_mode_detector.dart`
  - Verifie si un trip PLANNED a `start_date <= today <= end_date`
  - Si oui et status toujours PLANNED → appel API `PATCH /trips/{id}/status` → ONGOING
  - Retourne le trip actif (ONGOING) ou null
  - **Test** : Trip qui devrait etre ongoing, trip futur, trip passe, pas de trip

- [ ] **IT2 — App lifecycle listener**
  - Fichier : `bagtrip/lib/core/app_lifecycle_observer.dart`
  - `WidgetsBindingObserver` : detecte `resumed` (retour au premier plan)
  - Fire `RefreshHome` dans HomeBloc
  - **Test** : Lifecycle events fires

- [ ] **IT3 — Transition animee vers le mode voyage**
  - Quand le state passe de `HomeTripManager` a `HomeActiveTrip` :
    - Hero card du trip s'expand en full-screen
    - Autres elements fade out
    - Timeline du jour slide up
  - Duration : 800ms spring curve
  - **Test** : Smoke test visuel

---

## 4.2 — Today View : Enrichissement temps reel

> Les fondations sont posees au Sprint 3. Ce sprint enrichit l'experience avec le temps reel.

### Taches

- [ ] **TV1 — "Now" indicator temps reel**
  - Fichier : `bagtrip/lib/trip_detail/widgets/now_indicator.dart`
  - Ligne horizontale rouge dans la timeline du jour indiquant l'heure actuelle
  - Mise a jour toutes les minutes via `Timer.periodic`
  - Prochaine activite en surbrillance avec badge "Dans X min"
  - Cancel le Timer dans `close()` / `dispose()`
  - **Test** : Position correcte, badge countdown, timer cancel

- [ ] **TV2 — Activite en cours**
  - Si une activite est "en cours" (`start_time <= now <= end_time`) :
    - Card expanded avec fond `primaryContainer`
    - Badge "En cours" pulse
    - Bouton "Naviguer" prominent
    - Timer temps restant
  - **Haptic** : vibration subtle quand l'activite courante change
  - **Test** : Detection activite en cours, timer, badge

- [ ] **TV3 — Navigation rapide vers l'activite**
  - Chaque activite avec `location` affiche un bouton "Naviguer"
  - Tap → choix app Maps (Apple Maps par defaut iOS, Google Maps Android)
  - Si les 2 disponibles → `AdaptiveActionSheet` pour choisir
  - **Test** : URL correcte par plateforme

- [ ] **TV4 — Meteo mise a jour live**
  - Si le trip a des coordonnees → fetch Open-Meteo (cache TTL 1h)
  - Afficher dans le hero : icone + temperature + description courte
  - Fallback : derniere meteo connue du plan AI
  - **Test** : Fetch, cache, fallback

- [ ] **TV5 — Preview du lendemain**
  - Sous la timeline d'aujourd'hui, section collapsible "Demain"
  - 2-3 premieres activites du lendemain
  - Si demain = dernier jour → "Dernier jour de voyage"
  - **Test** : Affichage, collapsible, dernier jour

---

## 4.3 — Quick Actions contextuelles

### Design

Les quick actions changent selon le moment de la journee et le contexte :

| Contexte | Actions |
| --- | --- |
| Matin, avant activite | "Programme du jour", "Meteo", "Check-out" |
| Pendant une activite | "Naviguer", "Depense", "Photo" |
| Entre 2 activites | "Prochaine activite", "Suggestion IA", "Plan" |
| Soir | "Depenses du jour", "Demain", "Budget" |

### Taches

- [ ] **QA1 — Quick actions contextuelles helper**
  - Fichier : `bagtrip/lib/home/helpers/contextual_actions_helper.dart`
  - Determine les actions basees sur : heure actuelle, prochaine activite, jour du voyage
  - Retourne `List<QuickAction(icon, label, route/callback)>`
  - **Test** : Differents contextes temporels

- [ ] **QA2 — Action "Ajouter une depense" rapide**
  - Bottom sheet minimal :
    1. Montant (clavier numerique, grand affichage)
    2. Categorie (chips : Repas, Transport, Activite, Shopping, Autre)
    3. Note optionnelle
  - Sauvegarde immediate (pas de bouton "Save" — juste "Done" dans l'AppBar)
  - **Haptic** : `AppHaptics.success()` a la sauvegarde
  - **Decoration** : `backgroundColor: transparent` + Container rounded + handle bar
  - **Test** : Saisie montant, categorie, save

---

## 4.4 — Notifications en voyage

### Strategie

| Type | Timing | Contenu | Priorite |
| --- | --- | --- | --- |
| `TRIP_STARTED` | start_date, 8h locale | "Bon voyage ! Votre trip a {dest} commence" | High |
| `DAILY_SUMMARY` | Chaque matin, 8h | "Aujourd'hui : X activites planifiees" | Medium |
| `ACTIVITY_REMINDER` | 30min avant chaque activite | "{activite} dans 30 min a {lieu}" | Medium |
| `CHECKOUT_REMINDER` | Dernier jour, 9h | "N'oubliez pas le checkout a {heure}" | Medium |
| `TRIP_ENDED` | end_date + 1, 10h | "Voyage termine ! Comment c'etait ?" | Low |
| `PACKING_REMINDER` | 2 jours avant, 18h | "Depart dans 2 jours — {X} items non coches" | Medium |

### Taches

- [ ] **N1 — Planifier les notifications locales trip ONGOING**
  - Fichier : `bagtrip/lib/service/trip_notification_scheduler.dart`
  - Quand trip → ONGOING, planifier :
    - Daily summary chaque matin
    - Reminders 30min avant chaque activite avec `start_time`
    - Checkout reminder si hebergement avec check-out time
  - Annuler toutes quand trip → COMPLETED
  - **Test** : Bonnes notifications planifiees, annulation

- [ ] **N2 — Packing reminder 2 jours avant**
  - Quand trip est PLANNED, planifier 2 jours avant start_date
  - Si items bagages non coches → inclure le count dans le message
  - **Test** : Planning correct, message dynamique

- [ ] **N3 — Daily summary deep link**
  - Tap notification daily summary → deep link vers home en mode ActiveTrip
  - Le bon trip est affiche avec le bon jour
  - **Test** : Deep link vers bon trip

---

## 4.5 — Post-Trip Transition

### Taches

- [ ] **PT1 — Detection de fin de voyage**
  - Quand `end_date < today` et trip ONGOING :
    - Dialog : "Votre voyage est termine ! Voulez-vous le marquer comme termine ?"
    - Si oui → `PATCH status COMPLETED`
    - Si non → rappeler dans 24h
  - **Test** : Detection, dialog, transition

- [ ] **PT2 — Ecran post-trip "Souvenirs"**
  - Quand status → COMPLETED :
    - Nombre de jours
    - Activites realisees (checkees)
    - Budget total depense
    - Destinations visitees
  - CTA "Donner un avis" → feedback form
  - CTA "Planifier le prochain voyage"
  - **Animation** : fade in stagger sur les stats
  - **Test** : Stats correctes, CTAs

- [ ] **PT3 — Feedback post-voyage**
  - Formulaire feedback existant accessible depuis post-trip
  - Ajouter rating (1-5 etoiles) pour l'experience AI si trip genere par IA
  - **Test** : Form, rating, submission

---

## 4.6 — Changements API (integres)

- [ ] **API-1 — Auto-transition PLANNED → ONGOING notifiee**
  - Batch job detecte `start_date = today` → transition + push `TRIP_STARTED`
  - **Test** : `test_trip_started_notification.py`

- [ ] **API-2 — Notification `TRIP_CREATED` sur partage**
  - Quand un trip est partage, notification au destinataire
  - **Test** : `test_share_notification.py`

---

## Tests Sprint 4

### Tests unitaires

| Test | Module | Scenarios |
| --- | --- | --- |
| `trip_mode_detector_test.dart` | TripModeDetector | Ongoing, planned→ongoing, futur, passe |
| `contextual_actions_test.dart` | ContextualActions | Matin, aprem, soir, entre activites |
| `notification_scheduler_test.dart` | NotificationScheduler | Planning, annulation, packing |
| `app_lifecycle_test.dart` | AppLifecycleObserver | Resume → refresh |

### Tests widgets

| Test | Widget | Scenarios |
| --- | --- | --- |
| `now_indicator_test.dart` | NowIndicator | Position correcte, updates, timer cancel |
| `current_activity_test.dart` | ActiveTripHomeView | Activite detectee, timer, badge |
| `quick_expense_test.dart` | Expense sheet | Montant, categorie, save |
| `post_trip_screen_test.dart` | PostTripView | Stats, CTAs, feedback |
| `tomorrow_preview_test.dart` | ActiveTripHomeView | Preview, dernier jour |

### Tests integration

| Test | Scenario |
| --- | --- |
| `in_trip_detection_test.dart` | App launch, trip starts today → mode active, timeline shown |
| `post_trip_transition_test.dart` | Trip ended yesterday → dialog, stats |

---

## Criteres d'acceptation Sprint 4

- [ ] Trip mode s'active automatiquement quand `start_date <= today`
- [ ] "Now" indicator temps reel dans la timeline (mise a jour chaque minute)
- [ ] Activite en cours mise en surbrillance avec countdown
- [ ] Bouton "Naviguer" ouvre la bonne app de cartes
- [ ] Meteo du jour affichee et mise a jour (cache 1h)
- [ ] Quick actions contextuelles (changent selon l'heure/contexte)
- [ ] Ajout de depense rapide < 3 taps
- [ ] Notifications planifiees correctement (daily summary, reminders, packing)
- [ ] Post-trip affiche stats et propose feedback
- [ ] App re-detecte le mode quand elle revient au premier plan
- [ ] Timer cancel proprement dans `dispose()`/`close()`
- [ ] Dark mode fonctionne
- [ ] `flutter analyze` = 0 issues
- [ ] Tous les tests passent
- [ ] i18n EN + FR
