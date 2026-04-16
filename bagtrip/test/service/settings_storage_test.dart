import 'package:bagtrip/service/settings_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = SettingsStorage();
  });

  group('SettingsStorage', () {
    test('getTheme returns null when unset', () async {
      expect(await storage.getTheme(), isNull);
    });

    test('setTheme + getTheme round-trips', () async {
      await storage.setTheme('dark');
      expect(await storage.getTheme(), 'dark');
    });

    test('getLanguage returns null when unset', () async {
      expect(await storage.getLanguage(), isNull);
    });

    test('setLanguage + getLanguage round-trips', () async {
      await storage.setLanguage('fr');
      expect(await storage.getLanguage(), 'fr');
    });

    test('theme and language are independent keys', () async {
      await storage.setTheme('light');
      await storage.setLanguage('en');
      expect(await storage.getTheme(), 'light');
      expect(await storage.getLanguage(), 'en');
    });
  });
}
