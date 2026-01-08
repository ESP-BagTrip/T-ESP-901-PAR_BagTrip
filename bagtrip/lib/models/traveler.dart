class Traveler {
  final String id;
  final String tripId;
  final String? amadeusTravelerRef;
  final String travelerType;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<Map<String, dynamic>>? documents;
  final Map<String, dynamic>? contacts;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Traveler({
    required this.id,
    required this.tripId,
    this.amadeusTravelerRef,
    required this.travelerType,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.documents,
    this.contacts,
    required this.createdAt,
    this.updatedAt,
  });

  factory Traveler.fromJson(Map<String, dynamic> json) {
    return Traveler(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      amadeusTravelerRef:
          json['amadeusTravelerRef'] as String? ??
          json['amadeus_traveler_ref'] as String?,
      travelerType:
          json['travelerType'] as String? ??
          json['traveler_type'] as String? ??
          'ADULT',
      firstName:
          json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName:
          json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.parse(json['dateOfBirth'] as String)
              : json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null,
      gender: json['gender'] as String?,
      documents:
          json['documents'] != null
              ? List<Map<String, dynamic>>.from(
                (json['documents'] as List).map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ),
              )
              : null,
      contacts:
          json['contacts'] != null
              ? Map<String, dynamic>.from(json['contacts'] as Map)
              : null,
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
      'amadeusTravelerRef': amadeusTravelerRef,
      'travelerType': travelerType,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'documents': documents,
      'contacts': contacts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
