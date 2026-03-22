import 'package:bagtrip/auth/bloc/auth_bloc.dart';
import 'package:bagtrip/auth/widgets/auth_listener.dart';
import 'package:bagtrip/booking/bloc/booking_bloc.dart';
import 'package:bagtrip/core/cache/connectivity_bloc.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/profile/bloc/user_profile_bloc.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'mock_di_setup.dart';
import 'e2e_fixtures.dart';

// ─── TestApp ────────────────────────────────────────────────────────────────

class TestApp extends StatefulWidget {
  final GoRouter router;

  const TestApp({super.key, required this.router});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  late final HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
  }

  @override
  void dispose() {
    _homeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsBloc()),
        BlocProvider(create: (_) => UserProfileBloc()),
        BlocProvider(create: (_) => BookingBloc()),
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => TripManagementBloc()),
        BlocProvider.value(value: _homeBloc),
        BlocProvider(create: (_) => NotificationBloc()),
        BlocProvider(create: (_) => ConnectivityBloc()),
      ],
      child: AuthListener(
        router: widget.router,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: widget.router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}

// ─── Router factory ─────────────────────────────────────────────────────────

GoRouter createTestRouter({String initialLocation = '/home'}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) async {
      final path = state.uri.path;
      if (path == '/') return null;

      final authRepository = getIt<AuthRepository>();
      final authResult = await authRepository.isAuthenticated();
      final isAuthenticated = authResult.dataOrNull ?? false;
      final isLoginPage = path == '/login';
      final isOnboardingPage = path == '/onboarding';

      if (!isAuthenticated && !isLoginPage && !isOnboardingPage) {
        return '/login';
      }
      if (isAuthenticated && isLoginPage) {
        return '/home';
      }
      return null;
    },
    routes: [
      $splashRoute,
      $loginRoute,
      $onboardingRoute,
      $personalizationRoute,
      // Simplified shell: bypass AppShell + LiquidGlass for tests
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(body: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [$homeRoute]),
          StatefulShellBranch(routes: [$activityRoute]),
          StatefulShellBranch(routes: [$profileRoute]),
        ],
      ),
      $notificationsRoute,
      $deepLinkTripRoute,
    ],
  );
}

// ─── pumpTestApp() ──────────────────────────────────────────────────────────

Future<MockContainer> pumpTestApp(
  WidgetTester tester, {
  String initialRoute = '/home',
  MockContainer? existingMocks,
}) async {
  final mocks = existingMocks ?? await setupTestServiceLocator();

  // Default auth stubs (authenticated user)
  stubAuthenticated(mocks);

  final router = createTestRouter(initialLocation: initialRoute);

  await tester.pumpWidget(TestApp(router: router));
  // Use explicit pump() instead of pumpAndSettle() because infinite
  // animations (shimmer, Lottie) prevent settle. Pump enough frames
  // for GoRouter redirect + BLoC async operations to complete.
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  return mocks;
}
