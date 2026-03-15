import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/components/offline_banner.dart';

/// Tab order must match [StatefulShellRoute] branches: planifier, trips, profile.
const List<NavigationTab> _shellTabOrder = [
  NavigationTab.planifier,
  NavigationTab.trips,
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
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
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
