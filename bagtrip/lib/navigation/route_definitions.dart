import 'package:bagtrip/activities/view/activities_page.dart';
import 'package:bagtrip/trips/view/trip_locations_page.dart';
import 'package:bagtrip/transports/view/transports_page.dart';
import 'package:bagtrip/budget/view/budget_page.dart';
import 'package:bagtrip/flight_result_details/view/flight_result_details_page.dart';
import 'package:bagtrip/flight_search/models/flight_search_prefill.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/models/flight_search_arguments.dart';
import 'package:bagtrip/home/view/home_page.dart';
import 'package:bagtrip/navigation/page_transitions.dart';
import 'package:bagtrip/notifications/view/notifications_page.dart';
import 'package:bagtrip/accommodations/view/accommodations_page.dart';
import 'package:bagtrip/baggage/view/baggage_page.dart';
import 'package:bagtrip/pages/feedback_page.dart';
import 'package:bagtrip/post_trip/view/post_trip_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/onboarding_page.dart';
import 'package:bagtrip/pages/payment/payment_cancel_page.dart';
import 'package:bagtrip/pages/payment/payment_result_page.dart';
import 'package:bagtrip/pages/payment/payment_success_page.dart';
import 'package:bagtrip/pages/personalization_page.dart';
import 'package:bagtrip/pages/planifier_manual_flight_page.dart';
import 'package:bagtrip/profile/view/personal_info_page.dart';
import 'package:bagtrip/profile/view/settings_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/splash_page.dart';
import 'package:bagtrip/pages/subscription/subscription_cancel_page.dart';
import 'package:bagtrip/pages/subscription/subscription_success_page.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_view.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/view/plan_trip_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'route_definitions.g.dart';

// ---------------------------------------------------------------------------
// Top-level auth routes (NoTransitionPage)
// ---------------------------------------------------------------------------

@TypedGoRoute<SplashRoute>(path: '/')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: SplashPage());
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: LoginPage());
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: OnboardingPage());
}

@TypedGoRoute<PersonalizationRoute>(path: '/personalization')
class PersonalizationRoute extends GoRouteData with $PersonalizationRoute {
  const PersonalizationRoute({this.from});

  final String? from;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    const child = PersonalizationPage();
    // When pushed from another screen (profile, trip creation), use a proper
    // slide transition so that pop() works correctly. NoTransitionPage breaks
    // the imperative push/pop lifecycle (Future already completed).
    if (from != null) {
      return buildSlideTransitionPage<void>(state: state, child: child);
    }
    return const NoTransitionPage(child: child);
  }
}

// ---------------------------------------------------------------------------
// Deep link — direct trip access
//
// Redirects `/trip/:tripId` to `/home/:tripId` so the deep link traverses the
// `TripDetailShellRoute` that provisions `TripDetailBloc` for the sub-pages.
// ---------------------------------------------------------------------------

@TypedGoRoute<DeepLinkTripRoute>(path: '/trip/:tripId')
class DeepLinkTripRoute extends GoRouteData with $DeepLinkTripRoute {
  const DeepLinkTripRoute({required this.tripId});
  final String tripId;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      TripHomeRoute(tripId: tripId).location;
}

// ---------------------------------------------------------------------------
// Branch 0 — Home (replaces Explorer + Trips)
// ---------------------------------------------------------------------------

@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [
    TypedGoRoute<PlanTripRoute>(path: 'plan'),
    TypedGoRoute<TripFlightSearchRoute>(path: 'flight-search'),
    TypedGoRoute<TripDetailRoute>(path: 'trip/:tripId'),
    TypedShellRoute<TripDetailShellRoute>(
      routes: [
        TypedGoRoute<TripHomeRoute>(
          path: ':tripId',
          routes: [
            TypedGoRoute<AccommodationsRoute>(path: 'accommodations'),
            TypedGoRoute<BaggageRoute>(path: 'baggage'),
            TypedGoRoute<ActivitiesRoute>(path: 'activities'),
            TypedGoRoute<BudgetRoute>(path: 'budget'),
            TypedGoRoute<TransportsRoute>(path: 'transports'),
            TypedGoRoute<FeedbackRoute>(path: 'feedback'),
            TypedGoRoute<PostTripRoute>(path: 'post-trip'),
            TypedGoRoute<MapRoute>(path: 'map'),
          ],
        ),
      ],
    ),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: HomePage());
}

