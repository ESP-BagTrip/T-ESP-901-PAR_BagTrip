// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_definitions.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $splashRoute,
  $loginRoute,
  $onboardingRoute,
  $personalizationRoute,
  $deepLinkTripRoute,
  $homeRoute,
  $activityRoute,
  $profileRoute,
  $notificationsRoute,
  $flightSearchResultRoute,
  $flightResultDetailsRoute,
  $subscriptionSuccessRoute,
  $subscriptionCancelRoute,
  $paymentSuccessRoute,
  $paymentCancelRoute,
  $paymentResultRoute,
];

RouteBase get $splashRoute =>
    GoRouteData.$route(path: '/', factory: $SplashRoute._fromState);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute =>
    GoRouteData.$route(path: '/login', factory: $LoginRoute._fromState);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',
  factory: $OnboardingRoute._fromState,
);

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $personalizationRoute => GoRouteData.$route(
  path: '/personalization',
  factory: $PersonalizationRoute._fromState,
);

mixin $PersonalizationRoute on GoRouteData {
  static PersonalizationRoute _fromState(GoRouterState state) =>
      PersonalizationRoute(from: state.uri.queryParameters['from']);

  PersonalizationRoute get _self => this as PersonalizationRoute;

  @override
  String get location => GoRouteData.$location(
    '/personalization',
    queryParams: {if (_self.from != null) 'from': _self.from},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $deepLinkTripRoute => GoRouteData.$route(
  path: '/trip/:tripId',
  factory: $DeepLinkTripRoute._fromState,
);

mixin $DeepLinkTripRoute on GoRouteData {
  static DeepLinkTripRoute _fromState(GoRouterState state) =>
      DeepLinkTripRoute(tripId: state.pathParameters['tripId']!);

  DeepLinkTripRoute get _self => this as DeepLinkTripRoute;

  @override
  String get location =>
      GoRouteData.$location('/trip/${Uri.encodeComponent(_self.tripId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/home',
  factory: $HomeRoute._fromState,
  routes: [
    GoRouteData.$route(path: 'plan', factory: $PlanTripRoute._fromState),
    GoRouteData.$route(
      path: 'flight-search',
      factory: $TripFlightSearchRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'trip/:tripId',
      factory: $TripDetailRoute._fromState,
    ),
    ShellRouteData.$route(
      factory: $TripDetailShellRouteExtension._fromState,
      routes: [
        GoRouteData.$route(
          path: ':tripId',
          factory: $TripHomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'accommodations',
              factory: $AccommodationsRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'baggage',
              factory: $BaggageRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'feedback',
              factory: $FeedbackRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'post-trip',
              factory: $PostTripRoute._fromState,
            ),
            GoRouteData.$route(path: 'map', factory: $MapRoute._fromState),
          ],
        ),
      ],
    ),
  ],
);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlanTripRoute on GoRouteData {
  static PlanTripRoute _fromState(GoRouterState state) =>
      PlanTripRoute($extra: state.extra as LocationResult?);

  PlanTripRoute get _self => this as PlanTripRoute;

  @override
  String get location => GoRouteData.$location('/home/plan');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

mixin $TripFlightSearchRoute on GoRouteData {
  static TripFlightSearchRoute _fromState(GoRouterState state) =>
      TripFlightSearchRoute($extra: state.extra as FlightSearchPrefill?);

  TripFlightSearchRoute get _self => this as TripFlightSearchRoute;

  @override
  String get location => GoRouteData.$location('/home/flight-search');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

mixin $TripDetailRoute on GoRouteData {
  static TripDetailRoute _fromState(GoRouterState state) =>
      TripDetailRoute(tripId: state.pathParameters['tripId']!);

  TripDetailRoute get _self => this as TripDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/home/trip/${Uri.encodeComponent(_self.tripId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

extension $TripDetailShellRouteExtension on TripDetailShellRoute {
  static TripDetailShellRoute _fromState(GoRouterState state) =>
      const TripDetailShellRoute();
}

mixin $TripHomeRoute on GoRouteData {
  static TripHomeRoute _fromState(GoRouterState state) =>
      TripHomeRoute(tripId: state.pathParameters['tripId']!);

  TripHomeRoute get _self => this as TripHomeRoute;

  @override
  String get location =>
      GoRouteData.$location('/home/${Uri.encodeComponent(_self.tripId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccommodationsRoute on GoRouteData {
  static AccommodationsRoute _fromState(GoRouterState state) =>
      AccommodationsRoute(
        tripId: state.pathParameters['tripId']!,
        role: state.uri.queryParameters['role'] ?? 'OWNER',
        isCompleted:
            _$convertMapValue(
              'is-completed',
              state.uri.queryParameters,
              _$boolConverter,
            ) ??
            false,
        tripStartDate: state.uri.queryParameters['trip-start-date'],
        tripEndDate: state.uri.queryParameters['trip-end-date'],
        destinationIata: state.uri.queryParameters['destination-iata'],
      );

  AccommodationsRoute get _self => this as AccommodationsRoute;

  @override
  String get location => GoRouteData.$location(
    '/home/${Uri.encodeComponent(_self.tripId)}/accommodations',
    queryParams: {
      if (_self.role != 'OWNER') 'role': _self.role,
      if (_self.isCompleted != false)
        'is-completed': _self.isCompleted.toString(),
      if (_self.tripStartDate != null) 'trip-start-date': _self.tripStartDate,
      if (_self.tripEndDate != null) 'trip-end-date': _self.tripEndDate,
      if (_self.destinationIata != null)
        'destination-iata': _self.destinationIata,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BaggageRoute on GoRouteData {
  static BaggageRoute _fromState(GoRouterState state) => BaggageRoute(
    tripId: state.pathParameters['tripId']!,
    role: state.uri.queryParameters['role'] ?? 'OWNER',
    isCompleted:
        _$convertMapValue(
          'is-completed',
          state.uri.queryParameters,
          _$boolConverter,
        ) ??
        false,
  );

  BaggageRoute get _self => this as BaggageRoute;

  @override
  String get location => GoRouteData.$location(
    '/home/${Uri.encodeComponent(_self.tripId)}/baggage',
    queryParams: {
      if (_self.role != 'OWNER') 'role': _self.role,
      if (_self.isCompleted != false)
        'is-completed': _self.isCompleted.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FeedbackRoute on GoRouteData {
  static FeedbackRoute _fromState(GoRouterState state) =>
      FeedbackRoute(tripId: state.pathParameters['tripId']!);

  FeedbackRoute get _self => this as FeedbackRoute;

  @override
  String get location => GoRouteData.$location(
    '/home/${Uri.encodeComponent(_self.tripId)}/feedback',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PostTripRoute on GoRouteData {
  static PostTripRoute _fromState(GoRouterState state) =>
      PostTripRoute(tripId: state.pathParameters['tripId']!);

  PostTripRoute get _self => this as PostTripRoute;

  @override
  String get location => GoRouteData.$location(
    '/home/${Uri.encodeComponent(_self.tripId)}/post-trip',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MapRoute on GoRouteData {
  static MapRoute _fromState(GoRouterState state) =>
      MapRoute(tripId: state.pathParameters['tripId']!);

  MapRoute get _self => this as MapRoute;

  @override
  String get location =>
      GoRouteData.$location('/home/${Uri.encodeComponent(_self.tripId)}/map');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

RouteBase get $activityRoute =>
    GoRouteData.$route(path: '/activity', factory: $ActivityRoute._fromState);

mixin $ActivityRoute on GoRouteData {
  static ActivityRoute _fromState(GoRouterState state) => const ActivityRoute();

  @override
  String get location => GoRouteData.$location('/activity');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $profileRoute => GoRouteData.$route(
  path: '/profile',
  factory: $ProfileRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'personal-info',
      factory: $PersonalInfoRoute._fromState,
    ),
    GoRouteData.$route(path: 'settings', factory: $SettingsRoute._fromState),
  ],
);

mixin $ProfileRoute on GoRouteData {
  static ProfileRoute _fromState(GoRouterState state) => const ProfileRoute();

  @override
  String get location => GoRouteData.$location('/profile');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PersonalInfoRoute on GoRouteData {
  static PersonalInfoRoute _fromState(GoRouterState state) =>
      const PersonalInfoRoute();

  @override
  String get location => GoRouteData.$location('/profile/personal-info');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/profile/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $notificationsRoute => GoRouteData.$route(
  path: '/notifications',
  factory: $NotificationsRoute._fromState,
);

mixin $NotificationsRoute on GoRouteData {
  static NotificationsRoute _fromState(GoRouterState state) =>
      const NotificationsRoute();

  @override
  String get location => GoRouteData.$location('/notifications');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $flightSearchResultRoute => GoRouteData.$route(
  path: '/flight-search-result',
  factory: $FlightSearchResultRoute._fromState,
);

mixin $FlightSearchResultRoute on GoRouteData {
  static FlightSearchResultRoute _fromState(GoRouterState state) =>
      FlightSearchResultRoute($extra: state.extra as FlightSearchArguments?);

  FlightSearchResultRoute get _self => this as FlightSearchResultRoute;

  @override
  String get location => GoRouteData.$location('/flight-search-result');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $flightResultDetailsRoute => GoRouteData.$route(
  path: '/flight-result-details',
  factory: $FlightResultDetailsRoute._fromState,
);

mixin $FlightResultDetailsRoute on GoRouteData {
  static FlightResultDetailsRoute _fromState(GoRouterState state) =>
      FlightResultDetailsRoute($extra: state.extra as Flight?);

  FlightResultDetailsRoute get _self => this as FlightResultDetailsRoute;

  @override
  String get location => GoRouteData.$location('/flight-result-details');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $subscriptionSuccessRoute => GoRouteData.$route(
  path: '/subscription/success',
  factory: $SubscriptionSuccessRoute._fromState,
);

mixin $SubscriptionSuccessRoute on GoRouteData {
  static SubscriptionSuccessRoute _fromState(GoRouterState state) =>
      SubscriptionSuccessRoute(
        sessionId: state.uri.queryParameters['session-id'],
      );

  SubscriptionSuccessRoute get _self => this as SubscriptionSuccessRoute;

  @override
  String get location => GoRouteData.$location(
    '/subscription/success',
    queryParams: {if (_self.sessionId != null) 'session-id': _self.sessionId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $subscriptionCancelRoute => GoRouteData.$route(
  path: '/subscription/cancel',
  factory: $SubscriptionCancelRoute._fromState,
);

mixin $SubscriptionCancelRoute on GoRouteData {
  static SubscriptionCancelRoute _fromState(GoRouterState state) =>
      const SubscriptionCancelRoute();

  @override
  String get location => GoRouteData.$location('/subscription/cancel');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $paymentSuccessRoute => GoRouteData.$route(
  path: '/payment/success',
  factory: $PaymentSuccessRoute._fromState,
);

mixin $PaymentSuccessRoute on GoRouteData {
  static PaymentSuccessRoute _fromState(GoRouterState state) =>
      PaymentSuccessRoute(intentId: state.uri.queryParameters['intent-id']);

  PaymentSuccessRoute get _self => this as PaymentSuccessRoute;

  @override
  String get location => GoRouteData.$location(
    '/payment/success',
    queryParams: {if (_self.intentId != null) 'intent-id': _self.intentId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $paymentCancelRoute => GoRouteData.$route(
  path: '/payment/cancel',
  factory: $PaymentCancelRoute._fromState,
);

mixin $PaymentCancelRoute on GoRouteData {
  static PaymentCancelRoute _fromState(GoRouterState state) =>
      const PaymentCancelRoute();

  @override
  String get location => GoRouteData.$location('/payment/cancel');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $paymentResultRoute => GoRouteData.$route(
  path: '/payment/result',
  factory: $PaymentResultRoute._fromState,
);

mixin $PaymentResultRoute on GoRouteData {
  static PaymentResultRoute _fromState(GoRouterState state) =>
      const PaymentResultRoute();

  @override
  String get location => GoRouteData.$location('/payment/result');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
