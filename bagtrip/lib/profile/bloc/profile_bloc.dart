// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/booking_service.dart';
import 'package:bagtrip/service/profile_api_service.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    AuthService? authService,
    BookingService? bookingService,
    ProfileApiService? profileApiService,
  }) : _authService = authService ?? getIt<AuthService>(),
       _bookingService = bookingService ?? getIt<BookingService>(),
       _profileApiService = profileApiService ?? getIt<ProfileApiService>(),
       super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<ResetProfile>(_onResetProfile);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
  }

  final AuthService _authService;
  final BookingService _bookingService;
  final ProfileApiService _profileApiService;

  static const String _defaultTheme = 'light';
  static const String _defaultLanguage = 'Français';

  ProfileLoaded _currentState() {
    if (state is ProfileLoaded) {
      return state as ProfileLoaded;
    }
    return ProfileLoaded(
      name: '',
      email: '',
      phone: '',
      address: '',
      memberSince: '',
      paymentCards: [],
      selectedTheme: _defaultTheme,
      selectedLanguage: _defaultLanguage,
      recentBookings: [],
    );
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    final previousTheme =
        current is ProfileLoaded ? current.selectedTheme : _defaultTheme;
    final previousLanguage =
        current is ProfileLoaded ? current.selectedLanguage : _defaultLanguage;

    try {
      final User? user = await _authService.getCurrentUser();
      if (user == null) {
        await _authService.logout();
        emit(ProfileUnauthenticated());
        return;
      }

      List<RecentBooking> recentBookings = [];
      try {
        final bookings = await _bookingService.listBookings();
        recentBookings = bookings.map(_mapBookingToRecentBooking).toList();
      } catch (_) {
        // Keep empty list on booking list failure; profile still shows user
      }

      List<String> travelTypes = [];
      String? travelStyle;
      String? budget;
      String? companions;
      try {
        final travelerProfile = await _profileApiService.getProfile();
        travelTypes = travelerProfile.travelTypes;
        travelStyle = travelerProfile.travelStyle;
        budget = travelerProfile.budget;
        companions = travelerProfile.companions;
      } catch (_) {
        // Keep defaults on profile fetch failure; profile still shows user
      }

      final memberSince = DateFormat.yMMM('fr').format(user.createdAt);

      emit(
        ProfileLoaded(
          name:
              user.fullName?.trim().isNotEmpty == true
                  ? user.fullName!
                  : user.email,
          email: user.email,
          phone: user.phone?.trim().isNotEmpty == true ? user.phone! : '—',
          address: '—',
          memberSince: memberSince,
          paymentCards: [],
          selectedTheme: previousTheme,
          selectedLanguage: previousLanguage,
          recentBookings: recentBookings,
          travelTypes: travelTypes,
          travelStyle: travelStyle,
          budget: budget,
          companions: companions,
        ),
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') ||
          msg.contains('Non authentifié') ||
          msg.contains('Invalid') ||
          msg.contains('Unauthorized')) {
        await _authService.logout();
        emit(ProfileUnauthenticated());
      } else {
        emit(ProfileLoadFailure(message: msg));
      }
    }
  }

  void _onResetProfile(ResetProfile event, Emitter<ProfileState> emit) {
    emit(ProfileInitial());
  }

  RecentBooking _mapBookingToRecentBooking(BookingResponse b) {
    return RecentBooking(
      id: b.id,
      route: 'Réservation',
      details: b.status,
      date: DateFormat('d MMM yyyy', 'fr').format(b.createdAt),
      price:
          '${NumberFormat.decimalPattern('fr').format(b.priceTotal)} ${b.currency}',
      status: b.status,
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