/// Shell that provisions a single `TripDetailBloc` shared by `TripHomeRoute`
/// and all its trip-scoped sub-routes (`activities`, `transports`,
/// `accommodations`, `baggage`, `budget`, `shares`, `feedback`, `post-trip`,
/// `map`). The `ValueKey(tripId)` forces a fresh bloc per trip so switching
/// trip ids re-creates the provider rather than reusing stale state.
class TripDetailShellRoute extends ShellRouteData {
  const TripDetailShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final tripId = state.pathParameters['tripId'];
    if (tripId == null || tripId.isEmpty) {
      return navigator;
    }
    return BlocProvider<TripDetailBloc>(
      key: ValueKey('trip-detail-bloc-$tripId'),
      create: (_) => TripDetailBloc()..add(LoadTripDetail(tripId: tripId)),
      child: navigator,
    );
  }
}

class PlanTripRoute extends GoRouteData with $PlanTripRoute {
  const PlanTripRoute({this.$extra});

  final LocationResult? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildWizardTransitionPage<void>(
        state: state,
        child: PlanTripFlowPage(initialDestination: $extra),
      );
}

class TripFlightSearchRoute extends GoRouteData with $TripFlightSearchRoute {
  const TripFlightSearchRoute({this.$extra});

  final FlightSearchPrefill? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: PlanifierManualFlightPage(prefill: $extra),
      );
}

/// Legacy path kept for backward compatibility. Redirects to `/home/:tripId`
/// so the navigation traverses `TripDetailShellRoute` and gets a shared
/// `TripDetailBloc`.
class TripDetailRoute extends GoRouteData with $TripDetailRoute {
  const TripDetailRoute({required this.tripId});
  final String tripId;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      TripHomeRoute(tripId: tripId).location;
}

class TripHomeRoute extends GoRouteData with $TripHomeRoute {
  const TripHomeRoute({required this.tripId});

  final String tripId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: TripDetailView(tripId: tripId),
      );
}

class AccommodationsRoute extends GoRouteData with $AccommodationsRoute {
  const AccommodationsRoute({
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
    this.tripEndDate,
    this.destinationIata,
  });

  final String tripId;
  final String role;
  final bool isCompleted;
  final String? tripStartDate;
  final String? tripEndDate;
  final String? destinationIata;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: AccommodationsPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
          tripStartDate: tripStartDate != null
              ? DateTime.tryParse(tripStartDate!)
              : null,
          tripEndDate: tripEndDate != null
              ? DateTime.tryParse(tripEndDate!)
              : null,
          destinationIata: destinationIata,
        ),
      );
}

class BaggageRoute extends GoRouteData with $BaggageRoute {
  const BaggageRoute({
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  final String tripId;
  final String role;
  final bool isCompleted;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: BaggageBlocPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
        ),
      );
}

class ActivitiesRoute extends GoRouteData with $ActivitiesRoute {
  const ActivitiesRoute({
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
  });

  final String tripId;
  final String role;
  final bool isCompleted;
  final String? tripStartDate;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: ActivitiesPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
          tripStartDate: tripStartDate != null
              ? DateTime.tryParse(tripStartDate!)
              : null,
        ),
      );
}

class BudgetRoute extends GoRouteData with $BudgetRoute {
  const BudgetRoute({
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  final String tripId;
  final String role;
  final bool isCompleted;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: BudgetPage(tripId: tripId, role: role, isCompleted: isCompleted),
      );
}

class TransportsRoute extends GoRouteData with $TransportsRoute {
  const TransportsRoute({
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  final String tripId;
  final String role;
  final bool isCompleted;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: TransportsPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
        ),
      );
}

class MapRoute extends GoRouteData with $MapRoute {
  const MapRoute({required this.tripId});

  final String tripId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: TripLocationsPage(tripId: tripId),
      );
}

class FeedbackRoute extends GoRouteData with $FeedbackRoute {
  const FeedbackRoute({required this.tripId});

  final String tripId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: FeedbackPage(tripId: tripId),
      );
}

class PostTripRoute extends GoRouteData with $PostTripRoute {
  const PostTripRoute({required this.tripId});

  final String tripId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: PostTripPage(tripId: tripId),
      );
}

