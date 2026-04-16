import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnboardingStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = OnboardingStorage();
  });

  group('OnboardingStorage', () {
    test('hasSeenOnboarding is false by default', () async {
      expect(await storage.hasSeenOnboarding(), isFalse);
    });

    test('setOnboardingSeen persists true', () async {
      await storage.setOnboardingSeen();
      expect(await storage.hasSeenOnboarding(), isTrue);
    });

    test(
      'hasSeenOnboarding reads the prefs instance the second time',
      () async {
        SharedPreferences.setMockInitialValues({'onboarding_seen': true});
        expect(await OnboardingStorage().hasSeenOnboarding(), isTrue);
      },
    );
  });
}
