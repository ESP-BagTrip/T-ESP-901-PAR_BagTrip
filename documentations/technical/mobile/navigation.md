# Navigation Mobile BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

La navigation BagTrip repose sur **GoRouter** avec routes type-safe generees via `@TypedGoRoute`. Le squelette est un `StatefulShellRoute.indexedStack` a 3 branches (Home, Activity, Profile), chaque branche preservant son back stack lors d'un changement d'onglet. Le shell est rendu par `AppShell`, qui detecte les routes top-level pour afficher ou masquer la bottom bar (`GlassBottomBar` sur iOS, `NavigationBar` Material sur Android). Toutes les routes sont declarees dans `lib/navigation/route_definitions.dart` et le code de support est genere dans `route_definitions.g.dart` via `build_runner`.

Trois points cles structurent l'architecture :

1. **Routes type-safe** : chaque page est une classe `GoRouteData` annotee `@TypedGoRoute`, naviguee via `RouteClass(...).go(context)` au lieu d'une string brute.
2. **Auth guard centralise** : le `redirect` du `GoRouter` global est l'unique point de verification d'authentification. Aucune page ne doit dupliquer la logique.
3. **Deep links unifies** : `resolveNotificationRoute()` traduit un payload de notification en chemin canonique, consomme par tous les entry points (foreground, tap background, cold start, liste in-app).

## Routes typees

Definies dans `lib/navigation/route_definitions.dart`, generees dans `route_definitions.g.dart`. La regeneration se fait avec `flutter pub run build_runner build --delete-conflicting-outputs` apres toute modification.

| Route class                  | Path                                  | Page rendue                       |
|------------------------------|---------------------------------------|-----------------------------------|
| `SplashRoute`                | `/`                                   | `SplashPage`                      |
| `LoginRoute`                 | `/login`                              | `LoginPage`                       |
| `OnboardingRoute`            | `/onboarding`                         | `OnboardingPage`                  |
| `PersonalizationRoute`       | `/personalization`                    | `PersonalizationPage`             |
| `DeepLinkTripRoute`          | `/trip/:tripId`                       | redirige vers `/home/:tripId`     |
| `HomeRoute`                  | `/home`                               | `HomePage`                        |
| `PlanTripRoute`              | `/home/plan`                          | `PlanTripFlowPage`                |
| `TripFlightSearchRoute`      | `/home/flight-search`                 | `PlanifierManualFlightPage`       |
| `TripDetailRoute`            | `/home/trip/:tripId`                  | redirige vers `/home/:tripId`     |
| `TripHomeRoute`              | `/home/:tripId`                       | `TripDetailView`                  |
| `AccommodationsRoute`        | `/home/:tripId/accommodations`        | `AccommodationsPage`              |
| `BaggageRoute`               | `/home/:tripId/baggage`               | `BaggageBlocPage`                 |
| `FeedbackRoute`              | `/home/:tripId/feedback`              | `FeedbackPage`                    |
| `PostTripRoute`              | `/home/:tripId/post-trip`             | `PostTripPage`                    |
| `MapRoute`                   | `/home/:tripId/map`                   | `TripLocationsPage`               |
| `ActivityRoute`              | `/activity`                           | `NotificationsPage`               |
| `ProfileRoute`               | `/profile`                            | `ProfilePage`                     |
| `PersonalInfoRoute`          | `/profile/personal-info`              | `PersonalInfoPage`                |
| `SettingsRoute`              | `/profile/settings`                   | `SettingsPage`                    |
| `SubscriptionSettingsRoute`  | `/profile/subscription`               | `SubscriptionSettingsPage`        |
| `SubscriptionInvoicesRoute`  | `/profile/subscription/invoices`      | `InvoicesPage`                    |
| `NotificationsRoute`         | `/notifications`                      | `NotificationsPage`               |
| `FlightSearchResultRoute`    | `/flight-search-result`               | `FlightSearchResultPage`          |
| `FlightResultDetailsRoute`   | `/flight-result-details`              | `FlightResultDetailsPage`         |
| `SubscriptionSuccessRoute`   | `/subscription/success`               | `SubscriptionSuccessPage`         |
| `SubscriptionCancelRoute`    | `/subscription/cancel`                | `SubscriptionCancelPage`          |
| `PaymentSuccessRoute`        | `/payment/success`                    | `PaymentSuccessPage`              |
| `PaymentCancelRoute`         | `/payment/cancel`                     | `PaymentCancelPage`               |
| `PaymentResultRoute`         | `/payment/result`                     | `PaymentResultPage`               |

