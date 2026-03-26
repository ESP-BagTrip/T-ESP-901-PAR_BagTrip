import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_booking.freezed.dart';
part 'recent_booking.g.dart';

@freezed
abstract class RecentBooking with _$RecentBooking {
  const factory RecentBooking({
    required String id,
    required String details,
    required DateTime date,
    @JsonKey(name: 'priceTotal') required double priceTotal,
    required String currency,
    required String status,
  }) = _RecentBooking;

  factory RecentBooking.fromJson(Map<String, dynamic> json) =>
      _$RecentBookingFromJson(json);
}
