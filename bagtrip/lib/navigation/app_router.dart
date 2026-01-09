import 'package:bagtrip/flightResultDetails/view/flight_result_details_page.dart';
import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/flightSearchResult/models/flight_search_arguments.dart';
import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/chat_page.dart';
import 'package:bagtrip/pages/flight_booking_page.dart';
import 'package:bagtrip/pages/flight_search_result_page.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/card_input_page.dart';
import 'package:bagtrip/pages/payment_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/booking_confirmation_page.dart';
import 'package:bagtrip/payment/bloc/payment_bloc.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/chat/bloc/chat_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) async {
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    final isLoginPage = state.uri.path == '/login';

    // If not authenticated and not on login page, redirect to login
    if (!isAuthenticated && !isLoginPage) {
      return '/login';
    }

    // If authenticated and on login page, redirect to home
    if (isAuthenticated && isLoginPage) {
      return '/home';
    }

    return null; // No redirect needed
  },
  routes: [
    // Login route (outside ShellRoute, no bottom nav)
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
        final extra = state.extra;
        Flight? flight;
        String? tripId;

        if (extra is Map) {
          flight = extra['flight'] as Flight?;
          tripId = extra['tripId'] as String?;
        } else if (extra is Flight) {
          flight = extra;
        }

        if (flight == null) {
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(
          child: FlightResultDetailsPage(flight: flight, tripId: tripId),
        );
      },
    ),
    GoRoute(
      path: '/flight-booking',
      name: 'flight-booking',
      pageBuilder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        if (args == null ||
            args['tripId'] == null ||
            args['offerId'] == null ||
            args['price'] == null) {
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(
          child: FlightBookingPage(
            tripId: args['tripId'] as String,
            flightOfferId: args['offerId'] as String,
            price: (args['price'] as num).toDouble(),
            currency: args['currency'] as String? ?? 'EUR',
            intentId: args['intentId'] as String?,
          ),
        );
      },
    ),
    GoRoute(
      path: '/payment/:intentId',
      name: 'payment',
      pageBuilder: (context, state) {
        final intentId = state.pathParameters['intentId'];
        final args = state.extra as Map<String, dynamic>?;
        if (intentId == null || args == null) {
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(
          child: BlocProvider(
            create: (context) => PaymentBloc(),
            child: PaymentPage(
              intentId: intentId,
              tripId: args['tripId'] as String,
              price: (args['price'] as num).toDouble(),
              currency: args['currency'] as String? ?? 'EUR',
              flightOfferId: args['flightOfferId'] as String?,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/card-input/:intentId',
      name: 'card-input',
      pageBuilder: (context, state) {
        final intentId = state.pathParameters['intentId'];
        final args = state.extra as Map<String, dynamic>?;
        if (intentId == null || args == null) {
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(
          child: BlocProvider(
            create: (context) => PaymentBloc(),
            child: CardInputPage(
              intentId: intentId,
              tripId: args['tripId'] as String,
              price: (args['price'] as num).toDouble(),
              currency: args['currency'] as String? ?? 'EUR',
              flightOfferId: args['flightOfferId'] as String?,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/booking-confirmation/:intentId',
      name: 'booking-confirmation',
      pageBuilder: (context, state) {
        final intentId = state.pathParameters['intentId'];
        if (intentId == null) {
          return const NoTransitionPage(child: HomePage());
        }
        return NoTransitionPage(
          child: BookingConfirmationPage(intentId: intentId),
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
