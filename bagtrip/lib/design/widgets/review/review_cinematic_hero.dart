import 'dart:ui';

import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Cinematic, full-bleed hero at the top of the review.
///
/// Read-only by design: no edit affordances. The photo is the statement,
/// the type is the overture, the metadata pill whispers the context.
class ReviewCinematicHero extends StatelessWidget {
  const ReviewCinematicHero({
    super.key,
    required this.city,
    required this.country,
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
    required this.coverImageUrl,
    this.onBack,
    this.onClose,
  });

  final String city;
  final String country;
  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;

  /// Best-effort cover image URL. Never empty — caller composes from the
  /// AI destination or the continent fallback.
  final String coverImageUrl;

  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topPadding + 480,
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
                  bottom: AppSpacing.space32,
                  child: _HeroMetadata(
                    city: city,
                    country: country,
                    dateRangeLabel: dateRangeLabel,
                    durationLabel: durationLabel,
                    travelersLabel: travelersLabel,
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
// Cover + overlays
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
          stops: [0.0, 0.4, 0.75, 1.0],
          colors: [
            Colors.transparent,
            Color(0x22000000),
            Color(0x99000000),
            Color(0xEE000000),
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
            colors: [Color(0x55000000), Colors.transparent],
          ),
        ),
        child: SizedBox(height: 130, width: double.infinity),
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
// Chrome
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
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
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
// Metadata block: country eyebrow, city, thin rule, dates · duration · travelers
// -----------------------------------------------------------------------------

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({
    required this.city,
    required this.country,
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
  });

  final String city;
  final String country;
  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;

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
              letterSpacing: 4,
              color: Colors.white.withValues(alpha: 0.78),
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
            fontSize: 60,
            height: 0.95,
            fontWeight: FontWeight.w400,
            letterSpacing: -2,
            color: Colors.white,
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 18)],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        Container(
          width: 32,
          height: 1,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.space16),
        _Whisper(
          dateRangeLabel: dateRangeLabel,
          durationLabel: durationLabel,
          travelersLabel: travelersLabel,
        ),
      ],
    );
  }
}

class _Whisper extends StatelessWidget {
  const _Whisper({
    required this.dateRangeLabel,
    required this.durationLabel,
    required this.travelersLabel,
  });

  final String dateRangeLabel;
  final String durationLabel;
  final String travelersLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            dateRangeLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
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
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.82),
            shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        _Dot(),
        const SizedBox(width: AppSpacing.space12),
        Flexible(
          child: Text(
            travelersLabel,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.82),
              shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)],
            ),
          ),
        ),
      ],
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
        color: Colors.white.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
