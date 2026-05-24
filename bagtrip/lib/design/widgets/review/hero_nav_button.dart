import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Circular nav button used in [ReviewHero] and `BottomSheetScaffold`.
///
/// Sits on a dark surface (usually `ColorName.primaryDark`). White translucent
/// background with the provided [icon] centered.
class HeroNavButton extends StatelessWidget {
  const HeroNavButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppSpacing.space40,
          height: AppSpacing.space40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: ColorName.surface),
        ),
      ),
    );
    final t = tooltip;
    if (t == null) return button;
    return Tooltip(message: t, child: button);
  }
}
