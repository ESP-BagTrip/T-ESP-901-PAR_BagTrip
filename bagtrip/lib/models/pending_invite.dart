import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_invite.freezed.dart';
part 'pending_invite.g.dart';

@freezed
abstract class PendingInvite with _$PendingInvite {
  const factory PendingInvite({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    required String email,
    @Default('VIEWER') String role,
    required String token,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _PendingInvite;

  factory PendingInvite.fromJson(Map<String, dynamic> json) =>
      _$PendingInviteFromJson(json);
}
