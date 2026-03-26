import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback — iOS only (Android handles haptics at OS level).
abstract final class AppHaptics {
  /// Selection, toggle, chip tap.
  static Future<void> light() async {
    if (!AdaptivePlatform.isIOS) return;
    await HapticFeedback.lightImpact();
  }

  /// Button press, card selection.
  static Future<void> medium() async {
    if (!AdaptivePlatform.isIOS) return;
    await HapticFeedback.mediumImpact();
  }

  /// Trip created, step complete.
  static Future<void> success() async {
    if (!AdaptivePlatform.isIOS) return;
    await HapticFeedback.heavyImpact();
  }

  /// Validation failure, network error.
  static Future<void> error() async {
    if (!AdaptivePlatform.isIOS) return;
    await HapticFeedback.vibrate();
  }
}