Navigation type-safe : `TripHomeRoute(tripId: '123').go(context)`. Les parametres complexes non-serialisables passent par `$extra` (`PlanTripRoute($extra: locationResult).go(context)`).

Sous-arbre trip particulier : `/home/:tripId/*` est wrappe par un `TypedShellRoute<TripDetailShellRoute>` qui injecte un `BlocProvider<TripDetailBloc>` keye par `tripId`. Ce shell garantit que `TripHomeRoute` et toutes les sous-routes (`accommodations`, `baggage`, `feedback`, `post-trip`, `map`) partagent le meme bloc, et qu'un changement de `tripId` recree un bloc neuf au lieu de reutiliser un state stale.

## Shell branches

Le `StatefulShellRoute.indexedStack` declare 3 branches qui correspondent aux 3 onglets de la bottom bar :

| Index | Path     | Branche                                | Onglet   |
|-------|----------|----------------------------------------|----------|
| 0     | `/home`  | `$homeRoute` + sous-routes trip        | Home     |
| 1     | `/activity` | `$activityRoute`                    | Activity |
| 2     | `/profile`  | `$profileRoute` + sous-routes profil | Profile  |

L'ordre des branches doit matcher exactement `_shellTabOrder` dans `lib/navigation/app_shell.dart` (`[home, activity, profile]`). Le changement d'onglet passe par `widget.navigationShell.goBranch(index)`, jamais par un `context.go('/home')` qui detruirait le back stack de la branche cible.

## Redirect auth

Le `redirect` du `GoRouter` global (`lib/navigation/app_router.dart`) centralise toute la logique d'authentification. Aucune page ne doit dupliquer ce check.

Comportement :

1. Le path `/` (splash) est laisse passer : c'est la splash qui declenche le bootstrap auth au demarrage.
2. Pour toute autre route, `AuthRepository.isAuthenticated()` est appele via `getIt`.
3. Si non authentifie et hors `/login` / `/onboarding` : redirection vers `/login?redirect=<intended>` ou `intended` est l'URL d'origine encodee.
4. Si authentifie et sur `/login` : si un `?redirect=` est present, decode et redirige vers cette URL (sauf si elle pointe vers `/login` ou `/`).

Cette structure preserve la destination intentionnelle d'un deep link declenche alors que l'utilisateur n'est pas connecte. La query string `?redirect=` est l'unique mecanisme de propagation, il n'y a pas de state global ou de cache d'intention.

`errorBuilder` est cable sur `NotFoundPage` : une URL invalide ne crashe plus mais affiche une page 404 dediee.

## Deep links

### Notifications

`lib/notifications/notification_deep_link.dart` expose `resolveNotificationRoute(Map<String, dynamic>? data) -> String?`. C'est la **single source of truth** pour traduire un payload de notification en chemin in-app, consomme par tous les entry points :

- Relay FCM en foreground.
- Tap sur une push backgroundee.
- Cold start depuis une push terminee.
- Tap dans la liste in-app des notifications.

Le vocabulaire `screen` est defini cote backend (`api/src/services/notification_service.py`, `notification_job.py`). Mapping actuel :

| `data.screen`     | Route resolue            |
|-------------------|--------------------------|
| `feedback`        | `FeedbackRoute`          |
| `post-trip`       | `PostTripRoute`          |
| `baggage`         | `BaggageRoute`           |
| `accommodations`  | `AccommodationsRoute`    |
| `map`             | `MapRoute`               |
| autre / absent    | `TripHomeRoute`          |

Si `tripId` est absent ou non-string, la fonction retourne `null` et les callers ne naviguent pas. Le fallback `TripHomeRoute` garantit qu'un nouveau `screen` ajoute cote backend n'echoue jamais le client : il atterit sur le detail voyage, qui sert de hub pour activites / budget / transports / shares.

### Route legacy

