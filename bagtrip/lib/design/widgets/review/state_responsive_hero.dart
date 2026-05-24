import 'package:bagtrip/design/subpage_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Hero bar for the routed subpages that adapts to content density.
///
/// Used for [HeroDensity.sparse] and [HeroDensity.dense]. The blank-canvas
/// state renders its own full-screen hero ([BlankCanvasHero]) instead — do
/// not mount [StateResponsiveHero] alongside it.
///
/// Variants:
/// - **sparse** — 180px tall, DM Serif 28pt title, DM Sans 12pt caps meta.
///   The hero has room to breathe so the first 1–3 items below feel
///   considered rather than sparse.
/// - **dense** — 108px tall, DM Serif 20pt title, 11pt caps meta. The
///   content list is the focus; the hero recedes.
///
/// Transitions between densities animate with an `AnimatedSize` +
/// `AnimatedDefaultTextStyle` (280ms, easeOutCubic).
class StateResponsiveHero extends StatelessWidget {
  const StateResponsiveHero({
    super.key,
    required this.title,
    required this.density,
    this.meta,
    this.badge,
    this.trailing,
    this.onBack,
  });

  /// DM Serif Display title (e.g. "Activities", or the destination city).
  final String title;

  /// Layout density band (sparse or dense).
  final HeroDensity density;

  /// Caps meta line below the title. Render `AnimatedCount` here when the
  /// count should tween on change.
  final Widget? meta;

  /// Optional status pill rendered in the top row (e.g. READ ONLY).
  final Widget? badge;

  /// Optional action buttons on the right (AI suggest, search).
  final List<Widget>? trailing;

  /// Override the default `Navigator.maybePop` back action.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isSparse = density == HeroDensity.sparse;
    final isDense = density == HeroDensity.dense;
    assert(
      isSparse || isDense,
      'StateResponsiveHero only renders for sparse or dense density. '
      'Use BlankCanvasHero for blankCanvas.',
    );
    final titleSize = isSparse ? 28.0 : 20.0;
    final metaSize = isSparse ? 12.0 : 11.0;
    final verticalPadding = isSparse ? AppSpacing.space24 : AppSpacing.space16;

    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.primaryDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          top: topPadding + AppSpacing.space4,
          left: AppSpacing.space16,
          right: AppSpacing.space16,
          bottom: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                HeroNavButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                if (badge != null) ...[
                  const SizedBox(width: AppSpacing.space12),
                  badge!,
                ],
                const Spacer(),
                ...?trailing,
              ],
            ),
            SizedBox(
              height: isSparse ? AppSpacing.space24 : AppSpacing.space12,
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: titleSize,
                color: ColorName.surface,
                height: 1.15,
              ),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (meta != null) ...[
              const SizedBox(height: AppSpacing.space4),
              DefaultTextStyle(
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: metaSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: meta!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small rounded pill rendered in the hero (READ ONLY, COMPLETED, etc.).
class HeroBadge extends StatelessWidget {
  const HeroBadge({
    super.key,
    required this.label,
    this.tone = HeroBadgeTone.neutral,
  });

  final String label;
  final HeroBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (tone) {
      case HeroBadgeTone.neutral:
        bg = Colors.white.withValues(alpha: 0.15);
        fg = Colors.white.withValues(alpha: 0.9);
      case HeroBadgeTone.success:
        bg = ColorName.secondary.withValues(alpha: 0.25);
        fg = ColorName.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: 4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: fg,
        ),
      ),
    );
  }
}

enum HeroBadgeTone { neutral, success }
