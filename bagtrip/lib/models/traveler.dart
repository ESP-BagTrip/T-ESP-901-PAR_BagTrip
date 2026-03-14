import 'package:freezed_annotation/freezed_annotation.dart';

part 'traveler.freezed.dart';
part 'traveler.g.dart';

@freezed
abstract class Traveler with _$Traveler {
  const factory Traveler({
    required String id,
    required String tripId,
    String? amadeusTravelerRef,
    @Default('ADULT') String travelerType,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    List<Map<String, dynamic>>? documents,
    Map<String, dynamic>? contacts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Traveler;

  factory Traveler.fromJson(Map<String, dynamic> json) =>
      _$TravelerFromJson(json);
}
