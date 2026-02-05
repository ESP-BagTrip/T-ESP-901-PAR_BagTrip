import 'package:bagtrip/chat/bloc/chat_bloc.dart';
import 'package:bagtrip/flightResultDetails/view/flight_result_details_page.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/chat_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/splash_page.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.uri.path;

    // Laisser la splash gérer la vérification auth au démarrage
    if (path == '/') {
      return null;
    }

    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    final isLoginPage = path == '/login';

    if (!isAuthenticated && !isLoginPage) {
      return '/login';
    }

    if (isAuthenticated && isLoginPage) {
      return '/home';
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
    GoRoute(
      path: '/chat',
      name: 'chat',
      pageBuilder: (context, state) {
        final tripId = state.uri.queryParameters['tripId'];
        final conversationId = state.uri.queryParameters['conversationId'];

        if (tripId == null || conversationId == null) {
          // Fallback or error handling
          return const NoTransitionPage(child: HomePage());
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
