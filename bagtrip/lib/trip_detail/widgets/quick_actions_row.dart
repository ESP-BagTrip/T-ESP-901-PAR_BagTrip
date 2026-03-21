import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class QuickActionsRow extends StatelessWidget {
  final Trip trip;
  final String tripId;
  final bool isViewer;
  final bool isCompleted;
  final VoidCallback? onReturnFromAction;

  const QuickActionsRow({
    super.key,
    required this.trip,
    required this.tripId,
    required this.isViewer,
    required this.isCompleted,
    this.onReturnFromAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space24,
        vertical: AppSpacing.space8,
      ),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space12),
          itemBuilder: (_, i) => StaggeredFadeIn(
            index: i,
            child: _QuickActionChip(
              icon: actions[i].icon,
              label: actions[i].label,
              onTap: actions[i].onTap,
            ),
          ),
        ),
      ),
    );
  }

  List<QuickActionItem> _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isViewer) {
      return [
        QuickActionItem(
          icon: Icons.flight_rounded,
          label: l10n.tripDetailQuickFlights,
          onTap: () {
            AppHaptics.light();
            TransportsRoute(
              tripId: tripId,
              role: 'VIEWER',
              isCompleted: trip.status == TripStatus.completed,
            ).push(context);
          },
        ),
        QuickActionItem(
          icon: Icons.hiking_rounded,
          label: l10n.tripDetailQuickActivities,
          onTap: () {
            AppHaptics.light();
            ActivitiesRoute(
              tripId: tripId,
              role: 'VIEWER',
              isCompleted: trip.status == TripStatus.completed,
            ).push(context);
          },
        ),
      ];
    }

    return switch (trip.status) {
      TripStatus.draft || TripStatus.planned => [
        QuickActionItem(
          icon: Icons.flight_rounded,
          label: l10n.tripDetailQuickAddFlight,
          onTap: () async {
            AppHaptics.light();
            await TransportsRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
        QuickActionItem(
          icon: Icons.hotel_rounded,
          label: l10n.tripDetailQuickAddHotel,
          onTap: () async {
            AppHaptics.light();
            await AccommodationsRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
              tripStartDate: trip.startDate?.toIso8601String(),
              tripEndDate: trip.endDate?.toIso8601String(),
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
        QuickActionItem(
          icon: Icons.hiking_rounded,
          label: l10n.tripDetailQuickAddActivity,
          onTap: () async {
            AppHaptics.light();
            await ActivitiesRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
      ],
      TripStatus.ongoing => [
        QuickActionItem(
          icon: Icons.wallet_rounded,
          label: l10n.tripDetailQuickExpense,
          onTap: () async {
            AppHaptics.light();
            await BudgetRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
        QuickActionItem(
          icon: Icons.hiking_rounded,
          label: l10n.tripDetailQuickActivities,
          onTap: () async {
            AppHaptics.light();
            await ActivitiesRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
        QuickActionItem(
          icon: Icons.luggage_rounded,
          label: l10n.tripDetailQuickBaggage,
          onTap: () async {
            AppHaptics.light();
            await BaggageRoute(
              tripId: tripId,
              role: trip.role ?? 'OWNER',
            ).push(context);
            if (context.mounted) onReturnFromAction?.call();
          },
        ),
      ],
      TripStatus.completed => [
        QuickActionItem(
          icon: Icons.auto_awesome,
          label: l10n.postTripSouvenirsTitle,
          onTap: () {
            AppHaptics.light();
            PostTripRoute(tripId: tripId).push(context);
          },
        ),
        QuickActionItem(
          icon: Icons.rate_review_outlined,
          label: l10n.tripDetailQuickMemories,
          onTap: () {
            AppHaptics.light();
            FeedbackRoute(tripId: tripId).push(context);
          },
        ),
      ],
    };
  }
}

class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppAnimations.pressFeedback,
        curve: AppAnimations.standardCurve,
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                offset: const Offset(0, 1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: ColorName.primary, size: 24),
              const SizedBox(height: AppSpacing.space4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  color: ColorName.textMutedLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
