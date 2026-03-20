import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  final String tripId;

  const QuickActionsBar({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final actions = [
      _QuickAction(
        icon: Icons.event_note_outlined,
        label: l10n.activeTripsActivities,
        onTap: () {
          AppHaptics.light();
          TripHomeRoute(tripId: tripId).go(context);
        },
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.activeTripsBudget,
        onTap: () {
          AppHaptics.light();
          BudgetRoute(tripId: tripId).go(context);
        },
      ),
      _QuickAction(
        icon: Icons.luggage_outlined,
        label: l10n.activeTripsBaggage,
        onTap: () {
          AppHaptics.light();
          BaggageRoute(tripId: tripId).go(context);
        },
      ),
      _QuickAction(
        icon: Icons.share_outlined,
        label: l10n.activeTripsShare,
        onTap: () {
          AppHaptics.light();
          SharesRoute(tripId: tripId).go(context);
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
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
