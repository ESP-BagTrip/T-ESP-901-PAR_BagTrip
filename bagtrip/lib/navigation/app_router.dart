import 'package:bagtrip/chat/bloc/chat_bloc.dart';
import 'package:bagtrip/flightResultDetails/view/flight_result_details_page.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/navigation/page_transitions.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/chat_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/onboarding_page.dart';
import 'package:bagtrip/pages/personalization_page.dart';
import 'package:bagtrip/pages/planifier_manual_page.dart';
import 'package:bagtrip/pages/planifier_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/splash_page.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              path: '/planifier',
              name: 'planifier',
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: PlanifierPage()),
              routes: [
                GoRoute(
                  path: 'manual',
                  name: 'planifierManual',
                  pageBuilder:
                      (context, state) => buildSlideTransitionPage<void>(
                        state: state,
                        child: const PlanifierManualPage(),
                      ),
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
          return const NoTransitionPage(child: PlanifierPage());
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
          return const NoTransitionPage(child: PlanifierPage());
        }
        return buildSlideTransitionPage<void>(
          state: state,
          child: FlightResultDetailsPage(flight: flight),
        );
      },
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      pageBuilder: (context, state) {
        final tripId = state.uri.queryParameters['tripId'];
        final conversationId = state.uri.queryParameters['conversationId'];

        if (tripId == null || conversationId == null) {
          return const NoTransitionPage(child: PlanifierPage());
        }

        return NoTransitionPage(
          child: BlocProvider(
            create: (context) => ChatBloc(),
            child: ChatPage(tripId: tripId, conversationId: conversationId),
          ),
        );
      },
    ),
  ],
);
