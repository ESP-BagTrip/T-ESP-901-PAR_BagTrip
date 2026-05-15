import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:flutter/material.dart';

/// Rich activity card for the trip-detail Activities tab.
///
/// Presentation-only: no inline actions — validate/delete are swipe gestures.
class ActivityPanelCard extends StatelessWidget {
  const ActivityPanelCard({
    super.key,
    required this.title,
    required this.description,
    required this.categoryLabel,
    this.timeLabel,
    this.location,
    this.validationStatus,
    this.onTap,
  });

  final String title;
  final String description;
  final String categoryLabel;
  final String? timeLabel;
  final String? location;
  final ValidationStatus? validationStatus;
  final VoidCallback? onTap;

  static const double _validatedAccentWidth = 5;

  @override
  Widget build(BuildContext context) {
    final meta = _buildMetaLine(timeLabel, location);
    final showValidatedAccent = validationStatus == ValidationStatus.validated;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.18),
              borderRadius: AppRadius.large16,
            ),
            child: Text(
              _categoryEmoji(categoryLabel),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: ColorName.primaryDark,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: ColorName.primary,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pill,
                  color: ColorName.secondary.withValues(alpha: 0.12),
                ),
                child: Text(
                  categoryLabel.isEmpty ? 'ACT' : categoryLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: ColorName.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final card = ClipRRect(
      borderRadius: AppRadius.large16,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: ColorName.surface),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showValidatedAccent)
                const ColoredBox(
                  color: ColorName.secondary,
                  child: SizedBox(width: _validatedAccentWidth),
                ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );

    final wrapped = onTap == null
        ? card
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.large16,
              onTap: onTap,
              child: card,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: wrapped,
    );
  }

  String? _buildMetaLine(String? time, String? loc) {
    final parts = <String>[
      if (time != null && time.isNotEmpty) time,
      if (loc != null && loc.isNotEmpty) loc,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String _categoryEmoji(String raw) {
    final key = raw.toLowerCase();
    if (key.contains('culture') || key.contains('museum')) return '🏛️';
    if (key.contains('nature') || key.contains('park')) return '🌿';
    if (key.contains('food') || key.contains('restaurant')) return '🍽️';
    if (key.contains('shopping') || key.contains('shop')) return '🛍️';
    if (key.contains('night')) return '🌙';
    if (key.contains('sport')) return '⚽';
    if (key.contains('relax')) return '🧘';
    if (key.contains('transport')) return '🚆';
    return '📍';
  }
}
