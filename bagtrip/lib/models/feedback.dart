import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback.freezed.dart';
part 'feedback.g.dart';

@freezed
abstract class TripFeedback with _$TripFeedback {
  const factory TripFeedback({
    required String id,
    required String tripId,
    required String userId,
    required int overallRating,
    String? highlights,
    String? lowlights,
    @Default(false) bool wouldRecommend,
    DateTime? createdAt,
  }) = _TripFeedback;

  factory TripFeedback.fromJson(Map<String, dynamic> json) =>
      _$TripFeedbackFromJson(json);
}
