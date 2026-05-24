import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ProgressionCtaIconPosition { left, right }

/// Shared CTA for progression actions across flows (continue/next/choose/start).
class ProgressionCtaButton extends StatelessWidget {
  const ProgressionCtaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.iconPosition = ProgressionCtaIconPosition.right,
    this.enabled = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final ProgressionCtaIconPosition iconPosition;
  final bool enabled;
  final bool isLoading;

  bool get _isInteractive => enabled && !isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _isInteractive ? ColorName.surface : ColorName.hint;
    final child = _ProgressionLabel(
      text: text,
      icon: icon,
      iconPosition: iconPosition,
      foregroundColor: foregroundColor,
      isLoading: isLoading,
    );

    if (AdaptivePlatform.isIOS) {
      return Semantics(
        button: true,
        label: text,
        enabled: _isInteractive,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: _decoration(),
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: Colors.transparent,
                disabledColor: Colors.transparent,
                onPressed: _isInteractive ? onPressed : null,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: text,
      enabled: _isInteractive,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: _decoration(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isInteractive ? onPressed : null,
              borderRadius: AppRadius.pill,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      gradient: _isInteractive
          ? const LinearGradient(
              colors: [ColorName.primary, ColorName.secondary],
            )
          : null,
      color: _isInteractive ? null : ColorName.secondary.withValues(alpha: 0.1),
      borderRadius: AppRadius.pill,
      boxShadow: _isInteractive
          ? [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ]
          : null,
    );
  }
}

class _ProgressionLabel extends StatelessWidget {
  const _ProgressionLabel({
    required this.text,
    required this.icon,
    required this.iconPosition,
    required this.foregroundColor,
    required this.isLoading,
  });

  final String text;
  final IconData? icon;
  final ProgressionCtaIconPosition iconPosition;
  final Color foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null &&
            iconPosition == ProgressionCtaIconPosition.left) ...[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSpacing.space8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontFamily: FontFamily.dMSans,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
        if (icon != null &&
            iconPosition == ProgressionCtaIconPosition.right) ...[
          const SizedBox(width: AppSpacing.space8),
          Icon(icon, size: 20, color: foregroundColor),
        ],
      ],
    );
  }
}
