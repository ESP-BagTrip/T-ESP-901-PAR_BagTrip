class TripFeedback {
  final String id;
  final String tripId;
  final String userId;
  final int overallRating;
  final String? highlights;
  final String? lowlights;
  final bool wouldRecommend;
  final DateTime createdAt;

  TripFeedback({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.overallRating,
    this.highlights,
    this.lowlights,
    required this.wouldRecommend,
    required this.createdAt,
  });

  factory TripFeedback.fromJson(Map<String, dynamic> json) {
    return TripFeedback(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      overallRating:
          json['overallRating'] as int? ?? json['overall_rating'] as int? ?? 0,
      highlights: json['highlights'] as String?,
      lowlights: json['lowlights'] as String?,
      wouldRecommend:
          json['wouldRecommend'] as bool? ??
          json['would_recommend'] as bool? ??
          false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallRating': overallRating,
      'highlights': highlights,
      'lowlights': lowlights,
      'wouldRecommend': wouldRecommend,
    };
  }
}
