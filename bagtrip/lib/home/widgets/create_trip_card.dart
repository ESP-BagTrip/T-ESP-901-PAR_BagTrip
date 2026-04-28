import 'dart:math' as math;

import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateTripCard extends StatefulWidget {
  final bool isFirstTrip;
  final String? subtitle;

  const CreateTripCard({super.key, this.isFirstTrip = false, this.subtitle});

  @override
  State<CreateTripCard> createState() => _CreateTripCardState();
}

class _CreateTripCardState extends State<CreateTripCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        AppHaptics.medium();
        const PlanTripRoute().go(context);
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space4,
          ),
          decoration: const BoxDecoration(
            borderRadius: AppRadius.large28,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0E1A2B),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.large24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boundedHeight =
                    constraints.hasBoundedHeight &&
                    constraints.maxHeight < double.infinity;
                return Stack(
                  fit: boundedHeight ? StackFit.expand : StackFit.loose,
                  children: [
                    // Base gradient — uses design system dark colors
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    ColorName.surfaceDark,
                                    ColorName.primaryTrueDark,
                                    ColorName.primaryDark,
                                  ]
                                : [
                                    ColorName.primaryTrueDark,
                                    ColorName.primaryDark,
                                    ColorName.primary,
                                  ],
                          ),
                        ),
                      ),
                    ),

                    // Mesh gradient — accent radial glows
                    Positioned(
                      top: -60,
                      right: -40,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              PersonalizationColors.accentBlue.withValues(
                                alpha: 0.35,
                              ),
                              PersonalizationColors.accentBlue.withValues(
                                alpha: 0.08,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      left: -60,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              PersonalizationColors.accentViolet.withValues(
                                alpha: 0.25,
                              ),
                              PersonalizationColors.accentViolet.withValues(
                                alpha: 0.05,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 100,
                      left: 50,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              ColorName.secondary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Noise texture
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.03,
                        child: CustomPaint(painter: _NoisePainter()),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.space24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: boundedHeight
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: AppRadius.large16,
                              border: Border.all(color: ColorName.secondary),
                            ),
                            child: const Icon(
                              CupertinoIcons.airplane,
                              color: ColorName.secondary,
                              size: 20,
                            ),
                          ),
                          if (boundedHeight)
                            const Spacer()
                          else
                            const SizedBox(height: AppSpacing.space24),
                          if (widget.isFirstTrip) ...[
                            Text(
                              l10n.homeNewTripEyebrow.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: ColorName.secondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space8),
                          ],
                          Text(
                            widget.isFirstTrip
                                ? l10n.homeCreateFirstTrip
                                : l10n.planTripCta,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSerifDisplay,
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: ColorName.surface,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.space12),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: ColorName.surface.withValues(
                                  alpha: 0.84,
                                ),
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.space32),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: const BoxDecoration(
                              color: ColorName.secondary,
                              borderRadius: AppRadius.large16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.isFirstTrip
                                      ? l10n.homeCtaAiOrManual
                                      : l10n.homeCtaStartPlanning,
                                  style: const TextStyle(
                                    fontFamily: FontFamily.dMSans,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: ColorName.surface,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  CupertinoIcons.arrow_right,
                                  size: 12,
                                  color: ColorName.surface,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle noise texture for premium depth.
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 600; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
