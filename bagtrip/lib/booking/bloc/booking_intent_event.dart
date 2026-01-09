part of 'booking_intent_bloc.dart';

sealed class BookingIntentEvent extends Equatable {
  const BookingIntentEvent();

  @override
  List<Object?> get props => [];
}

class CreateBookingIntent extends BookingIntentEvent {
  final String tripId;
  final BookingIntentType type;
  final String? flightOfferId;
  final String? hotelOfferId;

  const CreateBookingIntent({
    required this.tripId,
    required this.type,
    this.flightOfferId,
    this.hotelOfferId,
  });

  @override
  List<Object?> get props => [tripId, type, flightOfferId, hotelOfferId];
}

class GetBookingIntent extends BookingIntentEvent {
  final String intentId;

  const GetBookingIntent({required this.intentId});

  @override
  List<Object?> get props => [intentId];
}

class BookFlight extends BookingIntentEvent {
  final String intentId;
  final List<String> travelerIds;
  final List<Map<String, dynamic>> contacts;

  const BookFlight({
    required this.intentId,
    required this.travelerIds,
    required this.contacts,
  });

  @override
  List<Object?> get props => [intentId, travelerIds, contacts];
}