// ---------------------------------------------------------------------------
// Branch 1 — Activity
// ---------------------------------------------------------------------------

@TypedGoRoute<ActivityRoute>(path: '/activity')
class ActivityRoute extends GoRouteData with $ActivityRoute {
  const ActivityRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: NotificationsPage());
}

// ---------------------------------------------------------------------------
// Branch 2 — Profile
// ---------------------------------------------------------------------------

@TypedGoRoute<ProfileRoute>(
  path: '/profile',
  routes: [
    TypedGoRoute<PersonalInfoRoute>(path: 'personal-info'),
    TypedGoRoute<SettingsRoute>(path: 'settings'),
  ],
)
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: ProfilePage());
}

class PersonalInfoRoute extends GoRouteData with $PersonalInfoRoute {
  const PersonalInfoRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PersonalInfoPage(),
      );
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(state: state, child: const SettingsPage());
}

// ---------------------------------------------------------------------------
// Top-level routes outside shell
// ---------------------------------------------------------------------------

@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  const NotificationsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const NotificationsPage(),
      );
}

@TypedGoRoute<FlightSearchResultRoute>(path: '/flight-search-result')
class FlightSearchResultRoute extends GoRouteData
    with $FlightSearchResultRoute {
  const FlightSearchResultRoute({this.$extra});

  final FlightSearchArguments? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if ($extra == null) {
      return const NoTransitionPage(child: HomePage());
    }
    return buildSlideTransitionPage<void>(
      state: state,
      child: FlightSearchResultPage(arguments: $extra!),
    );
  }
}

@TypedGoRoute<FlightResultDetailsRoute>(path: '/flight-result-details')
class FlightResultDetailsRoute extends GoRouteData
    with $FlightResultDetailsRoute {
  const FlightResultDetailsRoute({this.$extra});

  final Flight? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if ($extra == null) {
      return const NoTransitionPage(child: HomePage());
    }
    return buildSlideTransitionPage<void>(
      state: state,
      child: FlightResultDetailsPage(flight: $extra!),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription routes (outside shell)
// ---------------------------------------------------------------------------

@TypedGoRoute<SubscriptionSuccessRoute>(path: '/subscription/success')
class SubscriptionSuccessRoute extends GoRouteData
    with $SubscriptionSuccessRoute {
  const SubscriptionSuccessRoute({this.sessionId});

  final String? sessionId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: SubscriptionSuccessPage(sessionId: sessionId),
      );
}

@TypedGoRoute<SubscriptionCancelRoute>(path: '/subscription/cancel')
class SubscriptionCancelRoute extends GoRouteData
    with $SubscriptionCancelRoute {
  const SubscriptionCancelRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const SubscriptionCancelPage(),
      );
}

// ---------------------------------------------------------------------------
// Payment routes (outside shell)
// ---------------------------------------------------------------------------

@TypedGoRoute<PaymentSuccessRoute>(path: '/payment/success')
class PaymentSuccessRoute extends GoRouteData with $PaymentSuccessRoute {
  final String? intentId;
  const PaymentSuccessRoute({this.intentId});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: PaymentSuccessPage(intentId: intentId),
      );
}

@TypedGoRoute<PaymentCancelRoute>(path: '/payment/cancel')
class PaymentCancelRoute extends GoRouteData with $PaymentCancelRoute {
  const PaymentCancelRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PaymentCancelPage(),
      );
}

@TypedGoRoute<PaymentResultRoute>(path: '/payment/result')
class PaymentResultRoute extends GoRouteData with $PaymentResultRoute {
  const PaymentResultRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PaymentResultPage(),
      );
}

// ---------------------------------------------------------------------------
// Helper for dynamic feature.route dispatch
// ---------------------------------------------------------------------------

GoRouteData tripFeatureRoute({
  required String tripId,
  required String featureRoute,
  required String role,
  required bool isCompleted,
}) {
  return switch (featureRoute) {
    'accommodations' => AccommodationsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ),
    'baggage' => BaggageRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ),
    'activities' => ActivitiesRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ),
    'budget' => BudgetRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ),
    'transports' => TransportsRoute(
      tripId: tripId,
      role: role,
      isCompleted: isCompleted,
    ),
    _ => TripHomeRoute(tripId: tripId),
  };
}
