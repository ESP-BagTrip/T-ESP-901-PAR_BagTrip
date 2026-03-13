class BaggageItem {
  final String id;
  final String tripId;
  final String name;
  final int? quantity;
  final bool isPacked;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BaggageItem({
    required this.id,
    required this.tripId,
    required this.name,
    this.quantity,
    this.isPacked = false,
    this.category,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory BaggageItem.fromJson(Map<String, dynamic> json) {
    return BaggageItem(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int?,
      isPacked:
          json['isPacked'] as bool? ?? json['is_packed'] as bool? ?? false,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
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
      'name': name,
      'quantity': quantity,
      'isPacked': isPacked,
      'category': category,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
