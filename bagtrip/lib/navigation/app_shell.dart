import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/components/offline_banner.dart';

/// Tab order must match [StatefulShellRoute] branches: home, activity, profile.
const List<NavigationTab> _shellTabOrder = [
  NavigationTab.home,
  NavigationTab.activity,
  NavigationTab.profile,
];

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final activeTab = _shellTabOrder[currentIndex];

    final tabBar = BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        int badgeCount = 0;
        if (notifState is UnreadCountLoaded) {
          badgeCount = notifState.count;
        } else if (notifState is NotificationsLoaded) {
          badgeCount = notifState.unreadCount;
        }
        return BottomTabBar(
          activeTab: activeTab,
          activityBadgeCount: badgeCount,
          onTabChanged: (tab) {
            final index = _shellTabOrder.indexOf(tab);
            if (index >= 0 && index != currentIndex) {
              navigationShell.goBranch(index);
            }
          },
        );
      },
    );

    if (AdaptivePlatform.isIOS) {
      return CupertinoPageScaffold(
        child: Stack(
          children: [
            Column(
              children: [
                const OfflineBanner(),
                Expanded(child: navigationShell),
              ],
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: tabBar),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: tabBar,
    );
  }
}
