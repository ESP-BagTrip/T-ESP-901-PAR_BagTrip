import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('extractBudgetEntries', () {
    test('extracts entries preserving canonical order', () {
      final entries = extractBudgetEntries(l10n, {
        'activities': 150,
        'flights': 300,
        'accommodation': 500,
      });
      expect(entries.length, 3);
      // order follows budgetCategoryKeys: flights first, then accommodation,
      // then activities (meals/transport absent here)
      expect(entries[0].amount, 300);
      expect(entries[1].amount, 500);
      expect(entries[2].amount, 150);
    });

    test('accepts {amount: X} shape', () {
      final entries = extractBudgetEntries(l10n, {
        'flights': {'amount': 200},
      });
      expect(entries.length, 1);
      expect(entries[0].amount, 200);
    });

    test('skips non-positive amounts', () {
      final entries = extractBudgetEntries(l10n, {
        'flights': 0,
        'accommodation': -10,
        'meals': 40,
      });
      expect(entries.length, 1);
      expect(entries[0].amount, 40);
    });

    test('ignores unknown keys', () {
      final entries = extractBudgetEntries(l10n, {
        'souvenirs': 25,
        'flights': 100,
      });
      expect(entries.length, 1);
      expect(entries[0].amount, 100);
    });

    test('handles empty / missing breakdown', () {
      expect(extractBudgetEntries(l10n, {}), isEmpty);
    });
  });

  group('budgetLabelForKey', () {
    test('returns localized label for known keys', () {
      expect(budgetLabelForKey('flights', l10n), l10n.reviewBudgetFlights);
      expect(
        budgetLabelForKey('accommodation', l10n),
        l10n.reviewBudgetAccommodation,
      );
    });

    test('falls back to Other for unknown key', () {
      expect(budgetLabelForKey('???', l10n), l10n.reviewBudgetOther);
    });
  });

  group('budgetColorForKey', () {
    test('distinct colors per canonical key', () {
      final seen = <String, int>{};
      for (final key in budgetCategoryKeys) {
        final c = budgetColorForKey(key);
        seen[key] = c.toARGB32();
      }
      expect(seen.values.toSet().length, seen.length);
    });
  });
}
