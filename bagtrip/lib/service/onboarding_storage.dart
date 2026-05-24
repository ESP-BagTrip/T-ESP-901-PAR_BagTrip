import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingSeen = 'onboarding_seen';

/// Persists whether the user has seen the onboarding screen.
class OnboardingStorage {
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }
}
