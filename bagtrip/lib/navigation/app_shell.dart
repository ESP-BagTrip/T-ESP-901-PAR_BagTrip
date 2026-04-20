import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
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

/// Top-level paths where the tab bar should be visible.
const _topLevelPaths = {'/home', '/activity', '/profile'};

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isTopLevel = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTopLevel();
    // Listen for route changes
    GoRouter.of(context).routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    try {
      GoRouter.of(context).routerDelegate.removeListener(_onRouteChanged);
    } catch (_) {
      // Context may be invalid during dispose
    }
    super.dispose();
  }

  void _onRouteChanged() {
    _updateTopLevel();
  }

  void _updateTopLevel() {
    final location = GoRouterState.of(context).uri.path;
    final isTopLevel = _topLevelPaths.contains(location);
    if (isTopLevel != _isTopLevel) {
      setState(() => _isTopLevel = isTopLevel);
    }
  }

  /// Full-screen active trip home: no tab bar on the Home tab only.
  bool _showTabBar(NavigationTab activeTab, HomeState homeState) {
    if (!_isTopLevel) return false;
    if (activeTab == NavigationTab.home && homeState is HomeActiveTrip) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final activeTab = _shellTabOrder[currentIndex];

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        final showTabBar = _showTabBar(activeTab, homeState);

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
                  widget.navigationShell.goBranch(index);
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
                    Expanded(child: widget.navigationShell),
                  ],
                ),
                if (showTabBar)
                  Positioned(left: 0, right: 0, bottom: 0, child: tabBar),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: widget.navigationShell),
            ],
          ),
          bottomNavigationBar: showTabBar ? tabBar : null,
        );
      },
    );
  }
}
