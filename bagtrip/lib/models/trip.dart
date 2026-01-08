enum TripStatus {
  draft,
  planning,
  booked,
  completed,
  cancelled;

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => TripStatus.draft,
    );
  }
}

class Trip {
  final String id;
  final String userId;
  final String? title;
  final String? originIata;
  final String? destinationIata;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Trip({
    required this.id,
    required this.userId,
    this.title,
    this.originIata,
    this.destinationIata,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      title: json['title'] as String?,
      originIata:
          json['originIata'] as String? ?? json['origin_iata'] as String?,
      destinationIata:
          json['destinationIata'] as String? ??
          json['destination_iata'] as String?,
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : json['start_date'] != null
              ? DateTime.parse(json['start_date'] as String)
              : null,
      endDate:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'] as String)
              : json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      status: TripStatus.fromString(json['status'] as String? ?? 'draft'),
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
      'userId': userId,
      'title': title,
      'originIata': originIata,
      'destinationIata': destinationIata,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
