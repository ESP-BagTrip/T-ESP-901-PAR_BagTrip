import 'package:bagtrip/models/user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Support both new (access_token) and legacy (token) formats
      final accessToken =
          json['access_token']?.toString() ?? json['token']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Missing required field: access_token or token');
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
        accessToken: accessToken,
        refreshToken: json['refresh_token']?.toString() ?? '',
        expiresIn: json['expires_in'] as int? ?? 3600,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
    } catch (e) {
      throw Exception(
        'Failed to parse AuthResponse: ${e.toString()}. JSON: $json',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}
