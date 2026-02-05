// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
  }

  ProfileLoaded _currentState() {
    if (state is ProfileLoaded) {
      return state as ProfileLoaded;
    }
    // Return default state if not loaded yet
    return ProfileLoaded(
      name: 'Sophie Laurent',
      email: 'sophie.laurent@example.com',
      phone: '+33 6 12 34 56 78',
      address: 'Paris, France',
      memberSince: 'Janvier 2023',
      paymentCards: [],
      selectedTheme: 'light',
      selectedLanguage: 'Français',
      recentBookings: [],
    );
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    // Mock data for UI
    final mockCards = [
      PaymentCard(
        id: '1',
        lastFourDigits: '4242',
        expiryDate: '12/26',
        isDefault: true,
      ),
      PaymentCard(
        id: '2',
        lastFourDigits: '8888',
        expiryDate: '03/27',
        isDefault: false,
      ),
    ];

    final mockBookings = [
      RecentBooking(
        id: '1',
        route: 'Paris → Rome',
        details: 'Vol direct · Air France',
        date: '2 Sept 2026',
        price: '149,99 €',
        status: 'Confirmé',
      ),
      RecentBooking(
        id: '2',
        route: 'Rome → Paris',
        details: 'Vol direct · Air France',
        date: '9 Sept 2026',
        price: '149,99 €',
        status: 'Confirmé',
      ),
      RecentBooking(
        id: '3',
        route: 'Paris → New York',
        details: 'Vol direct · Delta Airlines',
        date: '15 Déc 2025',
        price: '789,99 €',
        status: 'Terminé',
      ),
    ];

    emit(
      ProfileLoaded(
        name: 'Sophie Laurent',
        email: 'sophie.laurent@example.com',
        phone: '+33 6 12 34 56 78',
        address: 'Paris, France',
        memberSince: 'Janvier 2023',
        paymentCards: mockCards,
        selectedTheme: 'light',
        selectedLanguage: 'Français',
        recentBookings: mockBookings,
      ),
    );
  }

  Future<void> _onUpdateTheme(
    UpdateTheme event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(selectedTheme: event.theme));
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguage event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(selectedLanguage: event.language));
  }

  Future<void> _onSetDefaultPaymentMethod(
    SetDefaultPaymentMethod event,
    Emitter<ProfileState> emit,
  ) async {
    final current = _currentState();
    final updatedCards =
        current.paymentCards.map((card) {
          return PaymentCard(
            id: card.id,
            lastFourDigits: card.lastFourDigits,
            expiryDate: card.expiryDate,
            isDefault: card.id == event.cardId,
          );
        }).toList();
    emit(current.copyWith(paymentCards: updatedCards));
  }
}
