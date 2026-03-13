enum ActivityCategory {
  visit,
  restaurant,
  transport,
  leisure,
  other;

  static ActivityCategory fromString(String value) {
    final upper = value.toUpperCase();
    switch (upper) {
      case 'VISIT':
        return ActivityCategory.visit;
      case 'RESTAURANT':
        return ActivityCategory.restaurant;
      case 'TRANSPORT':
        return ActivityCategory.transport;
      case 'LEISURE':
        return ActivityCategory.leisure;
      default:
        return ActivityCategory.other;
    }
  }
}

class Activity {
  final String id;
  final String tripId;
  final String title;
  final String? description;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final ActivityCategory category;
  final double? estimatedCost;
  final bool isBooked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Activity({
    required this.id,
    required this.tripId,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.category = ActivityCategory.other,
    this.estimatedCost,
    this.isBooked = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      date:
          json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      startTime: json['startTime'] as String? ?? json['start_time'] as String?,
      endTime: json['endTime'] as String? ?? json['end_time'] as String?,
      location: json['location'] as String?,
      category: ActivityCategory.fromString(
        json['category'] as String? ?? 'OTHER',
      ),
      estimatedCost:
          (json['estimatedCost'] as num?)?.toDouble() ??
          (json['estimated_cost'] as num?)?.toDouble(),
      isBooked:
          json['isBooked'] as bool? ?? json['is_booked'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'category': category.name.toUpperCase(),
      'estimatedCost': estimatedCost,
      'isBooked': isBooked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
