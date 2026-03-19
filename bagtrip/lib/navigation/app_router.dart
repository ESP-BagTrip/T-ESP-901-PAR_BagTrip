import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.uri.path;

    // Let the splash screen handle auth check on startup.
    if (path == '/') {
      return null;
    }

    final authRepository = getIt<AuthRepository>();
    final authResult = await authRepository.isAuthenticated();
    final isAuthenticated = authResult.dataOrNull ?? false;
    final isLoginPage = path == '/login';
    final isOnboardingPage = path == '/onboarding';

    if (!isAuthenticated && !isLoginPage && !isOnboardingPage) {
      final intended = state.uri.toString();
      if (intended != '/' && intended != '/login') {
        return '/login?redirect=${Uri.encodeComponent(intended)}';
      }
      return '/login';
    }

    if (isAuthenticated && isLoginPage) {
      final redirect = state.uri.queryParameters['redirect'];
      if (redirect != null && redirect.isNotEmpty) {
        final decoded = Uri.decodeComponent(redirect);
        if (decoded != '/login' && decoded != '/') {
          return decoded;
        }
      }
      return null;
    }

    return null;
  },
  routes: [
    $splashRoute,
    $loginRoute,
    $onboardingRoute,
    $personalizationRoute,
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(routes: [$homeRoute]),
        // Branch 1: Activity
        StatefulShellBranch(routes: [$activityRoute]),
        // Branch 2: Profile
        StatefulShellBranch(routes: [$profileRoute]),
      ],
    ),
    $notificationsRoute,
    $deepLinkTripRoute,
    $flightSearchResultRoute,
    $flightResultDetailsRoute,
    $subscriptionSuccessRoute,
    $subscriptionCancelRoute,
    $paymentSuccessRoute,
    $paymentCancelRoute,
    $paymentResultRoute,
  ],
);
