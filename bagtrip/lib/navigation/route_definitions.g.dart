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
  $planifierRoute,
  $tripsRoute,
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

RouteBase get $planifierRoute => GoRouteData.$route(
  path: '/planifier',
  factory: $PlanifierRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'manual',
      factory: $PlanifierManualRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'transport',
          factory: $PlanifierManualTransportRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'other',
              factory: $PlanifierManualOtherTransportRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: 'flight-search',
          factory: $PlanifierManualFlightSearchRoute._fromState,
        ),
      ],
    ),
    GoRouteData.$route(
      path: 'create-trip-ai',
      factory: $CreateTripAiRoute._fromState,
    ),
  ],
);

mixin $PlanifierRoute on GoRouteData {
  static PlanifierRoute _fromState(GoRouterState state) =>
      const PlanifierRoute();

  @override
  String get location => GoRouteData.$location('/planifier');

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

mixin $PlanifierManualRoute on GoRouteData {
  static PlanifierManualRoute _fromState(GoRouterState state) =>
      const PlanifierManualRoute();

  @override
  String get location => GoRouteData.$location('/planifier/manual');

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

mixin $PlanifierManualTransportRoute on GoRouteData {
  static PlanifierManualTransportRoute _fromState(GoRouterState state) =>
      const PlanifierManualTransportRoute();

  @override
  String get location => GoRouteData.$location('/planifier/manual/transport');

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

mixin $PlanifierManualOtherTransportRoute on GoRouteData {
  static PlanifierManualOtherTransportRoute _fromState(GoRouterState state) =>
      const PlanifierManualOtherTransportRoute();

  @override
  String get location =>
      GoRouteData.$location('/planifier/manual/transport/other');

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

mixin $PlanifierManualFlightSearchRoute on GoRouteData {
  static PlanifierManualFlightSearchRoute _fromState(GoRouterState state) =>
      const PlanifierManualFlightSearchRoute();

  @override
  String get location =>
      GoRouteData.$location('/planifier/manual/flight-search');

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

mixin $CreateTripAiRoute on GoRouteData {
  static CreateTripAiRoute _fromState(GoRouterState state) =>
      const CreateTripAiRoute();

  @override
  String get location => GoRouteData.$location('/planifier/create-trip-ai');

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

RouteBase get $tripsRoute => GoRouteData.$route(
  path: '/trips',
  factory: $TripsRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: ':tripId',
      factory: $TripHomeRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'accommodations',
          factory: $AccommodationsRoute._fromState,
        ),
        GoRouteData.$route(path: 'baggage', factory: $BaggageRoute._fromState),
        GoRouteData.$route(
          path: 'activities',
          factory: $ActivitiesRoute._fromState,
        ),
        GoRouteData.$route(path: 'budget', factory: $BudgetRoute._fromState),
        GoRouteData.$route(path: 'shares', factory: $SharesRoute._fromState),
        GoRouteData.$route(
          path: 'feedback',
          factory: $FeedbackRoute._fromState,
        ),
      ],
    ),
  ],
);

mixin $TripsRoute on GoRouteData {
  static TripsRoute _fromState(GoRouterState state) => const TripsRoute();

  @override
  String get location => GoRouteData.$location('/trips');

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

mixin $TripHomeRoute on GoRouteData {
  static TripHomeRoute _fromState(GoRouterState state) =>
      TripHomeRoute(tripId: state.pathParameters['tripId']!);

  TripHomeRoute get _self => this as TripHomeRoute;

  @override
  String get location =>
      GoRouteData.$location('/trips/${Uri.encodeComponent(_self.tripId)}');

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
      );

  AccommodationsRoute get _self => this as AccommodationsRoute;

  @override
  String get location => GoRouteData.$location(
    '/trips/${Uri.encodeComponent(_self.tripId)}/accommodations',
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
    '/trips/${Uri.encodeComponent(_self.tripId)}/baggage',
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

mixin $ActivitiesRoute on GoRouteData {
  static ActivitiesRoute _fromState(GoRouterState state) => ActivitiesRoute(
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

  ActivitiesRoute get _self => this as ActivitiesRoute;

  @override
  String get location => GoRouteData.$location(
    '/trips/${Uri.encodeComponent(_self.tripId)}/activities',
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

mixin $BudgetRoute on GoRouteData {
  static BudgetRoute _fromState(GoRouterState state) => BudgetRoute(
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

  BudgetRoute get _self => this as BudgetRoute;

  @override
  String get location => GoRouteData.$location(
    '/trips/${Uri.encodeComponent(_self.tripId)}/budget',
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

mixin $SharesRoute on GoRouteData {
  static SharesRoute _fromState(GoRouterState state) => SharesRoute(
    tripId: state.pathParameters['tripId']!,
    role: state.uri.queryParameters['role'] ?? 'OWNER',
  );

  SharesRoute get _self => this as SharesRoute;

  @override
  String get location => GoRouteData.$location(
    '/trips/${Uri.encodeComponent(_self.tripId)}/shares',
    queryParams: {if (_self.role != 'OWNER') 'role': _self.role},
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
    '/trips/${Uri.encodeComponent(_self.tripId)}/feedback',
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

RouteBase get $profileRoute =>
    GoRouteData.$route(path: '/profile', factory: $ProfileRoute._fromState);

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
      const PaymentSuccessRoute();

  @override
  String get location => GoRouteData.$location('/payment/success');

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
