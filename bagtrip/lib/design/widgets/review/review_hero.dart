import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Dark hero used by the wizard review step and by the trip-detail editor.
///
/// All edit affordances are opt-in via nullable callbacks:
/// * [onEditDates] — tap on the city/subtitle block or the budget opens the
///   range picker
/// * [onBack] / [onClose] — circular nav buttons at the top
/// * [onOverflow] — additional "…" button for the editor's menu
///
/// [subtitle] is shown under [city] (e.g. dates and duration: "16 mai 2026 -
/// 17 mai 2026 • 1 jour"). [trailing] is an optional slot on the hero row
/// (e.g. completion ring). [statusBadge] surfaces in the upper-right corner
/// (e.g. "READ-ONLY").
class ReviewHero extends StatelessWidget {
  const ReviewHero({
    super.key,
    required this.city,
    this.subtitle = '',
    required this.budgetLabel,
    this.coverImageUrl,
    this.onEditDates,
    this.onBack,
    this.onClose,
    this.onOverflow,
    this.trailing,
    this.statusBadge,
  });

  final String city;
  final String subtitle;
  final String budgetLabel;

  /// Optional cover image rendered behind the metadata, with a gradient
  /// overlay for legibility. When null, the hero falls back to the solid
  /// `primaryDark` background.
  final String? coverImageUrl;

  final VoidCallback? onEditDates;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onOverflow;

  /// Slot rendered next to the metadata column, under the nav row.
  /// Typical usage: completion ring in edit mode.
  final Widget? trailing;

  /// Pill badge rendered in the top-right corner (above the nav row).
  /// Used by the editor to surface read-only / completed status.
  final Widget? statusBadge;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final navButtons = <Widget>[
      if (onBack != null) ...[
        HeroNavButton(icon: Icons.arrow_back_rounded, onPressed: onBack!),
        const SizedBox(width: AppSpacing.space8),
      ],
      if (onClose != null) ...[
        HeroNavButton(icon: Icons.close_rounded, onPressed: onClose!),
        const SizedBox(width: AppSpacing.space8),
      ],
      if (onOverflow != null)
        HeroNavButton(icon: Icons.more_horiz_rounded, onPressed: onOverflow!),
    ];

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          city,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 24,
            color: ColorName.surface,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              color: ColorName.surface,
            ),
          ),
        ],
      ],
    );

    final budgetColumn = budgetLabel.isNotEmpty
        ? InkWell(
            onTap: onEditDates,
            child: Text(
              budgetLabel,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: ColorName.surface,
              ),
            ),
          )
        : null;

    final hasImage = coverImageUrl != null && coverImageUrl!.isNotEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.primaryDark),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (hasImage)
            Positioned.fill(child: OptimizedImage.tripCover(coverImageUrl!)),
          if (hasImage)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA0D1F35), Color(0xDD0D1F35)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space16,
                        AppSpacing.space8,
                        AppSpacing.space16,
                        AppSpacing.space8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: navButtons,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space24,
                        AppSpacing.space24,
                        AppSpacing.space24,
                        AppSpacing.space32,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: onEditDates != null
                                ? InkWell(onTap: onEditDates, child: titleBlock)
                                : titleBlock,
                          ),
                          if (budgetColumn != null) ...[
                            const SizedBox(width: AppSpacing.space12),
                            budgetColumn,
                          ],
                          if (trailing != null) ...[
                            const SizedBox(width: AppSpacing.space12),
                            trailing!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (statusBadge != null)
                  Positioned(
                    top: AppSpacing.space12,
                    right: AppSpacing.space16,
                    child: statusBadge!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
