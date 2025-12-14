import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/design/tokens.dart';

class BottomTabBar extends StatelessWidget {
  final NavigationTab activeTab;
  final ValueChanged<NavigationTab> onTabChanged;

  const BottomTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  Color _getTabColor(NavigationTab tab, bool isActive) {
    return isActive ? ColorName.secondary : Colors.grey;
  }

  Widget _buildTabItem(
    BuildContext context,
    NavigationTab tab,
    String label,
    IconData icon,
    String route,
  ) {
    final isActive = activeTab == tab;
    final color = _getTabColor(tab, isActive);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTabChanged(tab);
          context.go(route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSize.iconSizeHeight24),
            const SizedBox(height: AppSpacing.space4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: AppSpacing.horizontalSpace8,
          child: Row(
            children: [
              _buildTabItem(
                context,
                NavigationTab.home,
                'Accueil',
                Icons.home_outlined,
                '/home',
              ),
              _buildTabItem(
                context,
                NavigationTab.map,
                'Carte',
                Icons.map_outlined,
                '/map',
              ),
              _buildTabItem(
                context,
                NavigationTab.budget,
                'Budget',
                Icons.wallet_outlined,
                '/budget',
              ),
              _buildTabItem(
                context,
                NavigationTab.profile,
                'Profil',
                Icons.person_outlined,
                '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
