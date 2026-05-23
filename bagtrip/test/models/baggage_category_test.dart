import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/l10n/app_localizations_en.dart';
import 'package:bagtrip/models/baggage_category.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaggageCategory.fromApi', () {
    test('maps each known backend value to its enum', () {
      expect(BaggageCategory.fromApi('DOCUMENTS'), BaggageCategory.documents);
      expect(BaggageCategory.fromApi('CLOTHING'), BaggageCategory.clothing);
      expect(
        BaggageCategory.fromApi('ELECTRONICS'),
        BaggageCategory.electronics,
      );
      expect(BaggageCategory.fromApi('TOILETRIES'), BaggageCategory.toiletries);
      expect(BaggageCategory.fromApi('HEALTH'), BaggageCategory.health);
      expect(
        BaggageCategory.fromApi('ACCESSORIES'),
        BaggageCategory.accessories,
      );
      expect(BaggageCategory.fromApi('OTHER'), BaggageCategory.other);
    });

    test('falls back to other on null', () {
      expect(BaggageCategory.fromApi(null), BaggageCategory.other);
    });

    test('falls back to other on an unknown value', () {
      expect(BaggageCategory.fromApi('SOMETHING_NEW'), BaggageCategory.other);
    });

    test('apiValue round-trips through fromApi', () {
      for (final c in BaggageCategory.values) {
        expect(BaggageCategory.fromApi(c.apiValue), c);
      }
    });
  });

  group('BaggageCategoryPresentation', () {
    final l10n = AppLocalizationsEn();

    test('every category has a non-empty localized label', () {
      for (final c in BaggageCategory.values) {
        expect(c.label(l10n), isNotEmpty);
      }
    });

    test('every category resolves an icon and a color without throwing', () {
      for (final c in BaggageCategory.values) {
        // Accessing icon/color must be total over the enum (exhaustive switch).
        expect(c.icon, isNotNull);
        expect(c.color, isNotNull);
      }
    });
  });

  group('BaggageItem.categoryEnum', () {
    BaggageItem item(String? category) =>
        BaggageItem(id: 'i', tripId: 't', name: 'n', category: category);

    test('parses the raw category string', () {
      expect(item('HEALTH').categoryEnum, BaggageCategory.health);
    });

    test('null category resolves to other', () {
      expect(item(null).categoryEnum, BaggageCategory.other);
    });

    test('unknown category resolves to other', () {
      expect(item('WUT').categoryEnum, BaggageCategory.other);
    });
  });
}
