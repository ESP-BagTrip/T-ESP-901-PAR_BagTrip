part of 'hotel_search_result_bloc.dart';

@immutable
sealed class HotelSearchResultEvent {}

class LoadHotels extends HotelSearchResultEvent {
  final String tripId;
  final String cityCode;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int roomsQty;
  final String? currency;

  LoadHotels({
    required this.tripId,
    required this.cityCode,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.roomsQty,
    this.currency,
  });
}