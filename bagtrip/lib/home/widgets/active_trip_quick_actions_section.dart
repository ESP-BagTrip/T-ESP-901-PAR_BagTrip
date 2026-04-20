import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Unified list card + standalone end-trip card for active home (no grid / gradients).
class ActiveTripQuickActionsSection extends StatelessWidget {
  const ActiveTripQuickActionsSection({
    super.key,
    required this.navigateEnabled,
    this.onNavigate,
    required this.onExpense,
    required this.onPhoto,
    required this.nextDayEnabled,
    this.onNextDay,
    required this.onEndTrip,
    required this.destinationLabel,
  });

  final bool navigateEnabled;
  final VoidCallback? onNavigate;
  final VoidCallback onExpense;
  final VoidCallback onPhoto;
  final bool nextDayEnabled;
  final VoidCallback? onNextDay;
  final VoidCallback onEndTrip;
  final String destinationLabel;

  static const Color _semanticBlue = Color(0xFF007AFF);
  static const Color _semanticTeal = Color(0xFF1ABC9C);
  static const Color _semanticAmber = Color(0xFFE5982D);
  static const Color _endTripRose = Color(0xFFB03C50);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _surfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickActionRow(
                icon: Icons.navigation_outlined,
                iconColor: _semanticBlue,
                title: l10n.qaNavigate,
                subtitle: l10n.activeTripQuickActionNavigateSubtitle,
                enabled: navigateEnabled,
                onTap: onNavigate,
                showDivider: true,
              ),
              _QuickActionRow(
                icon: Icons.receipt_long_outlined,
                iconColor: _semanticTeal,
                title: l10n.qaExpense,
                subtitle: l10n.activeTripQuickActionExpenseSubtitle,
                enabled: true,
                onTap: onExpense,
                showDivider: true,
              ),
              _QuickActionRow(
                icon: Icons.photo_camera_outlined,
                iconColor: _semanticAmber,
                title: l10n.activeTripQuickActionPhotoTitle,
                subtitle: l10n.activeTripQuickActionPhotoSubtitle,
                enabled: true,
                onTap: onPhoto,
                showDivider: true,
              ),
              _QuickActionRow(
                icon: Icons.star_rounded,
                iconColor: _semanticBlue,
                title: l10n.activeTripQuickActionNextDayTitle,
                subtitle: l10n.activeTripQuickActionNextDaySubtitle,
                enabled: nextDayEnabled,
                onTap: onNextDay,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        _surfaceCard(
          tinted: true,

          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                onEndTrip();
              },
              borderRadius: AppRadius.large24,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    _activeTripActionIconTile(
                      icon: Icons.logout_rounded,
                      color: _endTripRose,
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.activeTripEndTripCardTitle,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _endTripRose,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            l10n.activeTripEndTripCardSubtitle(
                              destinationLabel,
                            ),
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w300,
                              color: _endTripRose.withValues(alpha: 0.92),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: _endTripRose.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _surfaceCard({
    required Widget child,
    bool tinted = false,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? ColorName.surface,
        borderRadius: AppRadius.large24,
        border: Border.all(
          color:
              borderColor ??
              (tinted
                  ? _endTripRose.withValues(alpha: 0.18)
                  : ColorName.primarySoftLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
    required this.showDivider,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && onTap != null
                ? () {
                    AppHaptics.light();
                    onTap!();
                  }
                : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    _activeTripActionIconTile(icon: icon, color: iconColor),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w300,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: _kActiveTripQuickActionsDivider,
          ),
      ],
    );
  }
}

const Color _kActiveTripQuickActionsDivider = Color(0xFFE8EAED);

Widget _activeTripActionIconTile({
  required IconData icon,
  required Color color,
}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.large16,
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color, size: 22),
  );
}
