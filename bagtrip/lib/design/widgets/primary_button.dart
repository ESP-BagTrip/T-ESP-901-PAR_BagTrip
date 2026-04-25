import 'package:bagtrip/components/adaptive/adaptive_button.dart';
import 'package:flutter/material.dart';

/// Generic primary button for non-progression actions (auth, onboarding, etc.).
/// For next-step/continue CTAs, use `ProgressionCtaButton`.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
    );
  }
}
