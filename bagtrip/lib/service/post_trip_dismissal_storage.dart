import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists "remind me later" dismissals for post-trip completion dialogs.
/// Each dismissal stores a timestamp; entries older than 24h are considered expired.
class PostTripDismissalStorage {
  static const _key = 'post_trip_dismissals';

  Future<Map<String, String>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveAll(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Returns `true` if the trip was dismissed less than 24 hours ago.
  Future<bool> wasDismissedRecently(String tripId) async {
    final all = await _loadAll();
    final ts = all[tripId];
    if (ts == null) return false;
    final dismissedAt = DateTime.tryParse(ts);
    if (dismissedAt == null) return false;
    return DateTime.now().difference(dismissedAt).inHours < 24;
  }

  /// Record a dismissal for the given trip (now).
  Future<void> recordDismissal(String tripId) async {
    final all = await _loadAll();
    all[tripId] = DateTime.now().toIso8601String();
    await _saveAll(all);
  }

  /// Remove the dismissal record for the given trip.
  Future<void> clearDismissal(String tripId) async {
    final all = await _loadAll();
    all.remove(tripId);
    await _saveAll(all);
  }
}
