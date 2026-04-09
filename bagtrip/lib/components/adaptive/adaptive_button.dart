import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A button that renders Material [ElevatedButton] on Android and
/// [CupertinoButton.filled] on iOS.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (AdaptivePlatform.isIOS) {
      return Semantics(
        button: true,
        label: label,
        enabled: !isLoading && onPressed != null,
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: isLoading ? null : onPressed,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Text(label),
                    ],
                  ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 8)],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}
