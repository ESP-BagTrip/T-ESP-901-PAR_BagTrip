import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Compact dark hero used at the top of each routed sub-page (activities,
/// transports, accommodations, baggage, budget, shares). Mirrors the
/// [ReviewHero] vocabulary (dark background, DM Serif Display title,
/// caps subtitle, circular nav buttons) without the full hero density.
///
/// Use instead of [AppBar] — wrap the page body in a `Column` with this as
/// the first child.
class SubPageHero extends StatelessWidget {
  const SubPageHero({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  /// DM Serif Display title (typically the destination city).
  final String title;

  /// Caps subtitle (e.g. "ACTIVITIES (24)").
  final String? subtitle;

  /// Defaults to [Navigator.pop] when null.
  final VoidCallback? onBack;

  /// Optional action buttons on the right (reuses [HeroNavButton] for
  /// visual consistency).
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.primaryDark),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding + AppSpacing.space4,
          left: AppSpacing.space16,
          right: AppSpacing.space16,
          bottom: AppSpacing.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HeroNavButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                ...?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 22,
                color: ColorName.surface,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(
                subtitle!.toUpperCase(),
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: ColorName.hint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
