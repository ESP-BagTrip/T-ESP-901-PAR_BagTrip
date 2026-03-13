import 'package:bagtrip/models/trip.dart';

class TripHomeStats {
  final int baggageCount;
  final double totalExpenses;
  final int nbTravelers;
  final int? daysUntilTrip;
  final int? tripDuration;

  TripHomeStats({
    required this.baggageCount,
    required this.totalExpenses,
    required this.nbTravelers,
    this.daysUntilTrip,
    this.tripDuration,
  });

  factory TripHomeStats.fromJson(Map<String, dynamic> json) {
    return TripHomeStats(
      baggageCount: json['baggageCount'] as int? ?? 0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      nbTravelers: json['nbTravelers'] as int? ?? 1,
      daysUntilTrip: json['daysUntilTrip'] as int?,
      tripDuration: json['tripDuration'] as int?,
    );
  }
}

class TripFeatureTile {
  final String id;
  final String label;
  final String icon;
  final String route;
  final bool enabled;

  TripFeatureTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.enabled,
  });

  factory TripFeatureTile.fromJson(Map<String, dynamic> json) {
    return TripFeatureTile(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
      route: json['route'] as String,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}

class TripHome {
  final Trip trip;
  final TripHomeStats stats;
  final List<TripFeatureTile> features;

  TripHome({required this.trip, required this.stats, required this.features});

  factory TripHome.fromJson(Map<String, dynamic> json) {
    return TripHome(
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
      stats: TripHomeStats.fromJson(json['stats'] as Map<String, dynamic>),
      features:
          (json['features'] as List<dynamic>)
              .map((e) => TripFeatureTile.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
