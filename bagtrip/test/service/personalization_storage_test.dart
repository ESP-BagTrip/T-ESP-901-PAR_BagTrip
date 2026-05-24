import 'package:bagtrip/service/personalization_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PersonalizationStorage storage;
  const userId = 'user-1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = PersonalizationStorage();
  });

  group('PersonalizationStorage', () {
    // ── Empty userId guard: every getter returns empty/true ─────────────

    test('empty userId: prompt is treated as already seen', () async {
      expect(await storage.hasSeenPersonalizationPrompt(''), isTrue);
    });

    test('empty userId: welcome is treated as already seen', () async {
      expect(await storage.hasSeenPersonalizationWelcome(''), isTrue);
    });

    test('empty userId: string getters return ""', () async {
      expect(await storage.getTravelTypes(''), '');
      expect(await storage.getBudget(''), '');
      expect(await storage.getCompanions(''), '');
      expect(await storage.getTravelStyle(''), '');
      expect(await storage.getTravelFrequency(''), '');
      expect(await storage.getConstraints(''), '');
    });

    test('empty userId: setters are no-ops', () async {
      await storage.setPersonalizationPromptSeen('');
      await storage.setPersonalizationWelcomeSeen('');
      await storage.setTravelTypes('', 'culture');
      await storage.setBudget('', 'low');
      await storage.setCompanions('', 'solo');
      await storage.setTravelStyle('', 'balanced');
      await storage.setTravelFrequency('', 'monthly');
      await storage.setConstraints('', 'none');

      // Even re-creating the storage should see nothing persisted.
      expect(
        await PersonalizationStorage().hasSeenPersonalizationPrompt('user-x'),
        isFalse,
      );
    });

    // ── Prompt / welcome flags ──────────────────────────────────────────

    test('prompt flag round-trips per userId', () async {
      expect(await storage.hasSeenPersonalizationPrompt(userId), isFalse);
      await storage.setPersonalizationPromptSeen(userId);
      expect(await storage.hasSeenPersonalizationPrompt(userId), isTrue);
      // Different userId is unaffected.
      expect(await storage.hasSeenPersonalizationPrompt('other'), isFalse);
    });

    test('welcome flag round-trips per userId', () async {
      expect(await storage.hasSeenPersonalizationWelcome(userId), isFalse);
      await storage.setPersonalizationWelcomeSeen(userId);
      expect(await storage.hasSeenPersonalizationWelcome(userId), isTrue);
    });

    // ── String fields ───────────────────────────────────────────────────

    test('travel types round-trip', () async {
      expect(await storage.getTravelTypes(userId), '');
      await storage.setTravelTypes(userId, 'culture,nature');
      expect(await storage.getTravelTypes(userId), 'culture,nature');
    });

    test('budget round-trip', () async {
      await storage.setBudget(userId, 'medium');
      expect(await storage.getBudget(userId), 'medium');
    });

    test('companions round-trip', () async {
      await storage.setCompanions(userId, 'couple');
      expect(await storage.getCompanions(userId), 'couple');
    });

    test('travel style round-trip', () async {
      await storage.setTravelStyle(userId, 'relax');
      expect(await storage.getTravelStyle(userId), 'relax');
    });

    test('travel frequency round-trip', () async {
      await storage.setTravelFrequency(userId, 'yearly');
      expect(await storage.getTravelFrequency(userId), 'yearly');
    });

    test('constraints round-trip', () async {
      await storage.setConstraints(userId, 'gluten-free');
      expect(await storage.getConstraints(userId), 'gluten-free');
    });

    test('fields are isolated per userId', () async {
      await storage.setBudget('user-a', 'low');
      await storage.setBudget('user-b', 'high');
      expect(await storage.getBudget('user-a'), 'low');
      expect(await storage.getBudget('user-b'), 'high');
    });
  });
}
