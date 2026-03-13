part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoadFailure extends ProfileState {
  final String? message;

  ProfileLoadFailure({this.message});
}

/// Emitted when the user is not authenticated (missing or invalid token).
/// The view should redirect to /login.
final class ProfileUnauthenticated extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String memberSince;
  final List<PaymentCard> paymentCards;
  final String selectedTheme; // 'light', 'dark', 'system'
  final String selectedLanguage;
  final List<RecentBooking> recentBookings;
  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;

  ProfileLoaded({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.memberSince,
    required this.paymentCards,
    required this.selectedTheme,
    required this.selectedLanguage,
    required this.recentBookings,
    this.travelTypes = const [],
    this.travelStyle,
    this.budget,
    this.companions,
  });

  ProfileLoaded copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? memberSince,
    List<PaymentCard>? paymentCards,
    String? selectedTheme,
    String? selectedLanguage,
    List<RecentBooking>? recentBookings,
    List<String>? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
  }) {
    return ProfileLoaded(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      memberSince: memberSince ?? this.memberSince,
      paymentCards: paymentCards ?? this.paymentCards,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      recentBookings: recentBookings ?? this.recentBookings,
      travelTypes: travelTypes ?? this.travelTypes,
      travelStyle: travelStyle ?? this.travelStyle,
      budget: budget ?? this.budget,
      companions: companions ?? this.companions,
    );
  }
}

class PaymentCard {
  final String id;
  final String lastFourDigits;
  final String expiryDate;
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.lastFourDigits,
    required this.expiryDate,
    required this.isDefault,
  });
}

class RecentBooking {
  final String id;
  final String route;
  final String details;
  final String date;
  final String price;
  final String status;

  RecentBooking({
    required this.id,
    required this.route,
    required this.details,
    required this.date,
    required this.price,
    required this.status,
  });
}
