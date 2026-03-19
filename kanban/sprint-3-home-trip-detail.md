# Sprint 3 — Home Contextuelle & Trip Detail Immersif

> **Objectif** : Refondre la home pour qu'elle s'adapte au contexte utilisateur (nouveau, en voyage, planificateur), et creer le trip detail comme hub central post-creation.
> **Dependances** : Sprint 1 (HomeBloc parallelise, design tokens), Sprint 2 (creation de trip — le trip detail affiche le resultat)
> **Branch** : `feat/SMP-330-home-trip-detail`
> **Ref design** : Airbnb home, Apple Wallet card stack, Tripsy dashboard, TripIt trip view

**Ce sprint inclut** : hero transitions, skeleton loading, pull-to-refresh, staggered list animations. Pas differe.

---

## 3.1 — HomeBloc : 3 etats contextuels

### Architecture

Le HomeBloc (deja parallelise au Sprint 1) emet desormais 3 states distincts bases sur les donnees :

```dart
sealed class HomeState {}
class HomeLoading extends HomeState {}
class HomeNewUser extends HomeState { final User user; }
class HomeActiveTrip extends HomeState {
  final User user;
  final Trip activeTrip;
  final List<Activity> todayActivities;
  final String? weatherSummary;
}
class HomeTripManager extends HomeState {
  final User user;
  final Trip? nextTrip;
  final int nextTripCompletion; // 0-100%
  final List<Trip> upcomingTrips;
  final List<Trip> completedTrips;
}
class HomeError extends HomeState { final String message; }
```

**Logique** : Fetch user + trips. Si 0 trips → `HomeNewUser`. Si un trip ONGOING (ou `start_date <= today <= end_date`) → `HomeActiveTrip`. Sinon → `HomeTripManager`.

### Taches

- [ ] **H1 — Refactorer HomeBloc avec les 3 states**
  - Fichier : `bagtrip/lib/home/bloc/home_bloc.dart`
  - States Freezed : `HomeNewUser`, `HomeActiveTrip`, `HomeTripManager`, `HomeError`
  - Pre-fetch des activites du jour pour `HomeActiveTrip` via `Future.wait`
  - **Test** : 6 scenarios (new user, active trip, planned only, completed only, error, refresh)

- [ ] **H2 — Event `RefreshHome`**
  - Re-fetch sans flash `HomeLoading` (garde le state actuel pendant le refresh)
  - **Test** : `RefreshHome` emet le nouveau state directement

- [ ] **H3 — Trip completion calculator**
  - Fichier : `bagtrip/lib/home/helpers/trip_completion.dart`
  - Calcul : dates 20% + flights 20% + accommodation 20% + 3+ activities 20% + 5+ baggage items 20%
  - Retourne `{percentage, completedSections}`
  - **Test** : 0%, 20%, 60%, 100%, null dates

---

## 3.2 — Vue Onboarding (HomeNewUser)

### Design

Ecran immersif pour les nouveaux utilisateurs. Lottie animation (avion survolant le globe), titre "Ou partez-vous ?", sous-titre, CTA gradient "Planifier mon voyage", cards inspiration.

### Taches

- [ ] **O1 — Creer `OnboardingHomeView`**
  - Fichier : `bagtrip/lib/home/view/onboarding_home_view.dart`
  - Full-screen : Lottie + headline + subtext + CTA gradient + inspiration cards
  - CTA navigue vers `PlanTripRoute`
  - Cards inspiration pre-remplissent la destination au tap
  - **Animation** : fade in stagger sur les elements (titre → sous-titre → CTA → cards)
  - **Test** : CTA visible, navigation, cards affichees

- [ ] **O2 — Inspiration cards**
  - 6 destinations populaires hardcodees avec assets locaux (pas de reseau)
  - Model : `{name, imageAsset, country, flag}`
  - **Test** : Chargement assets sans crash

---

## 3.3 — Vue Trip Manager (HomeTripManager)

### Design

Header salutation + prochain voyage en hero card + CTA "Planifier" + segment control Planifies/Passes + liste trips + pull-to-refresh.

### Taches

- [ ] **TM1 — Creer `TripManagerHomeView`**
  - Fichier : `bagtrip/lib/home/view/trip_manager_home_view.dart`
  - Greeting header + next trip hero card avec completion bar + CTA "Planifier" + segment control + trip list
  - Pull-to-refresh : iOS `CupertinoSliverRefreshControl`, Android `RefreshIndicator`
  - **Skeleton** : 1 hero skeleton + 3 trip card skeletons pendant le chargement
  - **Test** : Hero correct, segment switch, refresh fire event

