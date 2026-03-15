import 'dart:ui';

import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Frosted glass panel for premium personalization UI.
///
/// - iOS: Uses [LiquidGlassContainer] for true Liquid Glass effect with shaders.
/// - Android: Falls back to [BackdropFilter] for a lighter Material-compatible blur.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.large20;

    if (AdaptivePlatform.isIOS) {
      return GlassContainer(
        useOwnLayer: true,
        shape: LiquidRoundedSuperellipse(
          borderRadius: radius.resolve(TextDirection.ltr).topLeft.x,
        ),
        padding: padding ?? AppSpacing.allEdgeInsetSpace24,
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? AppSpacing.allEdgeInsetSpace24,
          decoration: BoxDecoration(
            color: PersonalizationColors.surfaceGlass,
            borderRadius: radius,
            border: Border.all(
              color: PersonalizationColors.surfaceGlassBorder,
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
