import 'dart:io';

/// Centralises platform detection — avoids scattering Platform.isIOS everywhere.
abstract class AdaptivePlatform {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Helper to choose a widget / value depending on the current platform.
  static T select<T>({required T material, required T cupertino}) {
    return isIOS ? cupertino : material;
  }
}
