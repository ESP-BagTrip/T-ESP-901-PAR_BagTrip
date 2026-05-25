import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Colored icon container for settings rows (44×44, rounded).
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.iconColor,
  });

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.medium12,
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}
