class User {
  final String id;
  final String email;
  final String createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
