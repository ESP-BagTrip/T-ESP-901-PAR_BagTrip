import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/contextual_actions_helper.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  final String tripId;
  final List<QuickActionType> actions;
  final VoidCallback? onNavigateTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onTomorrowTap;

  const QuickActionsBar({
    super.key,
    required this.tripId,
    required this.actions,
    this.onNavigateTap,
    this.onExpenseTap,
    this.onWeatherTap,
    this.onPhotoTap,
    this.onTomorrowTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      child: Row(
        key: ValueKey(actions.map((a) => a.name).join(',')),
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((type) {
          final resolved = _resolve(type, l10n, context);
          return _QuickAction(
            icon: resolved.$1,
            label: resolved.$2,
            onTap: () {
              AppHaptics.light();
              resolved.$3();
            },
          );
        }).toList(),
      ),
    );
  }

  (IconData, String, VoidCallback) _resolve(
    QuickActionType type,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return switch (type) {
      QuickActionType.todaySchedule => (
        Icons.event_note_outlined,
        l10n.qaSchedule,
        () => TripHomeRoute(tripId: tripId).go(context),
      ),
      QuickActionType.weather => (
        Icons.wb_sunny_outlined,
        l10n.qaWeather,
        () => onWeatherTap?.call(),
      ),
      QuickActionType.checkOut => (
        Icons.hotel_outlined,
        l10n.qaCheckOut,
        () => AccommodationsRoute(tripId: tripId).go(context),
      ),
      QuickActionType.navigate => (
        Icons.navigation_outlined,
        l10n.qaNavigate,
        () => onNavigateTap?.call(),
      ),
      QuickActionType.expense => (
        Icons.receipt_long_outlined,
        l10n.qaExpense,
        () => onExpenseTap?.call(),
      ),
      QuickActionType.photo => (
        Icons.camera_alt_outlined,
        l10n.qaPhoto,
        () => onPhotoTap?.call(),
      ),
      QuickActionType.nextActivity => (
        Icons.skip_next_outlined,
        l10n.qaNextActivity,
        () => TripHomeRoute(tripId: tripId).go(context),
      ),
      QuickActionType.aiSuggestion => (
        Icons.auto_awesome_outlined,
        l10n.qaAiSuggestion,
        () => TripHomeRoute(tripId: tripId).go(context),
      ),
      QuickActionType.map => (
        Icons.map_outlined,
        l10n.qaMap,
        () => MapRoute(tripId: tripId).go(context),
      ),
      QuickActionType.todayExpenses => (
        Icons.receipt_outlined,
        l10n.qaTodayExpenses,
        () => TripHomeRoute(tripId: tripId).go(context),
      ),
      QuickActionType.tomorrow => (
        Icons.calendar_today_outlined,
        l10n.qaTomorrow,
        () => onTomorrowTap?.call(),
      ),
      QuickActionType.budget => (
        Icons.account_balance_wallet_outlined,
        l10n.qaBudget,
        () => TripHomeRoute(tripId: tripId).go(context),
      ),
    };
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.space56,
            height: AppSpacing.space56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ColorName.primary, ColorName.secondary],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: ColorName.surface, size: 24),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              color: ColorName.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
