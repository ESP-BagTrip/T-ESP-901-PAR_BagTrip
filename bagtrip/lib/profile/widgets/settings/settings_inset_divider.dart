import 'package:flutter/material.dart';

/// Horizontal divider inset to align with settings row text (after icon badge).
class SettingsInsetDivider extends StatelessWidget {
  const SettingsInsetDivider({super.key});

  static const double _startIndent = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: _startIndent,
      endIndent: 0,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}
