import 'package:bagtrip/flightResultDetails/view/flight_result_details_page.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder:
              (context, state) => const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          pageBuilder:
              (context, state) => const NoTransitionPage(child: MapPage()),
        ),
        GoRoute(
          path: '/budget',
          name: 'budget',
          pageBuilder:
              (context, state) => const NoTransitionPage(child: BudgetPage()),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder:
              (context, state) => const NoTransitionPage(child: ProfilePage()),
        ),
      ],
    ),
    GoRoute(
      path: '/flight-search-result',
      name: 'flight-search-result',
      pageBuilder: (context, state) {
        final args = state.extra as FlightSearchArguments?;
        if (args == null) {
          // If no arguments, redirect to home or show error
          // For now, we can redirect or just provide dummy args to prevent crash during dev
          // Ideally, we should redirect.
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(child: FlightSearchResultPage(arguments: args));
      },
    ),
    GoRoute(
      path: FlightResultDetailsPage.routePath,
      name: 'flight-result-details',
      pageBuilder: (context, state) {
        final flight = state.extra as Flight?;
        if (flight == null) {
          // Fallback or error handling
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(child: FlightResultDetailsPage(flight: flight));
      },
    ),
  ],
);
