// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    AuthRepository? authRepository,
    BookingRepository? bookingRepository,
    ProfileRepository? profileRepository,
  }) : _authRepository = authRepository ?? getIt<AuthRepository>(),
       _bookingRepository = bookingRepository ?? getIt<BookingRepository>(),
       _profileRepository = profileRepository ?? getIt<ProfileRepository>(),
       super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<ResetProfile>(_onResetProfile);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<SetDefaultPaymentMethod>(_onSetDefaultPaymentMethod);
  }

  final AuthRepository _authRepository;
  final BookingRepository _bookingRepository;
  final ProfileRepository _profileRepository;

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
    final previousTheme = current is ProfileLoaded
        ? current.selectedTheme
        : _defaultTheme;
    final previousLanguage = current is ProfileLoaded
        ? current.selectedLanguage
        : _defaultLanguage;

    final userResult = await _authRepository.getCurrentUser();
    switch (userResult) {
      case Success(:final data):
        final user = data;
        if (user == null) {
          await _authRepository.logout();
          emit(ProfileUnauthenticated());
          return;
        }

        List<RecentBooking> recentBookings = [];
        final bookingsResult = await _bookingRepository.listBookings();
        if (bookingsResult is Success<List<BookingResponse>>) {
          recentBookings = bookingsResult.data
              .map(_mapBookingToRecentBooking)
              .toList();
        }

        List<String> travelTypes = [];
        String? travelStyle;
        String? budget;
        String? companions;
        final profileResult = await _profileRepository.getProfile();
        if (profileResult is Success) {
          final travelerProfile = (profileResult as Success).data;
          travelTypes = travelerProfile.travelTypes;
          travelStyle = travelerProfile.travelStyle;
          budget = travelerProfile.budget;
          companions = travelerProfile.companions;
        }

        final memberSince = DateFormat.yMMM(
          'fr',
        ).format(user.createdAt ?? DateTime.now());

        emit(
          ProfileLoaded(
            name: user.fullName?.trim().isNotEmpty == true
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
      case Failure(:final error):
        if (error is AuthenticationError) {
          await _authRepository.logout();
          emit(ProfileUnauthenticated());
        } else {
          emit(ProfileLoadFailure(message: toUserFriendlyMessage(error)));
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
      date: DateFormat(
        'd MMM yyyy',
        'fr',
      ).format(b.createdAt ?? DateTime.now()),
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
    final updatedCards = current.paymentCards.map((card) {
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
