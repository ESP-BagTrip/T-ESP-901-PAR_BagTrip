import 'package:bagtrip/activities/view/activities_page.dart';
import 'package:bagtrip/budget/view/budget_page.dart';
import 'package:bagtrip/flight_result_details/view/flight_result_details_page.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search_result/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/page_transitions.dart';
import 'package:bagtrip/notifications/view/activity_page.dart';
import 'package:bagtrip/notifications/view/notifications_page.dart';
import 'package:bagtrip/pages/accommodations_page.dart';
import 'package:bagtrip/pages/baggage_page.dart';
import 'package:bagtrip/pages/create_trip_ai_flow_page.dart';
import 'package:bagtrip/pages/feedback_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/onboarding_page.dart';
import 'package:bagtrip/pages/payment/payment_cancel_page.dart';
import 'package:bagtrip/pages/payment/payment_result_page.dart';
import 'package:bagtrip/pages/payment/payment_success_page.dart';
import 'package:bagtrip/pages/personalization_page.dart';
import 'package:bagtrip/profile/view/personal_info_page.dart';
import 'package:bagtrip/profile/view/settings_page.dart';
import 'package:bagtrip/pages/planifier_manual_flight_page.dart';
import 'package:bagtrip/pages/planifier_manual_other_transport_page.dart';
import 'package:bagtrip/pages/planifier_manual_page.dart';
import 'package:bagtrip/pages/planifier_manual_transport_page.dart';
import 'package:bagtrip/pages/planifier_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/splash_page.dart';
import 'package:bagtrip/pages/subscription/subscription_cancel_page.dart';
import 'package:bagtrip/pages/subscription/subscription_success_page.dart';
import 'package:bagtrip/pages/trip_home_page.dart';
import 'package:bagtrip/pages/trip_shares_page.dart';
import 'package:bagtrip/pages/trips_list_page.dart';
import 'package:flutter/material.dart';
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
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: PersonalizationPage());
}

// ---------------------------------------------------------------------------
// Branch 0 — Planifier
// ---------------------------------------------------------------------------

@TypedGoRoute<PlanifierRoute>(
  path: '/explorer',
  routes: [
    TypedGoRoute<PlanifierManualRoute>(
      path: 'manual',
      routes: [
        TypedGoRoute<PlanifierManualTransportRoute>(
          path: 'transport',
          routes: [
            TypedGoRoute<PlanifierManualOtherTransportRoute>(path: 'other'),
          ],
        ),
        TypedGoRoute<PlanifierManualFlightSearchRoute>(path: 'flight-search'),
      ],
    ),
    TypedGoRoute<CreateTripAiRoute>(path: 'create-trip-ai'),
  ],
)
class PlanifierRoute extends GoRouteData with $PlanifierRoute {
  const PlanifierRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: PlanifierPage());
}

class PlanifierManualRoute extends GoRouteData with $PlanifierManualRoute {
  const PlanifierManualRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PlanifierManualPage(),
      );
}

class PlanifierManualTransportRoute extends GoRouteData
    with $PlanifierManualTransportRoute {
  const PlanifierManualTransportRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PlanifierManualTransportPage(),
      );
}

class PlanifierManualOtherTransportRoute extends GoRouteData
    with $PlanifierManualOtherTransportRoute {
  const PlanifierManualOtherTransportRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PlanifierManualOtherTransportPage(),
      );
}

class PlanifierManualFlightSearchRoute extends GoRouteData
    with $PlanifierManualFlightSearchRoute {
  const PlanifierManualFlightSearchRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PlanifierManualFlightPage(),
      );
}

class CreateTripAiRoute extends GoRouteData with $CreateTripAiRoute {
  const CreateTripAiRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const CreateTripAiFlowPage(),
      );
}

// ---------------------------------------------------------------------------
// Branch 1 — Trips
// ---------------------------------------------------------------------------

@TypedGoRoute<TripsRoute>(
  path: '/trips',
  routes: [
    TypedGoRoute<TripHomeRoute>(
      path: ':tripId',
      routes: [
        TypedGoRoute<AccommodationsRoute>(path: 'accommodations'),
        TypedGoRoute<BaggageRoute>(path: 'baggage'),
        TypedGoRoute<ActivitiesRoute>(path: 'activities'),
        TypedGoRoute<BudgetRoute>(path: 'budget'),
        TypedGoRoute<SharesRoute>(path: 'shares'),
        TypedGoRoute<FeedbackRoute>(path: 'feedback'),
      ],
    ),
  ],
)
class TripsRoute extends GoRouteData with $TripsRoute {
  const TripsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: TripsListPage());
}

class TripHomeRoute extends GoRouteData with $TripHomeRoute {
  const TripHomeRoute({required this.tripId});

  final String tripId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: TripHomePage(tripId: tripId),
      );
}

class AccommodationsRoute extends GoRouteData with $AccommodationsRoute {
  const AccommodationsRoute({
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
        child: AccommodationsPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
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
        child: BaggagePage(
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
  });

  final String tripId;
  final String role;
  final bool isCompleted;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: ActivitiesPage(
          tripId: tripId,
          role: role,
          isCompleted: isCompleted,
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

class SharesRoute extends GoRouteData with $SharesRoute {
  const SharesRoute({required this.tripId, this.role = 'OWNER'});

  final String tripId;
  final String role;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: TripSharesPage(tripId: tripId, role: role),
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

// ---------------------------------------------------------------------------
// Branch 2 — Activity
// ---------------------------------------------------------------------------

@TypedGoRoute<ActivityRoute>(path: '/activity')
class ActivityRoute extends GoRouteData with $ActivityRoute {
  const ActivityRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: ActivityPage());
}

// ---------------------------------------------------------------------------
// Branch 3 — Profile
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
      return const NoTransitionPage(child: TripsListPage());
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
      return const NoTransitionPage(child: TripsListPage());
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
  const PaymentSuccessRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSlideTransitionPage<void>(
        state: state,
        child: const PaymentSuccessPage(),
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
    _ => TripHomeRoute(tripId: tripId),
  };
}
