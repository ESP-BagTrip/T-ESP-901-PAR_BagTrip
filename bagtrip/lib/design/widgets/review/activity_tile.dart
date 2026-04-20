import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Single-line representation of an itinerary activity.
///
/// Presentation-only. Tap behavior and drag-handle visibility are opt-in via
/// [onTap] and [showDragHandle] respectively — null / false means the tile is
/// a pure read-only row (wizard review case).
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    this.onTap,
    this.showDragHandle = false,
  });

  final String title;
  final String description;
  final String category;
  final VoidCallback? onTap;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorName.primary.withValues(alpha: 0.18),
            borderRadius: AppRadius.large16,
          ),
          child: Text(_categoryEmoji(category)),
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
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorName.hint,
                  ),
                ),
              ],
            ],
          ),
        ),
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
            category.isEmpty ? 'ACT' : category.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: ColorName.secondary,
            ),
          ),
        ),
        if (showDragHandle) ...[
          const SizedBox(width: AppSpacing.space8),
          const Icon(Icons.drag_handle_rounded, color: ColorName.hint),
        ],
      ],
    );

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: const BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
      ),
      child: row,
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

  String _categoryEmoji(String raw) {
    final key = raw.toLowerCase();
    if (key.contains('culture') || key.contains('museum')) return '🏛️';
    if (key.contains('nature') || key.contains('park')) return '🌿';
    if (key.contains('food') || key.contains('restaurant')) return '🍽️';
    if (key.contains('shopping')) return '🛍️';
    return '📍';
  }
}
