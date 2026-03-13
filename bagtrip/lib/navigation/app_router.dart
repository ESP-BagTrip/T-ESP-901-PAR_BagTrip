import 'package:bagtrip/flightResultDetails/view/flight_result_details_page.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/navigation/page_transitions.dart';
import 'package:bagtrip/pages/accommodations_page.dart';
import 'package:bagtrip/pages/baggage_page.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/onboarding_page.dart';
import 'package:bagtrip/pages/personalization_page.dart';
import 'package:bagtrip/pages/create_trip_ai_flow_page.dart';
import 'package:bagtrip/pages/planifier_manual_flight_page.dart';
import 'package:bagtrip/pages/planifier_manual_page.dart';
import 'package:bagtrip/pages/planifier_manual_other_transport_page.dart';
import 'package:bagtrip/pages/planifier_manual_transport_page.dart';
import 'package:bagtrip/pages/planifier_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/splash_page.dart';
import 'package:bagtrip/pages/trip_home_page.dart';
import 'package:bagtrip/pages/trips_list_page.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.uri.path;

    // Let the splash screen handle auth check on startup.
    if (path == '/') {
      return null;
    }

    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    final isLoginPage = path == '/login';
    final isOnboardingPage = path == '/onboarding';

    if (!isAuthenticated && !isLoginPage && !isOnboardingPage) {
      return '/login';
    }

    if (isAuthenticated && isLoginPage) {
      return null;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder:
          (context, state) => const NoTransitionPage(child: SplashPage()),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder:
          (context, state) => const NoTransitionPage(child: LoginPage()),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder:
          (context, state) => const NoTransitionPage(child: OnboardingPage()),
    ),
    GoRoute(
      path: '/personalization',
      name: 'personalization',
      pageBuilder:
          (context, state) =>
              const NoTransitionPage(child: PersonalizationPage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              name: 'map',
              pageBuilder:
                  (context, state) => const NoTransitionPage(child: MapPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/budget',
              name: 'budget',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: BudgetPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trips',
              name: 'trips',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: TripsListPage()),
              routes: [
                GoRoute(
                  path: 'planifier',
                  name: 'planifier',
                  pageBuilder:
                      (context, state) => buildSlideTransitionPage<void>(
                        state: state,
                        child: const PlanifierPage(),
                      ),
                  routes: [
                    GoRoute(
                      path: 'manual',
                      name: 'planifierManual',
                      pageBuilder:
                          (context, state) => buildSlideTransitionPage<void>(
                            state: state,
                            child: const PlanifierManualPage(),
                          ),
                      routes: [
                        GoRoute(
                          path: 'transport',
                          name: 'planifierManualTransport',
                          pageBuilder:
                              (context, state) =>
                                  buildSlideTransitionPage<void>(
                                    state: state,
                                    child: const PlanifierManualTransportPage(),
                                  ),
                          routes: [
                            GoRoute(
                              path: 'other',
                              name: 'planifierManualOtherTransport',
                              pageBuilder:
                                  (
                                    context,
                                    state,
                                  ) => buildSlideTransitionPage<void>(
                                    state: state,
                                    child:
                                        const PlanifierManualOtherTransportPage(),
                                  ),
                            ),
                          ],
                        ),
                        GoRoute(
                          path: 'flight-search',
                          name: 'planifierManualFlightSearch',
                          pageBuilder:
                              (context, state) =>
                                  buildSlideTransitionPage<void>(
                                    state: state,
                                    child: const PlanifierManualFlightPage(),
                                  ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'create-trip-ai',
                      name: 'createTripAi',
                      pageBuilder:
                          (context, state) => buildSlideTransitionPage<void>(
                            state: state,
                            child: const CreateTripAiFlowPage(),
                          ),
                    ),
                  ],
                ),
                GoRoute(
                  path: ':tripId',
                  name: 'tripHome',
                  pageBuilder: (context, state) {
                    final tripId = state.pathParameters['tripId']!;
                    return buildSlideTransitionPage<void>(
                      state: state,
                      child: TripHomePage(tripId: tripId),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'accommodations',
                      name: 'accommodations',
                      pageBuilder: (context, state) {
                        final tripId = state.pathParameters['tripId']!;
                        return buildSlideTransitionPage<void>(
                          state: state,
                          child: AccommodationsPage(tripId: tripId),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'baggage',
                      name: 'baggage',
                      pageBuilder: (context, state) {
                        final tripId = state.pathParameters['tripId']!;
                        return buildSlideTransitionPage<void>(
                          state: state,
                          child: BaggagePage(tripId: tripId),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: ProfilePage()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/flight-search-result',
      name: 'flight-search-result',
      pageBuilder: (context, state) {
        final args = state.extra as FlightSearchArguments?;
        if (args == null) {
          return const NoTransitionPage(child: TripsListPage());
        }
        return buildSlideTransitionPage<void>(
          state: state,
          child: FlightSearchResultPage(arguments: args),
        );
      },
    ),
    GoRoute(
      path: FlightResultDetailsPage.routePath,
      name: 'flight-result-details',
      pageBuilder: (context, state) {
        final flight = state.extra as Flight?;
        if (flight == null) {
          return const NoTransitionPage(child: TripsListPage());
        }
        return buildSlideTransitionPage<void>(
          state: state,
          child: FlightResultDetailsPage(flight: flight),
        );
      },
    ),
  ],
);
