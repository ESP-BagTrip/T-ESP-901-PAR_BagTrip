import 'package:bagtrip/models/feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripFeedback JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'fb-1',
        'trip_id': 'trip-1',
        'user_id': 'user-1',
        'overall_rating': 5,
        'highlights': 'Amazing food and scenery',
        'lowlights': 'Too short',
        'would_recommend': true,
        'ai_experience_rating': 4,
        'created_at': '2024-08-01T18:00:00.000',
      };

      final first = TripFeedback.fromJson(json);
      final serialized = first.toJson();
      final second = TripFeedback.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'fb-1');
      expect(second.tripId, 'trip-1');
      expect(second.userId, 'user-1');
      expect(second.overallRating, 5);
      expect(second.highlights, 'Amazing food and scenery');
      expect(second.lowlights, 'Too short');
      expect(second.wouldRecommend, true);
      expect(second.aiExperienceRating, 4);
      expect(second.createdAt, DateTime.parse('2024-08-01T18:00:00.000'));
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'fb-min',
        'trip_id': 'trip-min',
        'user_id': 'user-min',
        'overall_rating': 3,
      };

      final model = TripFeedback.fromJson(json);

      expect(model.id, 'fb-min');
      expect(model.tripId, 'trip-min');
      expect(model.userId, 'user-min');
      expect(model.overallRating, 3);
      expect(model.wouldRecommend, false);
      expect(model.highlights, isNull);
      expect(model.lowlights, isNull);
      expect(model.aiExperienceRating, isNull);
      expect(model.createdAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'fb-nulls',
        'trip_id': 'trip-nulls',
        'user_id': 'user-nulls',
        'overall_rating': 1,
        'highlights': null,
        'lowlights': null,
        'ai_experience_rating': null,
        'created_at': null,
      };

      final first = TripFeedback.fromJson(json);
      final serialized = first.toJson();
      final second = TripFeedback.fromJson(serialized);

      expect(second, first);
      expect(second.wouldRecommend, false);
      expect(second.highlights, isNull);
      expect(second.lowlights, isNull);
      expect(second.aiExperienceRating, isNull);
      expect(second.createdAt, isNull);
    });
  });
}