- [ ] **TM2 — Refactorer `TripCard` (2 variantes)**
  - `TripCard.large` : full-width, 200px hauteur, image hero, completion bar
  - `TripCard.compact` : row, image a gauche, infos a droite
  - `Hero` tag : `'trip-${trip.id}'` pour la transition vers le detail
  - **Test** : Golden test light/dark pour les 2 variantes

- [ ] **TM3 — Carousel trips passes**
  - `PageView.builder` horizontal, images desaturees
  - Tap → navigation read-only vers le trip detail
  - **Test** : Scroll horizontal, navigation

---

## 3.4 — Vue Active Trip (HomeActiveTrip)

### Design

Dashboard du trip en cours. Photo destination full-bleed, "Jour X sur Y", meteo inline, timeline des activites du jour, quick actions, preview du lendemain.

> Note : cette vue pose les fondations. Le Sprint 4 l'enrichira avec le "now" indicator, les actions contextuelles temps reel, et les notifications.

### Taches

- [ ] **AT1 — Creer `ActiveTripHomeView`**
  - Fichier : `bagtrip/lib/home/view/active_trip_home_view.dart`
  - Hero card trip actif + timeline du jour + quick actions basiques
  - **Test** : Donnees correctes, timeline ordonnee par heure

- [ ] **AT2 — Service "Today's Activities"**
  - Fichier : `bagtrip/lib/home/helpers/today_activities.dart`
  - Filtrer les activites par jour courant, trier par `start_time`
  - Calculer la prochaine activite
  - Gerer les activites sans horaire (allDay)
  - **Test** : Past/current/future/timeless activities

- [ ] **AT3 — Meteo inline**
  - Si le trip a des coordonnees → fetch Open-Meteo
  - Sinon → fallback meteo du plan AI
  - Cache TTL 1h
  - **Test** : Avec/sans meteo cachee

- [ ] **AT4 — Navigation vers trip detail**
  - Tap hero → `TripDetailRoute(tripId)` avec hero shared element
  - **Test** : Navigation fonctionne

---

## 3.5 — Home View Orchestrator

- [ ] **HO1 — Refactorer `HomeView`**
  - Fichier : `bagtrip/lib/home/view/home_view.dart`
  - `BlocBuilder<HomeBloc>` dispatche vers les 3 vues + loading + error
  - **Animation** : `AnimatedSwitcher` fade + slide up (500ms spring) entre les vues
  - **Test** : Chaque state rend le bon widget

---

## 3.6 — Trip Detail Page : Architecture

### Philosophie

