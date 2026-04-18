import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Final decision block at the end of the scroll. A confident primary CTA
/// with inner glow, paired with a quieter "try something else" link.
class ReviewDecisionInline extends StatelessWidget {
  const ReviewDecisionInline({
    super.key,
    required this.header,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.isPrimaryLoading = false,
  });

  final String header;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space32,
        AppSpacing.space24,
        AppSpacing.space40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            header,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.reviewFaint.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          _GradientCta(
            label: primaryLabel,
            onTap: onPrimary,
            isLoading: isPrimaryLoading,
          ),
          const SizedBox(height: AppSpacing.space12),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                foregroundColor: AppColors.reviewSubtle,
              ),
              child: Text(
                secondaryLabel,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.reviewSubtle,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatefulWidget {
  const _GradientCta({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<_GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<_GradientCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled
          ? (_) {
              _setPressed(false);
              widget.onTap!.call();
            }
          : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 140),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? const [Color(0xFF1B3A5E), ColorName.primaryDark]
                  : [
                      ColorName.primaryDark.withValues(alpha: 0.4),
                      ColorName.primaryDark.withValues(alpha: 0.4),
                    ],
            ),
            borderRadius: AppRadius.pill,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ColorName.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: SizedBox(
            height: 56,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
