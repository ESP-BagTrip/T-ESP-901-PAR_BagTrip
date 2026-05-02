// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
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
      final entries = extractBudgetEntries(
        l10n,
        const BudgetBreakdown(flight: 300, accommodation: 500, activity: 150),
      );
      expect(entries.length, 3);
      // order follows budgetCategoryKeys: flight, accommodation, activity
      expect(entries[0].amount, 300);
      expect(entries[1].amount, 500);
      expect(entries[2].amount, 150);
    });

    test('skips non-positive amounts', () {
      final entries = extractBudgetEntries(
        l10n,
        const BudgetBreakdown(food: 40),
      );
      expect(entries.length, 1);
      expect(entries[0].amount, 40);
    });

    test('appends `other` bucket when present', () {
      final entries = extractBudgetEntries(
        l10n,
        const BudgetBreakdown(flight: 100, other: 25),
      );
      expect(entries.length, 2);
      expect(entries[0].amount, 100);
      expect(entries[1].amount, 25);
    });

    test('handles empty breakdown', () {
      expect(extractBudgetEntries(l10n, const BudgetBreakdown()), isEmpty);
    });
  });

  group('budgetLabelForKey', () {
    test('returns localized label for known keys', () {
      expect(budgetLabelForKey('flight', l10n), l10n.reviewBudgetFlights);
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

  group('BudgetBreakdown.fromSseMap (B13)', () {
    test('parses flat numbers', () {
      final b = BudgetBreakdown.fromSseMap({'flight': 200, 'food': 50});
      expect(b.flight, 200);
      expect(b.food, 50);
    });

    test('parses {amount: X} objects', () {
      final b = BudgetBreakdown.fromSseMap({
        'flight': {'amount': 200, 'currency': 'EUR'},
      });
      expect(b.flight, 200);
    });

    test('coerces negatives to zero (no silent under-counting)', () {
      final b = BudgetBreakdown.fromSseMap({'accommodation': -150});
      expect(b.accommodation, 0);
    });

    test('captures unknown keys in `other`', () {
      final b = BudgetBreakdown.fromSseMap({'flight': 100, 'souvenirs': 25});
      expect(b.flight, 100);
      expect(b.other, 25);
    });

    test('drops total_min/total_max/currency metadata', () {
      final b = BudgetBreakdown.fromSseMap({
        'flight': 100,
        'total_min': 90,
        'total_max': 110,
        'currency': 'EUR',
      });
      expect(b.flight, 100);
      expect(b.other, 0);
    });

    test('total getter sums every category including other', () {
      const b = BudgetBreakdown(
        flight: 100,
        accommodation: 200,
        food: 30,
        transport: 20,
        activity: 50,
        other: 10,
      );
      expect(b.total, 410);
      expect(b.isEmpty, isFalse);
    });

    test('isEmpty true when every category is zero', () {
      expect(const BudgetBreakdown().isEmpty, isTrue);
    });
  });
}
