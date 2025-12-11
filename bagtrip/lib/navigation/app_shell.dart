import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/components/bottom_tab_bar.dart';

extension NavigationTabExtension on NavigationTab {
  String get path {
    switch (this) {
      case NavigationTab.home:
        return '/home';
      case NavigationTab.map:
        return '/map';
      case NavigationTab.budget:
        return '/budget';
      case NavigationTab.profile:
        return '/profile';
    }
  }

  static NavigationTab fromPath(String path) {
    return NavigationTab.values.firstWhere(
      (tab) => tab.path == path,
      orElse: () => NavigationTab.home,
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final activeTab = NavigationTabExtension.fromPath(currentLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomTabBar(
        activeTab: activeTab,
        onTabChanged: (tab) {
          // Navigation is handled by BottomTabBar's context.go() call
        },
      ),
    );
  }
}
