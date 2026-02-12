import 'package:bagtrip/models/user.dart';

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['token'] == null) {
        throw Exception('Missing required field: token');
      }
      if (json['user'] == null) {
        throw Exception('Missing required field: user');
      }
      if (json['user'] is! Map<String, dynamic>) {
        throw Exception(
          'Invalid user field: expected Map, got ${json['user'].runtimeType}',
        );
      }

      return AuthResponse(
        token: json['token'].toString(),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception(
        'Failed to parse AuthResponse: ${e.toString()}. JSON: $json',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}
