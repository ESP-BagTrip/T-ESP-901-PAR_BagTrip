enum BudgetCategory {
  flight,
  accommodation,
  food,
  activity,
  transport,
  other;

  static BudgetCategory fromString(String value) {
    final upper = value.toUpperCase();
    switch (upper) {
      case 'FLIGHT':
        return BudgetCategory.flight;
      case 'ACCOMMODATION':
        return BudgetCategory.accommodation;
      case 'FOOD':
        return BudgetCategory.food;
      case 'ACTIVITY':
        return BudgetCategory.activity;
      case 'TRANSPORT':
        return BudgetCategory.transport;
      default:
        return BudgetCategory.other;
    }
  }
}

class BudgetItem {
  final String id;
  final String tripId;
  final String label;
  final double amount;
  final BudgetCategory category;
  final DateTime? date;
  final bool isPlanned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BudgetItem({
    required this.id,
    required this.tripId,
    required this.label,
    required this.amount,
    this.category = BudgetCategory.other,
    this.date,
    this.isPlanned = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: BudgetCategory.fromString(
        json['category'] as String? ?? 'OTHER',
      ),
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      isPlanned:
          json['isPlanned'] as bool? ?? json['is_planned'] as bool? ?? true,
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
      'label': label,
      'amount': amount,
      'category': category.name.toUpperCase(),
      'date': date?.toIso8601String().split('T')[0],
      'isPlanned': isPlanned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final Map<String, double> byCategory;
  final double? percentConsumed;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.byCategory,
    this.percentConsumed,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      totalBudget:
          (json['totalBudget'] as num?)?.toDouble() ??
          (json['total_budget'] as num?)?.toDouble() ??
          0,
      totalSpent:
          (json['totalSpent'] as num?)?.toDouble() ??
          (json['total_spent'] as num?)?.toDouble() ??
          0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      byCategory: Map<String, double>.from(
        ((json['byCategory'] ?? json['by_category'] ?? {}) as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      percentConsumed:
          (json['percentConsumed'] as num?)?.toDouble() ??
          (json['percent_consumed'] as num?)?.toDouble(),
    );
  }
}
