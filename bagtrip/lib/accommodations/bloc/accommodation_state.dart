part of 'accommodation_bloc.dart';

abstract class AccommodationState {}

class AccommodationInitial extends AccommodationState {}

class AccommodationLoading extends AccommodationState {}

class AccommodationsLoaded extends AccommodationState {
  final List<Accommodation> accommodations;
  AccommodationsLoaded({required this.accommodations});
}

class AccommodationError extends AccommodationState {
  final AppError error;
  AccommodationError({required this.error});
}

class AccommodationSuggestionsLoading extends AccommodationState {}

class AccommodationSuggestionsLoaded extends AccommodationState {
  final List<Map<String, dynamic>> suggestions;
  AccommodationSuggestionsLoaded({required this.suggestions});
}

class AccommodationQuotaExceeded extends AccommodationState {}

class HotelSearchLoading extends AccommodationState {}

class HotelSearchLoaded extends AccommodationState {
  final List<Map<String, dynamic>> hotels;
  HotelSearchLoaded({required this.hotels});
}
