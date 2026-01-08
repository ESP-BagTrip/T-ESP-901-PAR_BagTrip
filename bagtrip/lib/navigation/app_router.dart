import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/profile_page.dart';
import 'package:bagtrip/pages/login_page.dart';
import 'package:bagtrip/pages/register_page.dart';
import 'package:bagtrip/logic/auth_bloc.dart';
import 'package:bagtrip/utils/router_utils.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;

      // Allow app to load
      if (authState is AuthInitial || authState is AuthLoading) return null;

      final isAuthenticated = authState is AuthAuthenticated;
      
      final isLogin = state.uri.path == '/login';
      final isRegister = state.uri.path == '/register';
      final isProfile = state.uri.path == '/profile';

      // 1. If trying to access Profile while not authenticated -> Redirect to Login
      if (isProfile && !isAuthenticated) {
        return '/login';
      }

      // 2. If authenticated and on Login/Register pages -> Redirect to Profile (or Home)
      if (isAuthenticated && (isLogin || isRegister)) {
        return '/profile';
      }

      // 3. Otherwise allow access (Home, Map, Budget are public)
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
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
    ],
  );
}
