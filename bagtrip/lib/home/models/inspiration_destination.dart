import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class InspirationDestination {
  final String name;
  final String country;
  final String flag;
  final String iataCode;
  final List<Color> gradient;

  const InspirationDestination({
    required this.name,
    required this.country,
    required this.flag,
    required this.iataCode,
    required this.gradient,
  });

  static const List<InspirationDestination> all = [
    InspirationDestination(
      name: 'Tokyo',
      country: 'Japan',
      flag: '\u{1F1EF}\u{1F1F5}',
      iataCode: 'TYO',
      gradient: [ColorName.primary, PersonalizationColors.accentBlue],
    ),
    InspirationDestination(
      name: 'Barcelona',
      country: 'Spain',
      flag: '\u{1F1EA}\u{1F1F8}',
      iataCode: 'BCN',
      gradient: [ColorName.secondary, Color(0xFF2BC4B4)],
    ),
    InspirationDestination(
      name: 'Marrakech',
      country: 'Morocco',
      flag: '\u{1F1F2}\u{1F1E6}',
      iataCode: 'RAK',
      gradient: [Color(0xFFE67E22), Color(0xFFF39C12)],
    ),
    InspirationDestination(
      name: 'Bali',
      country: 'Indonesia',
      flag: '\u{1F1EE}\u{1F1E9}',
      iataCode: 'DPS',
      gradient: [Color(0xFF27AE60), ColorName.secondary],
    ),
    InspirationDestination(
      name: 'New York',
      country: 'USA',
      flag: '\u{1F1FA}\u{1F1F8}',
      iataCode: 'NYC',
      gradient: [PersonalizationColors.accentViolet, ColorName.primary],
    ),
    InspirationDestination(
      name: 'Santorini',
      country: 'Greece',
      flag: '\u{1F1EC}\u{1F1F7}',
      iataCode: 'JTR',
      gradient: [PersonalizationColors.accentBlue, Color(0xFF3498DB)],
    ),
  ];
}
