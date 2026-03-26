# Navigation Mobile BagTrip (Flutter)

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La navigation BagTrip repose sur **GoRouter** avec generation de routes type-safe via `@TypedGoRoute`. L'app utilise un `StatefulShellRoute.indexedStack` pour les 3 onglets principaux (Home, Activity, Profile), chaque branche preservant son etat de navigation. Les transitions de page sont adaptatives (Cupertino slide sur iOS, Material slide+fade sur Android). La bottom bar est un `GlassBottomBar` sur iOS et un `NavigationBar` Material sur Android.

## Configuration du Router -- `lib/navigation/app_router.dart`

Le router global `appRouter` est un singleton `GoRouter` :

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async { /* auth guard */ },
  routes: [
    $splashRoute,
    $loginRoute,
    $onboardingRoute,
    $personalizationRoute,
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [$homeRoute]),    // Branch 0
        StatefulShellBranch(routes: [$activityRoute]), // Branch 1
        StatefulShellBranch(routes: [$profileRoute]),  // Branch 2
      ],
    ),
    $notificationsRoute,
    $deepLinkTripRoute,
    $flightSearchResultRoute,
    $flightResultDetailsRoute,
    $subscriptionSuccessRoute,
    $subscriptionCancelRoute,
    $paymentSuccessRoute,
    $paymentCancelRoute,
    $paymentResultRoute,
  ],
);
```

## Auth Guard (redirect)

Le `redirect` du router assure la protection des routes :

1. `/` (splash) est toujours accessible -- la splash gere la verification auth au demarrage.
2. Pour toute autre route, `authRepository.isAuthenticated()` est appele.
3. Si non authentifie et pas sur `/login` ni `/onboarding` : redirection vers `/login?redirect=<intended>`.
4. Si authentifie et sur `/login` : redirection vers la route `redirect` encodee dans les query params, ou navigation normale.

```dart
redirect: (context, state) async {
  final authRepository = getIt<AuthRepository>();
  final authResult = await authRepository.isAuthenticated();
  final isAuthenticated = authResult.dataOrNull ?? false;

  if (!isAuthenticated && !isLoginPage && !isOnboardingPage) {
    final intended = state.uri.toString();
    return '/login?redirect=${Uri.encodeComponent(intended)}';
  }
  if (isAuthenticated && isLoginPage) {
    final redirect = state.uri.queryParameters['redirect'];
    if (redirect != null) return Uri.decodeComponent(redirect);
  }
  return null;
},
```

## Routes Type-Safe -- `lib/navigation/route_definitions.dart`

### Definition

Chaque route est une classe qui etend `GoRouteData` et utilise un mixin genere :

```dart
@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [
    TypedGoRoute<PlanTripRoute>(path: 'plan'),
    TypedGoRoute<TripHomeRoute>(
      path: ':tripId',
      routes: [
        TypedGoRoute<ActivitiesRoute>(path: 'activities'),
        TypedGoRoute<BudgetRoute>(path: 'budget'),
        TypedGoRoute<BaggageRoute>(path: 'baggage'),
        // ...
      ],
    ),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute { ... }
```

### Navigation type-safe

```dart
// Navigation declarative
TripHomeRoute(tripId: '123').go(context);

// Navigation avec parametres complexes via $extra
PlanTripRoute($extra: locationResult).go(context);

// Navigation avec parametres d'URL
AccommodationsRoute(
  tripId: tripId,
  role: 'OWNER',
  isCompleted: false,
  tripStartDate: '2026-04-15',
).go(context);
```

### Regeneration

Apres toute modification des routes, regenerer le fichier `route_definitions.g.dart` :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Arbre des routes complet

```
/                          SplashRoute (NoTransition)
/login                     LoginRoute (NoTransition)
/onboarding                OnboardingRoute (NoTransition)
/personalization            PersonalizationRoute (NoTransition ou Slide)
/trip/:tripId              DeepLinkTripRoute (Slide)
/notifications             NotificationsRoute (Slide)
/flight-search-result      FlightSearchResultRoute (Slide)
/flight-result-details     FlightResultDetailsRoute (Slide)
/subscription/success      SubscriptionSuccessRoute (Slide)
/subscription/cancel       SubscriptionCancelRoute (Slide)
/payment/success           PaymentSuccessRoute (Slide)
/payment/cancel            PaymentCancelRoute (Slide)
/payment/result            PaymentResultRoute (Slide)

[StatefulShellRoute — AppShell]
  Branch 0: /home
    /home                  HomeRoute (NoTransition)
    /home/plan             PlanTripRoute (Wizard)
    /home/flight-search    TripFlightSearchRoute (Slide)
    /home/trip/:tripId     TripDetailRoute (Hero)
    /home/:tripId          TripHomeRoute (Slide)
      /home/:tripId/accommodations   AccommodationsRoute (Slide)
      /home/:tripId/baggage          BaggageRoute (Slide)
      /home/:tripId/activities       ActivitiesRoute (Slide)
      /home/:tripId/budget           BudgetRoute (Slide)
      /home/:tripId/transports       TransportsRoute (Slide)
      /home/:tripId/shares           SharesRoute (Slide)
      /home/:tripId/feedback         FeedbackRoute (Slide)
      /home/:tripId/post-trip        PostTripRoute (Slide)
      /home/:tripId/map              MapRoute (Slide)

  Branch 1: /activity
    /activity              ActivityRoute (NoTransition)

  Branch 2: /profile
    /profile               ProfileRoute (NoTransition)
    /profile/personal-info PersonalInfoRoute (Slide)
    /profile/settings      SettingsRoute (Slide)
```

## Transitions de page -- `lib/navigation/page_transitions.dart`

3 builders de transition, tous adaptatifs :

### buildSlideTransitionPage

Transition standard pour la navigation push :

- **iOS** : `CupertinoPageTransition` natif (slide-from-right avec swipe-back gesture, 400ms).
- **Android** : Slide 15% + fade avec `easeOutCubic` (350ms).

```dart
@override
Page<void> buildPage(BuildContext context, GoRouterState state) =>
    buildSlideTransitionPage<void>(
      state: state,
      child: ActivitiesPage(tripId: tripId),
    );
```

### buildHeroTransitionPage

Fade transition pour les navigations card -> detail avec `Hero` widgets :

- Duree : `AppAnimations.cardTransition` (350ms)
- Courbe : `AppAnimations.standardCurve` (easeOutCubic)
- Pas de slide -- seul le fade est gere, les Hero widgets animent les elements partages.

```dart
class TripDetailRoute extends GoRouteData {
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildHeroTransitionPage<void>(
        state: state,
        child: TripDetailPage(tripId: tripId),
      );
}
```

### buildWizardTransitionPage

Transition pour les flows multi-etapes (creation de voyage) :

- **iOS** : `CupertinoPageTransition` (identique au slide mais sans duration custom).
- **Android** : slide 15% + fade avec `easeOutCubic` / `easeInCubic` reverse.

## Shell et Bottom Bar

### AppShell -- `lib/navigation/app_shell.dart`

Le `AppShell` est un `StatefulWidget` qui :

1. Recoit le `StatefulNavigationShell` de GoRouter.
2. Detecte si on est sur une route top-level (`/home`, `/activity`, `/profile`).
3. Affiche/cache la bottom bar en fonction.

```dart
const _topLevelPaths = {'/home', '/activity', '/profile'};

// La tab bar n'est visible que sur les pages racines
if (_isTopLevel)
  Positioned(left: 0, right: 0, bottom: 0, child: tabBar),
```

**iOS** : `CupertinoPageScaffold` + `Stack` avec tab bar positionnee en overlay (`Positioned` en bas). Les sous-pages doivent prevoir un bottom padding (~100px) pour compenser.

**Android** : `Scaffold` avec `bottomNavigationBar` standard.

### BottomTabBar -- `lib/components/bottom_tab_bar.dart`

| Plateforme | Widget | Icones |
|------------|--------|--------|
| iOS | `GlassBottomBar` (liquid_glass_widgets) | `CupertinoIcons.house_fill`, `.bell_fill`, `.person_fill` |
| Android | `NavigationBar` (Material3) | `Icons.home_outlined`, `.notifications_outlined`, `.person_outlined` |

Badge de notifications sur l'onglet Activity :
- iOS : `GlassBadge` positionne en overlay.
- Android : `Badge` widget Material.

Labels localisees via l10n : `tabHome`, `tabActivity`, `tabProfile`.

### NavigationBloc -- `lib/navigation/bloc/`

BLoC simple qui track l'onglet actif :

```dart
enum NavigationTab { home, activity, profile }

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  on<NavigationTabChanged>(_onTabChanged);
}
```

Note : le changement d'onglet est gere par `navigationShell.goBranch(index)` dans `AppShell`, le `NavigationBloc` n'est pas directement utilise pour la navigation shell (il sert de source de verite pour d'autres composants).

## Deep Links

### Route dediee

`DeepLinkTripRoute` (`/trip/:tripId`) est une route top-level hors shell, avec transition slide :

```dart
@TypedGoRoute<DeepLinkTripRoute>(path: '/trip/:tripId')
class DeepLinkTripRoute extends GoRouteData {
  final String tripId;
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage(state: state, child: TripDetailPage(tripId: tripId));
}
```

### Deep links depuis notifications locales

`_handleLocalNotificationTap()` dans `main.dart` parse le payload JSON et navigue :

```dart
final path = switch (screen) {
  'activities' => '/home/$tripId/activities',
  'baggage' => '/home/$tripId/baggage',
  'budget' => '/home/$tripId/budget',
  _ => '/home/$tripId',
};
appRouter.go(path);
```

### Deep links depuis auth

Le redirect guard preserve la route intentionnelle via `?redirect=` dans l'URL de login.

## Helper de navigation dynamique

`tripFeatureRoute()` dans `route_definitions.dart` permet de naviguer vers un sous-module de voyage par nom :

```dart
GoRouteData tripFeatureRoute({
  required String tripId,
  required String featureRoute,
  required String role,
  required bool isCompleted,
}) {
  return switch (featureRoute) {
    'accommodations' => AccommodationsRoute(tripId: tripId, role: role, isCompleted: isCompleted),
    'baggage' => BaggageRoute(tripId: tripId, role: role, isCompleted: isCompleted),
    'activities' => ActivitiesRoute(tripId: tripId, role: role, isCompleted: isCompleted),
    'budget' => BudgetRoute(tripId: tripId, role: role, isCompleted: isCompleted),
    'transports' => TransportsRoute(tripId: tripId, role: role, isCompleted: isCompleted),
    _ => TripHomeRoute(tripId: tripId),
  };
}
```

Usage typique depuis une carte feature dans le detail voyage :

```dart
tripFeatureRoute(tripId: trip.id, featureRoute: 'activities', role: role, isCompleted: isCompleted).go(context);
```

## Passage de donnees complexes -- $extra

Pour les objets non-serialisables en URL, GoRouter `$extra` est utilise :

```dart
class PlanTripRoute extends GoRouteData {
  const PlanTripRoute({this.$extra});
  final LocationResult? $extra;
}

