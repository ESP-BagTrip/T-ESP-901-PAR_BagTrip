import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';

class BottomTabBar extends StatelessWidget {
  final NavigationTab activeTab;
  final ValueChanged<NavigationTab> onTabChanged;

  const BottomTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  Color _getTabColor(NavigationTab tab, bool isActive) {
    return isActive ? ColorName.secondary : AppColors.hint;
  }

  Widget _buildTabItem(
    BuildContext context,
    NavigationTab tab,
    String label,
    IconData icon,
  ) {
    final isActive = activeTab == tab;
    final color = _getTabColor(tab, isActive);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
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
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTrueDark.withValues(alpha: 0.08),
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
                NavigationTab.planifier,
                AppLocalizations.of(context)!.tabNew,
                Icons.add_circle_outline,
              ),
              _buildTabItem(
                context,
                NavigationTab.trips,
                AppLocalizations.of(context)!.tabTrips,
                Icons.luggage_outlined,
              ),
              _buildTabItem(
                context,
                NavigationTab.profile,
                AppLocalizations.of(context)!.tabProfile,
                Icons.person_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
