import 'package:shared_preferences/shared_preferences.dart';

String _keyPromptSeen(String userId) => 'personalization_prompt_seen_$userId';
String _keyTravelTypes(String userId) => 'personalization_travel_types_$userId';
String _keyBudget(String userId) => 'personalization_budget_$userId';
String _keyCompanions(String userId) => 'personalization_companions_$userId';
String _keyTravelStyle(String userId) => 'personalization_travel_style_$userId';
String _keyTravelFrequency(String userId) =>
    'personalization_travel_frequency_$userId';
String _keyConstraints(String userId) => 'personalization_constraints_$userId';
String _keyWelcomeSeen(String userId) => 'personalization_welcome_seen_$userId';

/// Persists whether the user has seen the personalization prompt (per user)
/// and the user's travel preferences.
class PersonalizationStorage {
  Future<bool> hasSeenPersonalizationPrompt(String userId) async {
    if (userId.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPromptSeen(userId)) ?? false;
  }

  Future<void> setPersonalizationPromptSeen(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromptSeen(userId), true);
  }

  Future<String> getTravelTypes(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTravelTypes(userId)) ?? '';
  }

  Future<void> setTravelTypes(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTravelTypes(userId), value);
  }

  Future<String> getBudget(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBudget(userId)) ?? '';
  }

  Future<void> setBudget(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudget(userId), value);
  }

  Future<String> getCompanions(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCompanions(userId)) ?? '';
  }

  Future<void> setCompanions(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompanions(userId), value);
  }

  Future<String> getTravelStyle(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTravelStyle(userId)) ?? '';
  }

  Future<void> setTravelStyle(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTravelStyle(userId), value);
  }

  Future<String> getTravelFrequency(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTravelFrequency(userId)) ?? '';
  }

  Future<void> setTravelFrequency(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTravelFrequency(userId), value);
  }

  Future<String> getConstraints(String userId) async {
    if (userId.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConstraints(userId)) ?? '';
  }

  Future<void> setConstraints(String userId, String value) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConstraints(userId), value);
  }

  /// True if the user has already seen the welcome screen (first launch only).
  Future<bool> hasSeenPersonalizationWelcome(String userId) async {
    if (userId.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWelcomeSeen(userId)) ?? false;
  }

  Future<void> setPersonalizationWelcomeSeen(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWelcomeSeen(userId), true);
  }
}
