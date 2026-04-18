import 'dart:ui';

import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Cinematic, full-bleed hero placed at the top of the review page.
///
/// Renders a real cover image (destination photo or country fallback) with
/// a rich dark gradient overlay for text legibility. Metadata floats in a
/// glassmorphic pill so the photo stays the protagonist.
class ReviewCinematicHero extends StatelessWidget {
  const ReviewCinematicHero({
    super.key,
    required this.city,
    required this.country,
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
    required this.coverImageUrl,
    this.onEditDates,
    this.onBack,
    this.onClose,
  });

  final String city;
  final String country;
  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;

  /// Best-effort cover image URL. Never empty: caller composes from the
  /// AI destination or the continent fallback.
  final String coverImageUrl;

  final VoidCallback? onEditDates;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topPadding + 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverImage(url: coverImageUrl),
          const _BottomGradient(),
          const _TopScrim(),
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.space12,
                  left: AppSpacing.space16,
                  right: AppSpacing.space16,
                  child: Row(
                    children: [
                      if (onBack != null)
                        _GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: onBack!,
                        ),
                      const Spacer(),
                      if (onClose != null)
                        _GlassIconButton(
                          icon: Icons.close_rounded,
                          onPressed: onClose!,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.space24,
                  right: AppSpacing.space24,
                  bottom: AppSpacing.space24,
                  child: _HeroMetadata(
                    city: city,
                    country: country,
                    dateRangeLabel: dateRangeLabel,
                    durationLabel: durationLabel,
                    travelersLabel: travelersLabel,
                    onEditDates: onEditDates,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cover image + overlays
// -----------------------------------------------------------------------------

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return OptimizedImage.tripCover(
      url,
      errorWidget: const _GradientPlaceholder(),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.35, 0.7, 1.0],
          colors: [
            Colors.transparent,
            Color(0x33000000),
            Color(0xAA000000),
            Color(0xF0000000),
          ],
        ),
      ),
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x66000000), Colors.transparent],
          ),
        ),
        child: SizedBox(height: 140, width: double.infinity),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E2135), ColorName.primaryDark],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Top chrome (back / close) with glass blur backdrop
// -----------------------------------------------------------------------------

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Metadata (country + city + glassmorphic dates pill)
// -----------------------------------------------------------------------------

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({
    required this.city,
    required this.country,
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
    required this.onEditDates,
  });

  final String city;
  final String country;
  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;
  final VoidCallback? onEditDates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (country.isNotEmpty)
          Text(
            country.toUpperCase(),
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.2,
              color: Colors.white.withValues(alpha: 0.8),
              shadows: const [Shadow(color: Color(0x66000000), blurRadius: 8)],
            ),
          ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          city,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 56,
            height: 0.95,
            fontWeight: FontWeight.w400,
            letterSpacing: -1.5,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 16)],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        _GlassMetadataPill(
          dateRangeLabel: dateRangeLabel,
          durationLabel: durationLabel,
          travelersLabel: travelersLabel,
          onEditDates: onEditDates,
        ),
      ],
    );
  }
}

class _GlassMetadataPill extends StatelessWidget {
  const _GlassMetadataPill({
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
    required this.onEditDates,
  });

  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;
  final VoidCallback? onEditDates;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.space8),
          Flexible(
            child: Text(
              dateRangeLabel,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          _Dot(),
          const SizedBox(width: AppSpacing.space12),
          Text(
            durationLabel,
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          _Dot(),
          const SizedBox(width: AppSpacing.space12),
          Flexible(
            child: Text(
              travelersLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          if (onEditDates != null) ...[
            const SizedBox(width: AppSpacing.space8),
            Icon(
              Icons.edit_outlined,
              size: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ],
      ),
    );

    final pill = ClipRRect(
      borderRadius: AppRadius.pill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: AppRadius.pill,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.5,
            ),
          ),
          child: content,
        ),
      ),
    );

    if (onEditDates == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEditDates,
        borderRadius: AppRadius.pill,
        child: pill,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}
