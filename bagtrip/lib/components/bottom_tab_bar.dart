import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomTabBar extends StatelessWidget {
  final NavigationTab activeTab;
  final ValueChanged<NavigationTab> onTabChanged;

  const BottomTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  static const _tabs = [
    NavigationTab.planifier,
    NavigationTab.trips,
    NavigationTab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.tabNew, l10n.tabTrips, l10n.tabProfile];
    const icons = [
      Icons.add_circle_outline,
      Icons.luggage_outlined,
      Icons.person_outlined,
    ];
    const cupertinoIcons = [
      CupertinoIcons.add_circled,
      CupertinoIcons.bag,
      CupertinoIcons.person,
    ];

    if (AdaptivePlatform.isIOS) {
      return CupertinoTabBar(
        currentIndex: _tabs.indexOf(activeTab),
        onTap: (index) => onTabChanged(_tabs[index]),
        activeColor: ColorName.secondary,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: CupertinoTheme.of(
          context,
        ).barBackgroundColor.withValues(alpha: 0.92),
        items: List.generate(
          _tabs.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(cupertinoIcons[i]),
            label: labels[i],
          ),
        ),
      );
    }

    return NavigationBar(
      selectedIndex: _tabs.indexOf(activeTab),
      onDestinationSelected: (index) => onTabChanged(_tabs[index]),
      destinations: List.generate(
        _tabs.length,
        (i) => NavigationDestination(
          icon: Icon(icons[i]),
          selectedIcon: Icon(icons[i], color: ColorName.secondary),
          label: labels[i],
        ),
      ),
    );
  }
}
