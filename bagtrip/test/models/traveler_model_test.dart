import 'package:bagtrip/models/traveler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Traveler JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'trav-1',
        'trip_id': 'trip-1',
        'amadeus_traveler_ref': 'AMX-42',
        'traveler_type': 'CHILD',
        'first_name': 'Marie',
        'last_name': 'Dupont',
        'date_of_birth': '1990-05-20T00:00:00.000',
        'gender': 'F',
        'documents': [
          {'type': 'PASSPORT', 'number': 'FR123456'},
        ],
        'contacts': {'email': 'marie@example.com', 'phone': '+33612345678'},
        'created_at': '2024-05-01T10:00:00.000',
        'updated_at': '2024-05-02T12:00:00.000',
      };

      final first = Traveler.fromJson(json);
      final serialized = first.toJson();
      final second = Traveler.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'trav-1');
      expect(second.tripId, 'trip-1');
      expect(second.amadeusTravelerRef, 'AMX-42');
      expect(second.travelerType, 'CHILD');
      expect(second.firstName, 'Marie');
      expect(second.lastName, 'Dupont');
      expect(second.dateOfBirth, DateTime.parse('1990-05-20T00:00:00.000'));
      expect(second.gender, 'F');
      expect(second.documents, isNotNull);
      expect(second.documents!.first['type'], 'PASSPORT');
      expect(second.contacts!['email'], 'marie@example.com');
      expect(second.createdAt, DateTime.parse('2024-05-01T10:00:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-05-02T12:00:00.000'));
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'trav-min',
        'trip_id': 'trip-min',
        'first_name': 'Jean',
        'last_name': 'Martin',
      };

      final model = Traveler.fromJson(json);

      expect(model.id, 'trav-min');
      expect(model.tripId, 'trip-min');
      expect(model.firstName, 'Jean');
      expect(model.lastName, 'Martin');
      expect(model.travelerType, 'ADULT');
      expect(model.amadeusTravelerRef, isNull);
      expect(model.dateOfBirth, isNull);
      expect(model.gender, isNull);
      expect(model.documents, isNull);
      expect(model.contacts, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'trav-nulls',
        'trip_id': 'trip-nulls',
        'first_name': 'Null',
        'last_name': 'Traveler',
        'amadeus_traveler_ref': null,
        'date_of_birth': null,
        'gender': null,
        'documents': null,
        'contacts': null,
        'created_at': null,
        'updated_at': null,
      };

      final first = Traveler.fromJson(json);
      final serialized = first.toJson();
      final second = Traveler.fromJson(serialized);

      expect(second, first);
      expect(second.amadeusTravelerRef, isNull);
      expect(second.travelerType, 'ADULT');
      expect(second.dateOfBirth, isNull);
      expect(second.gender, isNull);
      expect(second.documents, isNull);
      expect(second.contacts, isNull);
      expect(second.createdAt, isNull);
      expect(second.updatedAt, isNull);
    });
  });
}
