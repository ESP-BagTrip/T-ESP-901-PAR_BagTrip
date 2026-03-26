import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  final Set<String> _openedBoxes = {};

  static Future<void> initialize() async {
    await Hive.initFlutter();
  }

  Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> data,
  ) async {
    final box = await _openBox(boxName);
    await box.put(key, {
      'data': data,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> get(
    String boxName,
    String key, {
    Duration ttl = const Duration(minutes: 15),
  }) async {
    final box = await _openBox(boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    final entry = Map<String, dynamic>.from(raw as Map);
    final cachedAt = entry['cachedAt'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;

    if (ttl.inMilliseconds == 0 || age > ttl.inMilliseconds) {
      await box.delete(key);
      return null;
    }

    return Map<String, dynamic>.from(entry['data'] as Map);
  }

  Future<void> delete(String boxName, String key) async {
    final box = await _openBox(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = await _openBox(boxName);
    await box.clear();
  }

  Future<void> clearAll() async {
    for (final name in _openedBoxes.toList()) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).clear();
      }
    }
  }

  Future<Box<dynamic>> _openBox(String name) async {
    _openedBoxes.add(name);
    return Hive.openBox<dynamic>(name);
  }
}