Hub central post-creation. Doit etre : (1) Scannable (comprendre le trip en 2s), (2) Actionable (action claire par section), (3) Progressive (s'enrichit au fur et a mesure).

### Structure

```
Hero (cover + titre + dates + countdown)
  → Completion Bar (6 segments, tappable)
    → Quick Actions Row (horizontal scroll, contextuel)
      → Timeline (day-by-day, morning/afternoon/evening)
        → Flights (boarding pass cards)
          → Accommodation (cards avec details)
            → Baggage (checklist avec progression)
              → Budget (dashboard)
                → Sharing (participants + invite)
```

### Nouveau BLoC : `TripDetailBloc`

```dart
// Events
LoadTripDetail(String tripId)
RefreshTripDetail()
SelectDay(int dayIndex)
ToggleSection(String sectionId)
ValidateActivity(String activityId)
RejectActivity(String activityId)

// State (Freezed)
TripDetailLoaded(
  Trip trip,
  List<Activity> activities,
  List<ManualFlight> flights,
  List<Accommodation> accommodations,
  List<BaggageItem> baggageItems,
  BudgetSummary? budgetSummary,
  List<TripShare> shares,
  int selectedDayIndex,
  String userRole,          // OWNER / VIEWER
  int completionPercentage,
)
```

### Taches

- [ ] **TD1 — Creer `TripDetailBloc`**
  - Fichier : `bagtrip/lib/trip_detail/bloc/trip_detail_bloc.dart`
  - Fetch toutes les sections en parallele (`Future.wait`)
  - `close()` override
  - **Test** : Load, refresh, select day, validate/reject activity

- [ ] **TD2 — Creer `TripDetailPage` + `TripDetailView`**
  - Fichier : `bagtrip/lib/trip_detail/view/trip_detail_page.dart`
  - `BlocProvider<TripDetailBloc>` + `CustomScrollView` avec `SliverAppBar`
  - **Skeleton** : hero skeleton + 4 section skeletons pendant le chargement
  - Pull-to-refresh
  - **Test** : SliverAppBar collapse, sections rendues

---

## 3.7 — Trip Detail : Hero Section

- [ ] **TD3 — Creer `TripHeroHeader`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_hero_header.dart`
  - Image full-bleed avec parallax (0.5x) + gradient overlay + titre + date range + countdown
  - 3 etats : upcoming ("Dans X jours"), ongoing ("Jour X/Y"), completed ("Termine")
  - Hero tag pour shared element transition depuis Home
  - **Test** : 3 etats, countdown correct

---

## 3.8 — Trip Detail : Completion Bar

- [ ] **CB1 — Creer `TripCompletionBar`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_completion_bar.dart`
  - Barre segmentee (6 segments : dates, flights, accommodation, activities, baggage, budget)
  - Labels tappables → scroll vers la section correspondante
  - Anime au chargement
  - Cache pour les VIEWERs
  - **Test** : Correct %, tappable, animation, role-gating

---

## 3.9 — Trip Detail : Quick Actions Row

- [ ] **QA1 — Creer `QuickActionsRow`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/quick_actions_row.dart`
  - Boutons 80x80px en horizontal scroll
  - Actions contextuelles selon le status (PLANNED : "Add flight", "Add hotel" / ONGOING : "Navigate", "Expense" / COMPLETED : "Memories")
  - Role-gated (VIEWER : actions lecture seule)
  - **Test** : Actions correctes par status, navigation

---

## 3.10 — Trip Detail : Section Timeline

- [ ] **TL1 — Creer `TripTimelineSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_timeline_section.dart`
  - Day chips (J1, J2, ...) horizontaux + contenu par jour
  - Time blocks : Matin / Apres-midi / Soiree
  - "Ajouter une activite" par jour
  - Message si jour vide : "Pas encore d'activites — ajoutez-en ou demandez a l'IA"
  - **Animation** : stagger fade in sur les activity cards
  - **Test** : Jours corrects, time block grouping, jour vide

- [ ] **TL2 — Creer `TimelineActivityCard`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/timeline_activity_card.dart`
  - Badge categorie, titre, heure, lieu, status (SUGGESTED/VALIDATED/MANUAL)
  - Boutons Valider/Rejeter pour SUGGESTED (OWNER only)
  - Swipe delete
  - **Haptic** : `AppHaptics.medium()` sur Valider, `AppHaptics.light()` sur Rejeter
  - **Test** : 3 status, swipe delete, callbacks, role-gating

- [ ] **TL3 — Day activity grouping helper**
  - Fichier : `bagtrip/lib/trip_detail/helpers/day_grouping.dart`
  - `Map<int, {morning, afternoon, evening, allDay}>`
  - Calcul du jour (1-based) depuis la date de l'activite
  - **Test** : Grouping correct, timeless en allDay

- [ ] **TL4 — Events Validate/Reject activity**
  - `ValidateActivity(id)` → `PATCH /v1/activities/{id}` status VALIDATED
  - `RejectActivity(id)` → `DELETE /v1/activities/{id}`
  - Mise a jour optimiste du state (pas de re-fetch)
  - **Test** : State mis a jour, API appele

---

## 3.11 — Trip Detail : Section Flights

- [ ] **FL1 — Creer `TripFlightsSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_flights_section.dart`
  - Liste de boarding pass cards
  - Empty state avec 2 CTAs : "Rechercher un vol" + "Saisir manuellement"
  - **Test** : Avec/sans vols, CTAs

- [ ] **FL2 — Creer `FlightBoardingPassCard`**
  - Style boarding pass (departure → arrival, date, airline, flight#)
  - 3 status : Confirmed / Manual / Pending
  - OWNER : edit/delete. VIEWER : details seulement.
  - **Test** : Golden test light/dark

---

## 3.12 — Trip Detail : Section Accommodation

- [ ] **AC1 — Creer `TripAccommodationSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_accommodation_section.dart`
  - Cards avec photo + nom + etoiles + check-in/out + prix + badge status
  - Empty state avec CTAs
  - **Test** : Avec/sans, CTAs

---

## 3.13 — Trip Detail : Section Baggage

- [ ] **BG1 — Creer `TripBaggageSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_baggage_section.dart`
  - Header progression (compteur + barre)
  - Categories collapsibles
  - Checkboxes animees (spring + haptic)
  - Badge IA sur les items suggeres
  - CTA "Ajouter un item"
  - **Haptic** : `AppHaptics.light()` sur check
  - **Test** : Correct %, check/uncheck, grouping

---

## 3.14 — Trip Detail : Section Budget

- [ ] **BU1 — Creer `TripBudgetSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_budget_section.dart`
  - Total estime vs depense
  - Breakdown par categorie (bars horizontales colorees)
  - CTA "Ajouter une depense"
  - **Test** : Calculs corrects, couleurs par categorie

---

## 3.15 — Trip Detail : Section Sharing

- [ ] **SH1 — Creer `TripSharingSection`**
  - Fichier : `bagtrip/lib/trip_detail/widgets/trip_sharing_section.dart`
  - Liste participants avec role
  - Owner non-supprimable
  - CTA "Inviter" (OWNER only)
  - **Test** : Owner fixe, viewer removable, CTA cache pour VIEWER

---

## 3.16 — Changements API (integres)

- [ ] **API-1 — Cover image automatique**
  - Unsplash API (free, 50 req/h). Query : `{destination}`. Stocker URL.
  - Fallback : mapping continent → URL par defaut
  - **Test** : `test_cover_image.py`

- [ ] **API-2 — Fallback meteo intelligent**
  - Latitude → zone climatique (55°+ → 18C ete, 35-55° → 25C, 23-35° → 30C, <23° → 28C)
  - **Test** : `test_weather_fallback.py` — Stockholm, Paris, Dubai, Bangkok

---

## Tests Sprint 3

### Tests unitaires

| Test | Module | Scenarios |
| --- | --- | --- |
| `home_bloc_states_test.dart` | HomeBloc | NewUser, ActiveTrip, TripManager, Error, Refresh |
| `today_activities_test.dart` | Today helper | Filter by date, sort by hour, next activity |
| `trip_completion_test.dart` | Completion helper | 0%, 20%, 60%, 100%, null dates |
| `trip_detail_bloc_test.dart` | TripDetailBloc | Load, refresh, select day, validate, reject |
| `day_grouping_test.dart` | Day grouping helper | Grouping correct, timeless, edge cases |

### Tests widgets

| Test | Widget | Scenarios |
| --- | --- | --- |
| `onboarding_home_view_test.dart` | OnboardingHomeView | CTA visible, navigation, cards |
| `trip_manager_home_view_test.dart` | TripManagerHomeView | Hero card, segment, pull refresh |
| `active_trip_home_view_test.dart` | ActiveTripHomeView | Hero, timeline, quick actions |
| `home_view_test.dart` | HomeView orchestrator | Chaque state → bon widget |
| `trip_card_test.dart` | TripCard | Large/compact, dark mode |
| `trip_detail_page_test.dart` | TripDetailPage | Sections rendues, SliverAppBar |
| `trip_hero_test.dart` | TripHeroHeader | 3 etats, countdown |
| `trip_completion_bar_test.dart` | TripCompletionBar | %, tappable, role |
| `trip_timeline_test.dart` | TripTimelineSection | Jours, time blocks |
| `timeline_activity_card_test.dart` | TimelineActivityCard | 3 status, swipe, callbacks |
| `flight_boarding_pass_test.dart` | FlightBoardingPassCard | Golden light/dark |
| `trip_baggage_section_test.dart` | TripBaggageSection | %, check/uncheck |
| `trip_budget_section_test.dart` | TripBudgetSection | Calculs, couleurs |

### Tests integration

| Test | Scenario |
| --- | --- |
| `home_new_user_flow_test.dart` | New user → CTA → wizard |
| `home_active_trip_test.dart` | User avec trip ongoing → ActiveTrip view |
| `home_to_detail_test.dart` | Tap trip card → hero transition → detail |

---

## Criteres d'acceptation Sprint 3

- [ ] Home s'adapte correctement aux 3 contextes (new user, active trip, manager)
- [ ] Pull-to-refresh fonctionne dans les 3 vues
- [ ] Hero card du prochain trip affiche la completion bar
- [ ] ActiveTripHomeView affiche les activites du jour triees par heure
- [ ] Transitions entre vues animees (pas de flash blanc)
- [ ] Hero transition home → trip detail (shared element)
- [ ] Skeleton loading pendant le chargement (pas de spinner)
- [ ] Trip detail affiche toutes les sections avec des donnees reelles
- [ ] SliverAppBar collapse/expand smooth avec parallax
- [ ] Completion bar reflette l'etat reel (0-100%)
- [ ] Timeline day-by-day avec morning/afternoon/evening
- [ ] Activites AI avec boutons Valider/Rejeter fonctionnels
- [ ] Flight cards en style boarding pass
- [ ] Baggage checklist avec animations et haptics
- [ ] Budget breakdown avec barres colorees
- [ ] VIEWER role → lecture seule (pas de boutons edit)
- [ ] Dark mode fonctionne sur toutes les vues
- [ ] Staggered fade in sur les listes
- [ ] `flutter analyze` = 0 issues
- [ ] Tous les tests passent
- [ ] i18n EN + FR
