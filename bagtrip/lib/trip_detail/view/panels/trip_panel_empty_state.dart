import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/helpers/trip_departure_countdown.dart';
import 'package:flutter/material.dart';

/// Shared empty state for trip-detail tabs (flights, activities, hotels, shares).
class TripPanelEmptyState extends StatelessWidget {
  const TripPanelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.ctaLabel,
    this.tripStartDate,
    required this.canEdit,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String ctaLabel;
  final DateTime? tripStartDate;
  final bool canEdit;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final countdown = TripDepartureCountdown.fromStartDate(tripStartDate);
    final showCta = canEdit && onCta != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyStateIcon(icon: icon),
            const SizedBox(height: AppSpacing.space24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: ColorName.primaryDark,
              ),
            ),
            if (countdown != null && canEdit) ...[
              const SizedBox(height: AppSpacing.space12),
              _CountdownLine(countdown: countdown, onTap: onCta),
            ],
            if (showCta) ...[
              SizedBox(
                height: countdown != null && canEdit
                    ? AppSpacing.space32
                    : AppSpacing.space24,
              ),
              ItemFormPrimaryButton(
                label: ctaLabel,
                icon: Icons.add_rounded,
                onPressed: onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: ColorName.secondaryLight,
        borderRadius: AppRadius.large16,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 48, color: ColorName.secondary),
    );
  }
}

class _CountdownLine extends StatelessWidget {
  const _CountdownLine({required this.countdown, this.onTap});

  final TripDepartureCountdown countdown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final full = countdown.lineLabel(l10n);
    final highlight = countdown.highlightLabel(l10n);
    final start = full.indexOf(highlight);
    final hasHighlight = start >= 0;

    final text = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: ColorName.primaryDark,
        ),
        children: hasHighlight
            ? [
                TextSpan(text: full.substring(0, start)),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ColorName.secondary,
                  ),
                ),
                TextSpan(text: full.substring(start + highlight.length)),
              ]
            : [TextSpan(text: full)],
      ),
      textAlign: TextAlign.center,
    );

    if (onTap == null) return text;

    return Semantics(
      button: true,
      label: full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium8,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space4,
          ),
          child: text,
        ),
      ),
    );
  }
}
