part of 'hotel_search_result_bloc.dart';

@immutable
sealed class HotelSearchResultState {}

final class HotelSearchResultInitial extends HotelSearchResultState {}

final class HotelSearchResultLoading extends HotelSearchResultState {}

final class HotelSearchResultLoaded extends HotelSearchResultState {
  final String cityCode;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int roomsQty;
  final String? currency;
  final List<Hotel> hotels;
  final bool sortAscending;

  HotelSearchResultLoaded({
    required this.cityCode,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.roomsQty,
    this.currency,
    required this.hotels,
    this.sortAscending = true,
  });
}

final class HotelSearchResultError extends HotelSearchResultState {
  final String message;

  HotelSearchResultError(this.message);
}