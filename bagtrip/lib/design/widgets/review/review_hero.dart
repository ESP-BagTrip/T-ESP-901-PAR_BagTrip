import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/trip_cover_hero_overlay.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Dark hero for trip-detail and active-trip programme screens. Occupies one
/// third of the viewport height so the cover photo reads clearly; metadata sits
/// on the bottom edge.
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
///
/// [coverOverlay] selects the darkening treatment. [ReviewHeroCoverOverlay.activeTripCard]
/// matches the home active-trip card; [ReviewHeroCoverOverlay.tripDetail] keeps the
/// editor scrim.
enum ReviewHeroCoverOverlay { tripDetail, activeTripCard }

class ReviewHero extends StatelessWidget {
  const ReviewHero({
    super.key,
    required this.city,
    this.subtitle = '',
    required this.budgetLabel,
    this.coverImageUrl,
    this.coverOverlay = ReviewHeroCoverOverlay.tripDetail,
    this.onEditDates,
    this.onBack,
    this.onClose,
    this.onOverflow,
    this.onChangeCover,
    this.trailing,
    this.statusBadge,
    this.cityStyle,
    this.subtitleStyle,
  });

  final String city;
  final String subtitle;
  final String budgetLabel;

  /// Defaults to trip-detail typography (24 pt serif city, 16 pt serif subtitle).
  final TextStyle? cityStyle;
  final TextStyle? subtitleStyle;

  static const TextStyle _defaultCityStyle = TextStyle(
    fontFamily: FontFamily.dMSerifDisplay,
    fontSize: 24,
    color: ColorName.surface,
  );

  static const TextStyle _defaultSubtitleStyle = TextStyle(
    fontFamily: FontFamily.dMSerifDisplay,
    fontSize: 16,
    color: ColorName.surface,
  );

  /// Optional cover image rendered behind the metadata, with a gradient
  /// overlay for legibility. When null, the hero falls back per [coverOverlay].
  final String? coverImageUrl;
  final ReviewHeroCoverOverlay coverOverlay;

  final VoidCallback? onEditDates;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onOverflow;

  /// SMP-330 — opens the "Change cover" bottom sheet. When null, no
  /// camera button is rendered in the hero's nav row.
  final VoidCallback? onChangeCover;

  /// Slot rendered next to the metadata column, under the nav row.
  /// Typical usage: completion ring in edit mode.
  final Widget? trailing;

  /// Pill badge rendered in the top-right corner (above the nav row).
  /// Used by the editor to surface read-only / completed status.
  final Widget? statusBadge;

  static const double _viewportHeightFraction = 1 / 3;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final topPadding = MediaQuery.paddingOf(context).top;
    final heroHeight =
        MediaQuery.sizeOf(context).height * _viewportHeightFraction;
    final navButtons = <Widget>[
      if (onBack != null) ...[
        HeroNavButton(icon: Icons.arrow_back_rounded, onPressed: onBack!),
        const SizedBox(width: AppSpacing.space8),
      ],
      if (onClose != null) ...[
        HeroNavButton(icon: Icons.close_rounded, onPressed: onClose!),
        const SizedBox(width: AppSpacing.space8),
      ],
      if (onChangeCover != null) ...[
        HeroNavButton(
          icon: Icons.photo_camera_outlined,
          onPressed: onChangeCover!,
        ),
        const SizedBox(width: AppSpacing.space8),
      ],
      if (onOverflow != null)
        HeroNavButton(icon: Icons.more_horiz_rounded, onPressed: onOverflow!),
    ];

    final resolvedCityStyle = cityStyle ?? _defaultCityStyle;
    final resolvedSubtitleStyle = subtitleStyle ?? _defaultSubtitleStyle;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          city,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: resolvedCityStyle,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: resolvedSubtitleStyle,
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
    final metadataRow = Row(
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
    );

    final backgroundColor = coverOverlay == ReviewHeroCoverOverlay.tripDetail
        ? AppColors.reviewAccentSurfaceOf(brightness)
        : Colors.transparent;

    return SizedBox(
      height: heroHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ..._coverLayers(hasImage, brightness),
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Stack(
                children: [
                  Positioned(
                    top: AppSpacing.space8,
                    left: AppSpacing.space16,
                    right: AppSpacing.space16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: navButtons,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.space24,
                    right: AppSpacing.space24,
                    bottom: AppSpacing.space32,
                    child: metadataRow,
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
      ),
    );
  }

  List<Widget> _coverLayers(bool hasImage, Brightness brightness) {
    final accent = AppColors.reviewAccentSurfaceOf(brightness);
    switch (coverOverlay) {
      case ReviewHeroCoverOverlay.activeTripCard:
        return [
          if (hasImage)
            Positioned.fill(
              child: OptimizedImage.tripCover(
                coverImageUrl!,
                errorWidget: const TripCoverHeroFallback(),
              ),
            )
          else
            const Positioned.fill(child: TripCoverHeroFallback()),
          const Positioned.fill(child: TripCoverHeroScrim()),
        ];
      case ReviewHeroCoverOverlay.tripDetail:
        return [
          if (hasImage)
            Positioned.fill(child: OptimizedImage.tripCover(coverImageUrl!)),
          if (hasImage)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.67),
                      accent.withValues(alpha: 0.87),
                    ],
                  ),
                ),
              ),
            ),
        ];
    }
  }
}