`DeepLinkTripRoute` (`/trip/:tripId`) ne rend rien : son seul role est de rediriger vers `/home/:tripId` pour que le deep link traverse `TripDetailShellRoute` et beneficie du `TripDetailBloc` provisionne. Idem pour `TripDetailRoute` (`/home/trip/:tripId`) qui est une compat backward.

### $extra perdu au refresh

Les routes `PlanTripRoute`, `TripFlightSearchRoute`, `FlightSearchResultRoute` et `FlightResultDetailsRoute` utilisent `$extra` pour passer des objets non-serialisables (`LocationResult`, `FlightSearchPrefill`, `FlightSearchArguments`, `Flight`). Si l'app est redemarree sur une de ces URLs (deep link froid, refresh), `$extra` est `null` et la page fallback silencieusement sur `HomePage`.

## AppShell et bottom bar

`AppShell` (`lib/navigation/app_shell.dart`) est le widget qui wrappe le `StatefulNavigationShell` et gere l'affichage conditionnel de la bottom bar.

### Detection top-level

```dart
const _topLevelPaths = {'/home', '/activity', '/profile'};
```

Un listener attache a `GoRouter.of(context).routerDelegate` recalcule `_isTopLevel` a chaque changement de route. La bottom bar n'est rendue que si le path courant est dans `_topLevelPaths`. Toute sous-page (`/home/:tripId`, `/profile/settings`, etc.) masque automatiquement la bottom bar.

### Adaptatif iOS vs Android

| Plateforme | Container             | Bottom bar                    | Strategie                                              |
|------------|-----------------------|-------------------------------|--------------------------------------------------------|
| iOS        | `CupertinoPageScaffold` + `Stack` | `GlassBottomBar` positionnee en overlay | La bar flotte au-dessus du content via `Positioned(bottom: 0)`. Le content passe **sous** la bar. |
| Android    | `Scaffold`            | `NavigationBar` Material      | Bar standard dans `bottomNavigationBar`, qui reserve son espace dans le layout. |

### Bottom padding compensatoire

Comme la bottom bar iOS est en overlay et ne reserve pas de hauteur, **chaque sous-page doit prevoir un bottom padding** pour que le scroll content ne soit pas mange par la bar. Convention figee dans le design system :

```dart
final bottomPadding = AdaptivePlatform.isIOS ? 100.0 : AppSpacing.space32;
```

- iOS : 100 px (hauteur `GlassBottomBar` + safe area).
- Android : 32 px (les sous-pages n'ont pas la bar, mais on conserve un padding de respiration).

Cette convention est appliquee dans toutes les pages qui contiennent un `ListView`, `SingleChildScrollView` ou `CustomScrollView` susceptibles de scroller jusqu'en bas.

### Badge notifications

L'onglet Activity affiche un badge avec le compteur de notifications non lues, alimente par `NotificationCountCubit` via un `BlocBuilder` dans `AppShell.build()`. Le compteur est rafraichi a chaque mutation cote `NotificationsBloc`.

## Ce qu'il manque

| Element                              | Description                                                                                                       | Priorite |
|--------------------------------------|-------------------------------------------------------------------------------------------------------------------|----------|
| Listener GoRouter dans `dispose()`   | `_AppShellState.dispose()` appelle `GoRouter.of(context)` dans un `try/catch` muet ; solution fragile             | P2       |
| Pas de guard role-based              | Le `redirect` ne verifie que l'auth ; les controles OWNER / VIEWER / EDITOR vivent uniquement dans la UI          | P2       |
| Feedback `$extra == null`            | `FlightSearchResultRoute` / `FlightResultDetailsRoute` fallback silencieusement sur `HomePage` sans message       | P2       |
| `ActivityRoute` reutilise `NotificationsPage` | La branche 1 du shell rend la meme page que `/notifications` ; pas de differenciation contextuelle       | P3       |
| Deep links partiels                  | `resolveNotificationRoute` ne couvre pas `transports`, `shares`, `budget` (tous fallback sur `TripHomeRoute`)     | P3       |
| Pas de tests de navigation E2E       | Aucun test ne valide les redirections auth, le routing notification deep link, ni la persistence du back stack   | P2       |
