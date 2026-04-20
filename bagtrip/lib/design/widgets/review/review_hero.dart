import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Dark hero used by the wizard review step and by the trip-detail editor.
///
/// All edit affordances are opt-in via nullable callbacks:
/// * [onEditDates] — tap on the date/budget column opens the range picker
/// * [onBack] / [onClose] — circular nav buttons at the top
/// * [onOverflow] — additional "…" button for the editor's menu
///
/// [trailing] is an optional slot below the nav row (e.g. completion ring),
/// [statusBadge] surfaces in the upper-right corner (e.g. "READ-ONLY").
class ReviewHero extends StatelessWidget {
  const ReviewHero({
    super.key,
    required this.city,
    required this.daysLabel,
    required this.dateRangeLabel,
    required this.budgetLabel,
    this.onEditDates,
    this.onBack,
    this.onClose,
    this.onOverflow,
    this.trailing,
    this.statusBadge,
  });

  final String city;
  final String daysLabel;
  final String dateRangeLabel;
  final String budgetLabel;
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

    final metadata = InkWell(
      onTap: onEditDates,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            daysLabel.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontWeight: FontWeight.w700,
              color: ColorName.hint,
            ),
          ),
          Text(
            dateRangeLabel,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              color: ColorName.surface,
            ),
          ),
          const SizedBox(height: 2),
          if (budgetLabel.isNotEmpty)
            Text(
              budgetLabel,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: ColorName.surface,
              ),
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.primaryDark),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space4,
                    AppSpacing.space16,
                    0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: navButtons,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          city,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 24,
                            color: ColorName.surface,
                          ),
                        ),
                      ),
                      metadata,
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
    );
  }
}
