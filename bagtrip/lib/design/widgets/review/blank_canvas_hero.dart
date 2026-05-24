import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Signature for a breathing animation applied to the icon halo.
///
/// Each subpage passes a domain-appropriate animation:
/// - activities: subtle scale pulse (1.0 → 1.04 → 1.0).
/// - transports: boarding-pass tilt (0 → 2deg → 0).
/// - accommodations: shadow softening via opacity on the halo.
/// - baggage: rotate (0 → 3deg → 0).
/// - budget: full rotate per cycle.
/// - shares: translate apart/together.
///
/// The builder receives the icon widget and returns it wrapped in whatever
/// transform / animation is appropriate. Animations stop when
/// [MediaQuery.disableAnimations] is active — the wrapper is still invoked
/// but the animation controller stays at rest.
typedef BreathingIconBuilder =
    Widget Function(BuildContext context, Widget icon, Animation<double> t);

/// Full-screen empty state that **is** the primary interaction surface.
///
/// Replaces the passive `ElegantEmptyState` halo + text combo in subpages:
/// here the whole screen invites action. Back button in the top-left, a
/// hero icon with breathing animation (domain-specific), a large serif
/// title, a supporting subtitle, and up to two CTA pills stacked.
///
/// Not intended for panels inside the trip detail view — those keep
/// `ElegantEmptyState` (smaller surface, secondary status).
///
/// Accessibility:
/// - Respects `MediaQuery.disableAnimations` — skips both the fade-in and
///   the breathing loop when the user has reduce-motion enabled.
/// - Primary/secondary buttons are ordinary `PillCtaButton`s — no custom
///   focus semantics needed.
class BlankCanvasHero extends StatefulWidget {
  const BlankCanvasHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryLeadingIcon,
    this.secondaryLeadingIcon,
    this.onBack,
    this.breathingIconBuilder,
    this.breathingDuration = const Duration(milliseconds: 3000),
  });

  /// Icon used inside the circular halo (e.g. `Icons.event_outlined` for
  /// activities, `Icons.flight_takeoff_rounded` for transports).
  final IconData icon;

  /// DM Serif Display title — rendered at 24pt, center-aligned, capped at
  /// 2 lines. Keep it short and evocative ("Your itinerary is empty", not
  /// "There are no activities yet").
  final String title;

  /// Supporting DM Sans copy below the title. 2 lines max.
  final String subtitle;

  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryLeadingIcon;

  /// Optional secondary action (e.g. "Let AI plan a day"). Rendered as an
  /// outlined pill under the primary.
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? secondaryLeadingIcon;

  /// Override the default `Navigator.maybePop` back action.
  final VoidCallback? onBack;

  /// Custom breathing animation wrapper for the icon. Defaults to a subtle
  /// scale pulse (1.0 → 1.04 → 1.0).
  final BreathingIconBuilder? breathingIconBuilder;

  /// Breathing loop duration.
  final Duration breathingDuration;

  @override
  State<BlankCanvasHero> createState() => _BlankCanvasHeroState();
}

class _BlankCanvasHeroState extends State<BlankCanvasHero>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: widget.breathingDuration,
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disabled = MediaQuery.of(context).disableAnimations;
      if (disabled) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
        _breathingController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: ColorName.surfaceVariant),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.space8,
              left: AppSpacing.space16,
              child: HeroNavButton(
                icon: Icons.arrow_back_rounded,
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _entrance,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(_entrance),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Halo(
                          icon: widget.icon,
                          animation: _breathingController,
                          builder:
                              widget.breathingIconBuilder ?? _defaultBreathing,
                        ),
                        const SizedBox(height: AppSpacing.space24),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 26,
                            height: 1.2,
                            color: ColorName.primaryDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: ColorName.hint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space32),
                        SizedBox(
                          width: 280,
                          child: PillCtaButton(
                            label: widget.primaryLabel,
                            leadingIcon: widget.primaryLeadingIcon,
                            onTap: widget.onPrimary,
                          ),
                        ),
                        if (widget.secondaryLabel != null &&
                            widget.onSecondary != null) ...[
                          const SizedBox(height: AppSpacing.space12),
                          SizedBox(
                            width: 280,
                            child: PillCtaButton(
                              label: widget.secondaryLabel!,
                              leadingIcon: widget.secondaryLeadingIcon,
                              onTap: widget.onSecondary,
                              variant: PillVariant.outlined,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Default breathing: subtle scale pulse 1.0 → 1.04 → 1.0.
  Widget _defaultBreathing(
    BuildContext context,
    Widget icon,
    Animation<double> t,
  ) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, _) =>
          Transform.scale(scale: 1 + t.value * 0.04, child: icon),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({
    required this.icon,
    required this.animation,
    required this.builder,
  });

  final IconData icon;
  final Animation<double> animation;
  final BreathingIconBuilder builder;

  @override
  Widget build(BuildContext context) {
    final iconWidget = SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer radial halo.
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ColorName.primary.withValues(alpha: 0.1),
                  ColorName.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Inner solid disc.
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: ColorName.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 44, color: ColorName.primary),
          ),
        ],
      ),
    );
    return builder(context, iconWidget, animation);
  }
}

/// Pre-built breathing animation helpers for each domain. Callers pass one
/// of these to [BlankCanvasHero.breathingIconBuilder] to give the empty
/// state a domain-specific personality.
class BlankCanvasBreathing {
  const BlankCanvasBreathing._();

  /// Activities — subtle scale pulse.
  static BreathingIconBuilder pulse() {
    return (ctx, child, t) => AnimatedBuilder(
      animation: t,
      builder: (_, _) =>
          Transform.scale(scale: 1 + t.value * 0.04, child: child),
    );
  }

  /// Transports — tilt back and forth.
  static BreathingIconBuilder tilt({double maxDegrees = 2}) {
    return (ctx, child, t) => AnimatedBuilder(
      animation: t,
      builder: (_, _) => Transform.rotate(
        angle: (t.value * 2 - 1) * (maxDegrees * 3.14159 / 180),
        child: child,
      ),
    );
  }

  /// Accommodations — shadow softening via scale + opacity on the halo
  /// (fades in and out subtly).
  static BreathingIconBuilder softShadow() {
    return (ctx, child, t) => AnimatedBuilder(
      animation: t,
      builder: (_, _) => Opacity(opacity: 0.85 + t.value * 0.15, child: child),
    );
  }

  /// Budget — full rotate per cycle (subtle, slow).
  static BreathingIconBuilder rotate() {
    return (ctx, child, t) => AnimatedBuilder(
      animation: t,
      builder: (_, _) =>
          Transform.rotate(angle: t.value * 2 * 3.14159, child: child),
    );
  }

  /// Shares — subtle horizontal drift (±2px).
  static BreathingIconBuilder drift() {
    return (ctx, child, t) => AnimatedBuilder(
      animation: t,
      builder: (_, _) => Transform.translate(
        offset: Offset((t.value * 2 - 1) * 2, 0),
        child: child,
      ),
    );
  }
}
