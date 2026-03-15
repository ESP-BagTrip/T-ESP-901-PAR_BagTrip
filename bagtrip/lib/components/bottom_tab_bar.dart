import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class BottomTabBar extends StatelessWidget {
  final NavigationTab activeTab;
  final ValueChanged<NavigationTab> onTabChanged;
  final int activityBadgeCount;

  const BottomTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.activityBadgeCount = 0,
  });

  static const _tabs = [
    NavigationTab.home,
    NavigationTab.activity,
    NavigationTab.profile,
  ];

  static const _selectedCupertinoIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.bell_fill,
    CupertinoIcons.person_fill,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.tabHome, l10n.tabActivity, l10n.tabProfile];
    const icons = [
      Icons.home_outlined,
      Icons.notifications_outlined,
      Icons.person_outlined,
    ];
    const cupertinoIcons = [
      CupertinoIcons.house,
      CupertinoIcons.bell,
      CupertinoIcons.person,
    ];

    if (AdaptivePlatform.isIOS) {
      Widget bar = Material(
        type: MaterialType.transparency,
        child: GlassBottomBar(
          tabs: List.generate(
            _tabs.length,
            (i) => GlassBottomBarTab(
              icon: cupertinoIcons[i],
              selectedIcon: _selectedCupertinoIcons[i],
              label: labels[i],
              glowColor: ColorName.secondary,
            ),
          ),
          selectedIndex: _tabs.indexOf(activeTab),
          onTabSelected: (index) => onTabChanged(_tabs[index]),
          unselectedIconColor: CupertinoColors.systemGrey,
        ),
      );

      if (activityBadgeCount > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        bar = Stack(
          clipBehavior: Clip.none,
          children: [
            bar,
            Positioned(
              left: screenWidth / 2 + 8,
              top: 14,
              child: IgnorePointer(
                child: GlassBadge(
                  count: activityBadgeCount,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      }

      return bar;
    }

    return NavigationBar(
      selectedIndex: _tabs.indexOf(activeTab),
      onDestinationSelected: (index) => onTabChanged(_tabs[index]),
      destinations: List.generate(
        _tabs.length,
        (i) => NavigationDestination(
          icon: i == 1
              ? Badge(
                  isLabelVisible: activityBadgeCount > 0,
                  label: Text(
                    activityBadgeCount > 99 ? '99+' : '$activityBadgeCount',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: Icon(icons[i]),
                )
              : Icon(icons[i]),
          selectedIcon: i == 1
              ? Badge(
                  isLabelVisible: activityBadgeCount > 0,
                  label: Text(
                    activityBadgeCount > 99 ? '99+' : '$activityBadgeCount',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: Icon(icons[i], color: ColorName.secondary),
                )
              : Icon(icons[i], color: ColorName.secondary),
          label: labels[i],
        ),
      ),
    );
  }
}
