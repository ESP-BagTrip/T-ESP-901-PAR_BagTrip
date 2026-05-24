import 'package:flutter_test/flutter_test.dart';

/// Mirrors the season mapping logic originally from the legacy trip creation flow.
///
/// The mapping uses French season names:
///   months 3-5  → 'printemps'  (spring)
///   months 6-8  → 'été'        (summer)
///   months 9-11 → 'automne'    (autumn)
///   months 12,1,2 → 'hiver'   (winter)
String? seasonFromMonth(int? month) {
  if (month == null) return null;
  if (month >= 3 && month <= 5) return 'printemps';
  if (month >= 6 && month <= 8) return 'été';
  if (month >= 9 && month <= 11) return 'automne';
  return 'hiver';
}

void main() {
  group('Season mapping (month → season)', () {
    test('January maps to hiver', () {
      expect(seasonFromMonth(1), 'hiver');
    });

    test('February maps to hiver', () {
      expect(seasonFromMonth(2), 'hiver');
    });

    test('March maps to printemps', () {
      expect(seasonFromMonth(3), 'printemps');
    });

    test('April maps to printemps', () {
      expect(seasonFromMonth(4), 'printemps');
    });

    test('May maps to printemps', () {
      expect(seasonFromMonth(5), 'printemps');
    });

    test('June maps to été', () {
      expect(seasonFromMonth(6), 'été');
    });

    test('July maps to été', () {
      expect(seasonFromMonth(7), 'été');
    });

    test('August maps to été', () {
      expect(seasonFromMonth(8), 'été');
    });

    test('September maps to automne', () {
      expect(seasonFromMonth(9), 'automne');
    });

    test('October maps to automne', () {
      expect(seasonFromMonth(10), 'automne');
    });

    test('November maps to automne', () {
      expect(seasonFromMonth(11), 'automne');
    });

    test('December maps to hiver', () {
      expect(seasonFromMonth(12), 'hiver');
    });

    test('null month returns null', () {
      expect(seasonFromMonth(null), isNull);
    });

    test('all 12 months produce exactly 4 distinct seasons', () {
      final seasons = List.generate(12, (i) => seasonFromMonth(i + 1)).toSet();
      expect(seasons, {'hiver', 'printemps', 'été', 'automne'});
    });

    test('season boundaries are correct', () {
      // Winter-Spring boundary
      expect(seasonFromMonth(2), 'hiver');
      expect(seasonFromMonth(3), 'printemps');

      // Spring-Summer boundary
      expect(seasonFromMonth(5), 'printemps');
      expect(seasonFromMonth(6), 'été');

      // Summer-Autumn boundary
      expect(seasonFromMonth(8), 'été');
      expect(seasonFromMonth(9), 'automne');

      // Autumn-Winter boundary
      expect(seasonFromMonth(11), 'automne');
      expect(seasonFromMonth(12), 'hiver');
    });

    test('integration with DateTime.month', () {
      expect(seasonFromMonth(DateTime(2024, 1, 15).month), 'hiver');
      expect(seasonFromMonth(DateTime(2024, 4).month), 'printemps');
      expect(seasonFromMonth(DateTime(2024, 7, 20).month), 'été');
      expect(seasonFromMonth(DateTime(2024, 10, 31).month), 'automne');
    });
  });
}
