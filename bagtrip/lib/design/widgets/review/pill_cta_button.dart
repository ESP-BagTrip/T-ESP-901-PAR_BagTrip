import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Visual variant of [PillCtaButton].
enum PillVariant { filled, outlined, danger }

/// Pill-shaped primary CTA used across the review/edit universe.
///
/// Encapsulates tap-scale 0.98 feedback. Replaces ad-hoc [FilledButton] /
/// [OutlinedButton] in the trip detail bottom actions and wraps the wizard
/// "create trip" button with the same visual vocabulary.
class PillCtaButton extends StatefulWidget {
  const PillCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = PillVariant.filled,
    this.isLoading = false,
    this.leadingIcon,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onTap;
  final PillVariant variant;
  final bool isLoading;
  final IconData? leadingIcon;
  final double height;

  @override
  State<PillCtaButton> createState() => _PillCtaButtonState();
}

class _PillCtaButtonState extends State<PillCtaButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    final decoration = _decorationFor(widget.variant, enabled);
    final foreground = _foregroundFor(widget.variant, enabled);

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
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: decoration,
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(foreground),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Icon(widget.leadingIcon, size: 18, color: foreground),
                      const SizedBox(width: AppSpacing.space8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  BoxDecoration _decorationFor(PillVariant variant, bool enabled) {
    switch (variant) {
      case PillVariant.filled:
        return BoxDecoration(
          color: enabled
              ? ColorName.primaryDark
              : ColorName.primaryDark.withValues(alpha: 0.4),
          borderRadius: AppRadius.pill,
        );
      case PillVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: enabled
                ? ColorName.primaryDark
                : ColorName.primaryDark.withValues(alpha: 0.4),
            width: 1.5,
          ),
        );
      case PillVariant.danger:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: enabled
                ? ColorName.error
                : ColorName.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
        );
    }
  }

  Color _foregroundFor(PillVariant variant, bool enabled) {
    switch (variant) {
      case PillVariant.filled:
        return enabled ? Colors.white : Colors.white.withValues(alpha: 0.75);
      case PillVariant.outlined:
        return enabled
            ? ColorName.primaryDark
            : ColorName.primaryDark.withValues(alpha: 0.5);
      case PillVariant.danger:
        return enabled
            ? ColorName.error
            : ColorName.error.withValues(alpha: 0.5);
    }
  }
}
