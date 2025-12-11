import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/app_shell.dart';
import 'package:bagtrip/pages/home_page.dart';
import 'package:bagtrip/pages/map_page.dart';
import 'package:bagtrip/pages/budget_page.dart';
import 'package:bagtrip/pages/profile_page.dart';

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
  ],
);
