import 'package:bagtrip/models/suggested_baggage_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuggestedBaggageItem JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'name': 'Sunscreen SPF50',
        'quantity': 2,
        'category': 'Hygiene',
        'reason': 'Tropical destination with high UV index',
      };

      final first = SuggestedBaggageItem.fromJson(json);
      final serialized = first.toJson();
      final second = SuggestedBaggageItem.fromJson(serialized);

      expect(second, first);
      expect(second.name, 'Sunscreen SPF50');
      expect(second.quantity, 2);
      expect(second.category, 'Hygiene');
      expect(second.reason, 'Tropical destination with high UV index');
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{'name': 'Umbrella'};

      final model = SuggestedBaggageItem.fromJson(json);

      expect(model.name, 'Umbrella');
      expect(model.quantity, 1);
      expect(model.category, 'Autre');
      expect(model.reason, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{'name': 'Adapter', 'reason': null};

      final first = SuggestedBaggageItem.fromJson(json);
      final serialized = first.toJson();
      final second = SuggestedBaggageItem.fromJson(serialized);

      expect(second, first);
      expect(second.quantity, 1);
      expect(second.category, 'Autre');
      expect(second.reason, isNull);
    });
  });
}
