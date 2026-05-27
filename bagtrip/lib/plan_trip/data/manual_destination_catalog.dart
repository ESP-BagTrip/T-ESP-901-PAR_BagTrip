import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:flutter/material.dart';

/// Wikimedia Commons thumbnail used for curated popular tiles (same sources as
/// the server cover pipeline). [fileName] is the Commons file title.
String manualPopularCoverImageUrl(String fileName) {
  return Uri(
    scheme: 'https',
    host: 'commons.wikimedia.org',
    path: '/wiki/Special:FilePath/${Uri.encodeComponent(fileName)}',
    queryParameters: const {'width': '640'},
  ).toString();
}

/// Fixed set of destinations for the plan-trip destination step (local search).
abstract final class ManualDestinationCatalog {
  static const List<LocationResult> all = [
    LocationResult(
      name: 'Paris',
      iataCode: 'PAR',
      city: 'Paris',
      countryCode: 'FR',
      countryName: 'France',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Barcelona',
      iataCode: 'BCN',
      city: 'Barcelona',
      countryCode: 'ES',
      countryName: 'Spain',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Amsterdam',
      iataCode: 'AMS',
      city: 'Amsterdam',
      countryCode: 'NL',
      countryName: 'Netherlands',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Marrakech',
      iataCode: 'RAK',
      city: 'Marrakech',
      countryCode: 'MA',
      countryName: 'Morocco',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Bali',
      iataCode: 'DPS',
      city: 'Denpasar',
      countryCode: 'ID',
      countryName: 'Indonesia',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Tokyo',
      iataCode: 'NRT',
      city: 'Tokyo',
      countryCode: 'JP',
      countryName: 'Japan',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'New York',
      iataCode: 'JFK',
      city: 'New York',
      countryCode: 'US',
      countryName: 'United States',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Lisbon',
      iataCode: 'LIS',
      city: 'Lisbon',
      countryCode: 'PT',
      countryName: 'Portugal',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Kyoto',
      iataCode: 'KIX',
      city: 'Kyoto',
      countryCode: 'JP',
      countryName: 'Japan',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'London',
      iataCode: 'LHR',
      city: 'London',
      countryCode: 'GB',
      countryName: 'United Kingdom',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Rome',
      iataCode: 'FCO',
      city: 'Rome',
      countryCode: 'IT',
      countryName: 'Italy',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Berlin',
      iataCode: 'BER',
      city: 'Berlin',
      countryCode: 'DE',
      countryName: 'Germany',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Dubrovnik',
      iataCode: 'DBV',
      city: 'Dubrovnik',
      countryCode: 'HR',
      countryName: 'Croatia',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Reykjavik',
      iataCode: 'KEF',
      city: 'Reykjavik',
      countryCode: 'IS',
      countryName: 'Iceland',
      subType: 'CITY',
    ),
    LocationResult(
      name: 'Singapore',
      iataCode: 'SIN',
      city: 'Singapore',
      countryCode: 'SG',
      countryName: 'Singapore',
      subType: 'CITY',
    ),
  ];

  /// Six featured tiles (subset of [all]) with cover imagery.
  static final List<ManualPopularDestination> popular = [
    ManualPopularDestination(
      location: const LocationResult(
        name: 'Marrakech',
        iataCode: 'RAK',
        city: 'Marrakech',
        countryCode: 'MA',
        countryName: 'Morocco',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl('Jemaa_el-Fnaa_at_night.jpg'),
      fallbackGradient: const [Color(0xFFE67E22), Color(0xFFC87E4A)],
    ),
    ManualPopularDestination(
      location: const LocationResult(
        name: 'Bali',
        iataCode: 'DPS',
        city: 'Denpasar',
        countryCode: 'ID',
        countryName: 'Indonesia',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl('Pura_Ulun_Danu_Bratan.jpg'),
      fallbackGradient: const [Color(0xFF1E8449), Color(0xFF145A32)],
    ),
    ManualPopularDestination(
      location: const LocationResult(
        name: 'Tokyo',
        iataCode: 'NRT',
        city: 'Tokyo',
        countryCode: 'JP',
        countryName: 'Japan',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl(
        'Skyscrapers_of_Shinjuku_2009_January.jpg',
      ),
      fallbackGradient: const [Color(0xFFE91E8C), Color(0xFF7B1FA2)],
    ),
    ManualPopularDestination(
      location: const LocationResult(
        name: 'New York',
        iataCode: 'JFK',
        city: 'New York',
        countryCode: 'US',
        countryName: 'United States',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl(
        'New_york_times_square-terabass.jpg',
      ),
      fallbackGradient: const [Color(0xFF5DADE2), Color(0xFF1A5276)],
    ),
    ManualPopularDestination(
      location: const LocationResult(
        name: 'Lisbon',
        iataCode: 'LIS',
        city: 'Lisbon',
        countryCode: 'PT',
        countryName: 'Portugal',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl('Lisboa_-_panoramio.jpg'),
      fallbackGradient: const [Color(0xFFF4D03F), Color(0xFFB7950B)],
    ),
    ManualPopularDestination(
      location: const LocationResult(
        name: 'Kyoto',
        iataCode: 'KIX',
        city: 'Kyoto',
        countryCode: 'JP',
        countryName: 'Japan',
        subType: 'CITY',
      ),
      imageUrl: manualPopularCoverImageUrl('Kiyomizu-dera_in_Kyoto.jpg'),
      fallbackGradient: const [Color(0xFFE57373), Color(0xFFC62828)],
    ),
  ];

  static List<LocationResult> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];
    bool matches(LocationResult loc) {
      final name = loc.name.toLowerCase();
      final country = loc.countryName.toLowerCase();
      final city = loc.city.toLowerCase();
      return name.contains(q) || country.contains(q) || city.contains(q);
    }

    return all.where(matches).toList();
  }
}

class ManualPopularDestination {
  const ManualPopularDestination({
    required this.location,
    required this.imageUrl,
    required this.fallbackGradient,
  });

  final LocationResult location;
  final String imageUrl;
  final List<Color> fallbackGradient;
}
