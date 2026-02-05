part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoadFailure extends ProfileState {
  final String? message;

  ProfileLoadFailure({this.message});
}

/// Émis quand l'utilisateur n'est pas authentifié (token absent/invalide).
/// La vue doit rediriger vers /login.
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
