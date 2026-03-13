class TripShare {
  final String id;
  final String tripId;
  final String userId;
  final String role;
  final DateTime invitedAt;
  final String userEmail;
  final String? userFullName;

  TripShare({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    required this.userEmail,
    this.userFullName,
  });

  factory TripShare.fromJson(Map<String, dynamic> json) {
    return TripShare(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'VIEWER',
      invitedAt:
          json['invitedAt'] != null
              ? DateTime.parse(json['invitedAt'] as String)
              : json['invited_at'] != null
              ? DateTime.parse(json['invited_at'] as String)
              : DateTime.now(),
      userEmail:
          json['userEmail'] as String? ?? json['user_email'] as String? ?? '',
      userFullName:
          json['userFullName'] as String? ?? json['user_full_name'] as String?,
    );
  }
}
