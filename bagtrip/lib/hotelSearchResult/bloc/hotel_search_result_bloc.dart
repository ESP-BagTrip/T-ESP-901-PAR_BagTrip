import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/hotelSearchResult/models/hotel.dart';
import 'package:bagtrip/service/hotel_client.dart';

part 'hotel_search_result_event.dart';
part 'hotel_search_result_state.dart';

class HotelSearchResultBloc extends Bloc<HotelSearchResultEvent, HotelSearchResultState> {
  
  // 1. Le BLoC a besoin du service pour appeler l'API
  final HotelService _hotelService;

  HotelSearchResultBloc({
    HotelService? hotelService,
  })  : _hotelService = hotelService ?? HotelService(),
        super(HotelSearchResultInitial()) {
    
    // 2. On enregistre : "Quand tu reçois LoadHotels, appelle _onLoadHotels"
    on<LoadHotels>(_onLoadHotels);
  }

  // 3. La méthode qui gère l'event LoadHotels
  Future<void> _onLoadHotels(
    LoadHotels event,        // L'event reçu (contient cityCode, checkIn, etc.)
    Emitter<HotelSearchResultState> emit,  // Pour émettre les states
  ) async {
    
    // 4. D'abord on émet Loading (affiche le spinner)
    emit(HotelSearchResultLoading());

    try {
      // 5. On appelle le service avec les données de l'event
      final hotels = await _hotelService.searchHotels(
        tripId: event.tripId,      // où trouver tripId ?
        cityCode: event.cityCode,    // où trouver cityCode ?
        checkIn: event.checkInDate,     // où trouver checkIn ?
        checkOut: event.checkOutDate,
        adults: event.adults,
        roomQty: event.roomsQty,
        currency: event.currency,
      );

      // 6. Succès ! On émet Loaded avec la liste d'hôtels
      emit(HotelSearchResultLoaded(
        cityCode: event.cityCode,
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
        adults: event.adults,
        roomsQty: event.roomsQty,
        currency: event.currency,
        hotels: hotels,
      ));

    } catch (e) {
      // 7. Erreur ! On émet Error avec le message
      emit(HotelSearchResultError(e.toString()));
    }
  }
}