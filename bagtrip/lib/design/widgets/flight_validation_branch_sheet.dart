import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Two-branch sheet that splits "Validate this flight" into the only
/// two intents an honest user actually has: "I already booked
/// elsewhere" or "Book it through BagTrip now". Each branch sticks to
/// its own pace — the external one collects a flight number, the
/// Amadeus one delegates to the booking flow.
class FlightValidationBranchSheet extends StatelessWidget {
  const FlightValidationBranchSheet({
    super.key,
    required this.onPickExternal,
    required this.onPickAmadeus,
  });

  /// Tapped when the user already has a booking elsewhere. The caller
  /// is expected to push a small form collecting the flight number,
  /// then dispatch the validate event.
  final VoidCallback onPickExternal;

  /// Tapped when the user wants to reserve through BagTrip. The caller
  /// is expected to drive the reprice → booking-intent flow.
  final VoidCallback onPickAmadeus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cornerRadius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: AppRadius.handleBar,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              child: Text(
                l10n.flightValidateSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Padding(
              padding: AppSpacing.horizontalSpace16,
              child: _BranchCard(
                icon: Icons.confirmation_number_outlined,
                title: l10n.flightValidateExternalTitle,
                subtitle: l10n.flightValidateExternalSubtitle,
                onTap: onPickExternal,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Padding(
              padding: AppSpacing.horizontalSpace16,
              child: _BranchCard(
                icon: Icons.flight_takeoff,
                title: l10n.flightValidateAmadeusTitle,
                subtitle: l10n.flightValidateAmadeusSubtitle,
                onTap: onPickAmadeus,
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
          ],
        ),
      ),
    );
  }
}

/// Open a [FlightValidationBranchSheet] with the sheet chrome the rest
/// of the app uses (transparent barrier, top-radius).
Future<T?> showFlightValidationBranchSheet<T>({
  required BuildContext context,
  required VoidCallback onPickExternal,
  required VoidCallback onPickAmadeus,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FlightValidationBranchSheet(
      onPickExternal: onPickExternal,
      onPickAmadeus: onPickAmadeus,
    ),
  );
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// When set, paints the leading icon + a subtle border in the brand
  /// colour to mark the recommended path.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ?? AppColors.textSecondary;
    return Material(
      color: Colors.white,
      borderRadius: AppRadius.large16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace16,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: accent != null
                  ? accent!.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.medium8,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
