import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/components/bottom_tab_bar.dart';

/// Tab order must match [StatefulShellRoute] branches: map, budget, planifier, profile.
const List<NavigationTab> _shellTabOrder = [
  NavigationTab.map,
  NavigationTab.budget,
  NavigationTab.planifier,
  NavigationTab.profile,
];

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final activeTab = _shellTabOrder[currentIndex];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomTabBar(
        activeTab: activeTab,
        onTabChanged: (tab) {
          final index = _shellTabOrder.indexOf(tab);
          if (index >= 0 && index != currentIndex) {
            navigationShell.goBranch(index);
          }
        },
      ),
    );
  }
}
