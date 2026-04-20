import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Small floating button mounted on a panel (inside [Stack] + [Positioned])
/// to expose the primary quick-add action without taking over the screen.
///
/// Visual contract:
/// - **iOS** — compact 52×52 circle in `primaryDark`, centred `+` icon. The
///   label is not rendered (AppBar/secondary-label style), matching Apple HIG
///   where a FAB metaphor doesn't exist.
/// - **Android** — extended FAB with icon + label (Material design).
///
/// The caller is responsible for positioning (usually `Positioned(bottom: 24,
/// right: 24)`). Haptic `light` is fired automatically on tap before the
/// callback runs — callers can still escalate to `medium` inside the callback
/// once the form sheet opens.
class PanelFab extends StatelessWidget {
  const PanelFab({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  void _handleTap() {
    AppHaptics.light();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (AdaptivePlatform.isIOS) {
      return _IosFab(label: label, icon: icon, onTap: _handleTap);
    }
    return _AndroidFab(label: label, icon: icon, onTap: _handleTap);
  }
}

class _IosFab extends StatelessWidget {
  const _IosFab({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ColorName.primaryDark,
            shape: BoxShape.circle,
            boxShadow: AppShadows.card,
          ),
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _AndroidFab extends StatelessWidget {
  const _AndroidFab({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: ColorName.primaryDark,
      foregroundColor: Colors.white,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
