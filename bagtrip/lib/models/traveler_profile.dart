class TravelerProfile {
  final String id;
  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelerProfile({
    required this.id,
    required this.travelTypes,
    this.travelStyle,
    this.budget,
    this.companions,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelerProfile.fromJson(Map<String, dynamic> json) {
    return TravelerProfile(
      id: json['id']?.toString() ?? '',
      travelTypes:
          (json['travelTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      travelStyle: json['travelStyle'] as String?,
      budget: json['budget'] as String?,
      companions: json['companions'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travelTypes': travelTypes,
      'travelStyle': travelStyle,
      'budget': budget,
      'companions': companions,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ProfileCompletion {
  final bool isCompleted;
  final List<String> missingFields;

  ProfileCompletion({required this.isCompleted, required this.missingFields});

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) {
    return ProfileCompletion(
      isCompleted: json['isCompleted'] as bool? ?? false,
      missingFields:
          (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
