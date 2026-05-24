part of 'accommodation_bloc.dart';

abstract class AccommodationEvent {}

class LoadAccommodations extends AccommodationEvent {
  final String tripId;
  LoadAccommodations({required this.tripId});
}

class CreateAccommodation extends AccommodationEvent {
  final String tripId;
  final Map<String, dynamic> data;
  CreateAccommodation({required this.tripId, required this.data});
}

class UpdateAccommodation extends AccommodationEvent {
  final String tripId;
  final String accommodationId;
  final Map<String, dynamic> data;
  UpdateAccommodation({
    required this.tripId,
    required this.accommodationId,
    required this.data,
  });
}

class DeleteAccommodation extends AccommodationEvent {
  final String tripId;
  final String accommodationId;
  DeleteAccommodation({required this.tripId, required this.accommodationId});
}

class SuggestAccommodations extends AccommodationEvent {
  final String tripId;
  SuggestAccommodations({required this.tripId});
}

class SearchHotels extends AccommodationEvent {
  final String cityCode;
  final String? checkIn;
  final String? checkOut;
  final int? adults;
  SearchHotels({
    required this.cityCode,
    this.checkIn,
    this.checkOut,
    this.adults,
  });
}

class SearchHotelOffers extends AccommodationEvent {
  final String hotelIds;
  final String? checkIn;
  final String? checkOut;
  SearchHotelOffers({required this.hotelIds, this.checkIn, this.checkOut});
}

class ClearHotelSearch extends AccommodationEvent {}
