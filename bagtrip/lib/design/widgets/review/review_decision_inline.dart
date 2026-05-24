import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Final decision at the end of the scroll.
///
/// A solid ink pill (no screaming gradient) paired with a quiet text link
/// for the alternative path. Luxury via restraint.
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
        AppSpacing.space40,
        AppSpacing.space24,
        AppSpacing.space48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              header,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.2,
                color: AppColors.reviewInk.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          _InkCta(
            label: primaryLabel,
            onTap: onPrimary,
            isLoading: isPrimaryLoading,
          ),
          const SizedBox(height: AppSpacing.space16),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space8,
                ),
                foregroundColor: AppColors.reviewSubtle,
                overlayColor: Colors.transparent,
              ),
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.reviewInk.withValues(alpha: 0.55),
                  decoration: TextDecoration.underline,
                  decorationThickness: 0.8,
                  decorationColor: AppColors.reviewInk.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkCta extends StatefulWidget {
  const _InkCta({
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<_InkCta> createState() => _InkCtaState();
}

class _InkCtaState extends State<_InkCta> {
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
            color: enabled
                ? const Color(0xFF0D1F35)
                : const Color(0xFF0D1F35).withValues(alpha: 0.4),
            borderRadius: AppRadius.pill,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF0D1F35).withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: SizedBox(
            height: 58,
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
                  : Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