class FlightSearchResultRoute extends GoRouteData {
  const FlightSearchResultRoute({this.$extra});
  final FlightSearchArguments? $extra;
}
```

**Attention** : `$extra` est perdu si l'utilisateur refresh l'app ou restaure depuis un deep link. Les routes utilisant `$extra` gerent le cas `null` en fallback sur `HomePage`.

## AuthListener -- Deconnexion globale

`lib/auth/widgets/auth_listener.dart` ecoute `AuthEventBus.onUnauthenticated` et force la navigation vers `/login` :

```dart
class AuthListener extends StatefulWidget {
  final GoRouter router;
  final Widget child;
  // ...
}

_subscription = AuthEventBus.onUnauthenticated.listen((_) {
  widget.router.go('/login');
});
```

Ce widget wrappe l'ensemble de l'app dans `main.dart`, avant le `MaterialApp.router`.

## PersonalizationRoute -- Transition conditionnelle

`PersonalizationRoute` a une transition conditionnelle selon le contexte :

- **Navigation directe** (premier lancement) : `NoTransitionPage`.
- **Push depuis un ecran** (profil, creation voyage) : `buildSlideTransitionPage` pour que `pop()` fonctionne.

```dart
class PersonalizationRoute extends GoRouteData {
  final String? from;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (from != null) {
      return buildSlideTransitionPage(state: state, child: child);
    }
    return const NoTransitionPage(child: child);
  }
}
```

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Pas de gestion des erreurs 404 route | Aucune `errorBuilder` ou route catch-all configuree dans `GoRouter` -- une URL invalide causera un crash | P0 |
| MapRoute pointe vers un placeholder | `lib/navigation/route_definitions.dart:330` -- `MapRoute` rend `MapComingSoonView`, la carte n'est pas implementee | P1 |
| Deep link notifications limites | `_handleLocalNotificationTap` ne gere que 3 ecrans (activities, baggage, budget) -- les notifications pour accommodations, transports, shares ne sont pas routees | P1 |
| $extra perdu au refresh | Les routes `FlightSearchResultRoute` et `FlightResultDetailsRoute` utilisent `$extra` et fallback silencieusement sur `HomePage` si null -- pas de feedback utilisateur | P2 |
| NavigationBloc potentiellement inutilise | `NavigationBloc` dans `lib/navigation/bloc/` track l'onglet actif mais la navigation shell utilise `goBranch()` directement -- verifier si ce bloc est encore consomme | P2 |
| Pas de guard role-based | Le `redirect` ne verifie que l'authentification, pas les roles (OWNER/VIEWER) -- l'acces aux routes est controle uniquement par la UI | P2 |
| Listener GoRouter dans dispose() | `_AppShellState.dispose()` appelle `GoRouter.of(context)` qui peut etre invalide pendant le dispose (`lib/navigation/app_shell.dart:44-48`) -- wrape dans try/catch mais solution fragile | P2 |
| Transition iOS sans swipe-back | `buildWizardTransitionPage` sur iOS utilise `CupertinoPageTransition` sans `fullscreenDialog` mais le swipe-back n'est pas garanti sur les `CustomTransitionPage` GoRouter | P2 |
