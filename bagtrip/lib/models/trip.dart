import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

enum TripStatus {
  draft,
  planned,
  ongoing,
  completed;

  static TripStatus fromString(String value) {
    final lower = value.toLowerCase();
    switch (lower) {
      case 'draft':
        return TripStatus.draft;
      case 'planned' || 'planning':
        return TripStatus.planned;
      case 'ongoing' || 'active':
        return TripStatus.ongoing;
      case 'completed' || 'archived':
        return TripStatus.completed;
      default:
        return TripStatus.draft;
    }
  }
}

class TripStatusConverter implements JsonConverter<TripStatus, String> {
  const TripStatusConverter();

  @override
  TripStatus fromJson(String json) => TripStatus.fromString(json);

  @override
  String toJson(TripStatus object) => object.name;
}

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    String? userId,
    String? title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
    @TripStatusConverter() @Default(TripStatus.draft) TripStatus status,
    String? description,
    @JsonKey(name: 'destination_name') String? destinationName,
    String? destinationTimezone,
    int? nbTravelers,
    String? coverImageUrl,
    double? budgetTotal,
    String? origin,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
