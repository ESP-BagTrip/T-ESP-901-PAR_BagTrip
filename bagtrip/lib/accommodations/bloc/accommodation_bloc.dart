import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bloc/bloc.dart';

part 'accommodation_event.dart';
part 'accommodation_state.dart';

class AccommodationBloc extends Bloc<AccommodationEvent, AccommodationState> {
  final AccommodationRepository _repository;

  AccommodationBloc({AccommodationRepository? repository})
    : _repository = repository ?? getIt<AccommodationRepository>(),
      super(AccommodationInitial()) {
    on<LoadAccommodations>(_onLoad);
    on<CreateAccommodation>(_onCreate);
    on<UpdateAccommodation>(_onUpdate);
    on<DeleteAccommodation>(_onDelete);
    on<SuggestAccommodations>(_onSuggest);
    on<SearchHotels>(_onSearchHotels);
    on<SearchHotelOffers>(_onSearchHotelOffers);
    on<ClearHotelSearch>(_onClearHotelSearch);
  }

  Future<void> _onLoad(
    LoadAccommodations event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationLoading());
    final result = await _repository.getByTrip(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(AccommodationsLoaded(accommodations: data));
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onCreate(
    CreateAccommodation event,
    Emitter<AccommodationState> emit,
  ) async {
    final result = await _repository.createAccommodation(
      event.tripId,
      name: event.data['name'] as String,
      address: event.data['address'] as String?,
      checkIn: event.data['checkIn'] != null
          ? DateTime.tryParse(event.data['checkIn'] as String)
          : null,
      checkOut: event.data['checkOut'] != null
          ? DateTime.tryParse(event.data['checkOut'] as String)
          : null,
      pricePerNight: event.data['pricePerNight'] as double?,
      currency: event.data['currency'] as String?,
      bookingReference: event.data['bookingReference'] as String?,
      notes: event.data['notes'] as String?,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        if (current is AccommodationsLoaded) {
          emit(
            AccommodationsLoaded(
              accommodations: [...current.accommodations, data],
            ),
          );
        } else {
          add(LoadAccommodations(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onUpdate(
    UpdateAccommodation event,
    Emitter<AccommodationState> emit,
  ) async {
    final result = await _repository.updateAccommodation(
      event.tripId,
      event.accommodationId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        if (current is AccommodationsLoaded) {
          final updated = current.accommodations
              .map((a) => a.id == data.id ? data : a)
              .toList();
          emit(AccommodationsLoaded(accommodations: updated));
        } else {
          add(LoadAccommodations(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onDelete(
    DeleteAccommodation event,
    Emitter<AccommodationState> emit,
  ) async {
    final result = await _repository.deleteAccommodation(
      event.tripId,
      event.accommodationId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        final current = state;
        if (current is AccommodationsLoaded) {
          final updated = current.accommodations
              .where((a) => a.id != event.accommodationId)
              .toList();
          emit(AccommodationsLoaded(accommodations: updated));
        } else {
          add(LoadAccommodations(tripId: event.tripId));
        }
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onSuggest(
    SuggestAccommodations event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationSuggestionsLoading());
    final result = await _repository.suggestAccommodations(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(AccommodationSuggestionsLoaded(suggestions: data));
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(AccommodationQuotaExceeded());
        } else {
          emit(AccommodationError(error: error));
        }
    }
  }

  Future<void> _onSearchHotels(
    SearchHotels event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(HotelSearchLoading());
    final result = await _repository.searchHotelsByCity(
      event.cityCode,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      adults: event.adults,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(HotelSearchLoaded(hotels: data));
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onSearchHotelOffers(
    SearchHotelOffers event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(HotelSearchLoading());
    final result = await _repository.searchHotelOffers(
      event.hotelIds,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(HotelSearchLoaded(hotels: data));
      case Failure(:final error):
        emit(AccommodationError(error: error));
    }
  }

  Future<void> _onClearHotelSearch(
    ClearHotelSearch event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationInitial());
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
