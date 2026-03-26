import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_share.freezed.dart';
part 'trip_share.g.dart';

@freezed
abstract class TripShare with _$TripShare {
  const factory TripShare({
    required String id,
    required String tripId,
    required String userId,
    @Default('VIEWER') String role,
    DateTime? invitedAt,
    required String userEmail,
    String? userFullName,
  }) = _TripShare;

  factory TripShare.fromJson(Map<String, dynamic> json) =>
      _$TripShareFromJson(json);
}
