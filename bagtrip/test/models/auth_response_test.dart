import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponse', () {
    final testUser = const User(
      id: 'user-1',
      email: 'alice@example.com',
      fullName: 'Alice Smith',
    );

    final fullJson = <String, dynamic>{
      'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
      'refresh_token': 'refresh_abc123',
      'expires_in': 7200,
      'user': {
        'id': 'user-1',
        'email': 'alice@example.com',
        'fullName': 'Alice Smith',
        'plan': 'FREE',
      },
    };

    group('fromJson', () {
      test('parses all fields with snake_case keys', () {
        final response = AuthResponse.fromJson(fullJson);

        expect(
          response.accessToken,
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        );
        expect(response.refreshToken, 'refresh_abc123');
        expect(response.expiresIn, 7200);
        expect(response.user.id, 'user-1');
        expect(response.user.email, 'alice@example.com');
        expect(response.user.fullName, 'Alice Smith');
      });

      test('applies defaults when optional fields are missing', () {
        final json = <String, dynamic>{
          'access_token': 'token123',
          'user': {'id': 'user-2', 'email': 'bob@example.com'},
        };

        final response = AuthResponse.fromJson(json);

        expect(response.accessToken, 'token123');
        expect(response.refreshToken, '');
        expect(response.expiresIn, 3600);
        expect(response.user.id, 'user-2');
        expect(response.user.email, 'bob@example.com');
      });

      test('parses nested user correctly', () {
        final json = <String, dynamic>{
          'access_token': 'tok',
          'user': {
            'id': 'u1',
            'email': 'nested@test.com',
            'fullName': 'Nested User',
            'phone': '+33612345678',
            'isProfileCompleted': true,
            'plan': 'PREMIUM',
            'aiGenerationsRemaining': 10,
          },
        };

        final response = AuthResponse.fromJson(json);

        expect(response.user.fullName, 'Nested User');
        expect(response.user.phone, '+33612345678');
        expect(response.user.isProfileCompleted, true);
        expect(response.user.plan, 'PREMIUM');
        expect(response.user.aiGenerationsRemaining, 10);
      });
    });

    group('toJson', () {
      test('produces snake_case keys', () {
        final response = AuthResponse(
          accessToken: 'my_token',
          refreshToken: 'my_refresh',
          expiresIn: 1800,
          user: testUser,
        );

        final json = response.toJson();

        expect(json.containsKey('access_token'), true);
        expect(json.containsKey('refresh_token'), true);
        expect(json.containsKey('expires_in'), true);
        expect(json['access_token'], 'my_token');
        expect(json['refresh_token'], 'my_refresh');
        expect(json['expires_in'], 1800);

        // Should not contain camelCase keys
        expect(json.containsKey('accessToken'), false);
        expect(json.containsKey('refreshToken'), false);
        expect(json.containsKey('expiresIn'), false);
      });

      test('serializes nested user', () {
        final response = AuthResponse(accessToken: 'tok', user: testUser);

        final json = response.toJson();

        expect(json['user'], isA<Map<String, dynamic>>());
        expect(json['user']['id'], 'user-1');
        expect(json['user']['email'], 'alice@example.com');
      });

      test('roundtrip produces equal object', () {
        final response = AuthResponse(
          accessToken: 'access_123',
          refreshToken: 'refresh_456',
          user: testUser,
        );

        final json = response.toJson();
        final restored = AuthResponse.fromJson(json);

        expect(restored, response);
      });

      test('roundtrip with defaults', () {
        final response = const AuthResponse(
          accessToken: 'tok',
          user: User(id: 'u1', email: 'a@b.com'),
        );

        final json = response.toJson();
        final restored = AuthResponse.fromJson(json);

        expect(restored, response);
        expect(restored.refreshToken, '');
        expect(restored.expiresIn, 3600);
      });
    });

    group('equality', () {
      test('two responses with same fields are equal', () {
        final r1 = AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          user: testUser,
        );
        final r2 = AuthResponse(
          accessToken: 'tok',
          refreshToken: 'ref',
          user: testUser,
        );
        expect(r1, r2);
      });

      test('two responses with different tokens are not equal', () {
        final r1 = AuthResponse(accessToken: 'tok1', user: testUser);
        final r2 = AuthResponse(accessToken: 'tok2', user: testUser);
        expect(r1, isNot(r2));
      });

      test('two responses with different users are not equal', () {
        final r1 = const AuthResponse(
          accessToken: 'tok',
          user: User(id: 'u1', email: 'a@b.com'),
        );
        final r2 = const AuthResponse(
          accessToken: 'tok',
          user: User(id: 'u2', email: 'b@b.com'),
        );
        expect(r1, isNot(r2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final response = AuthResponse(
          accessToken: 'old_token',
          refreshToken: 'old_refresh',
          user: testUser,
        );
        final updated = response.copyWith(
          accessToken: 'new_token',
          expiresIn: 7200,
        );

        expect(updated.accessToken, 'new_token');
        expect(updated.refreshToken, 'old_refresh');
        expect(updated.expiresIn, 7200);
        expect(updated.user, testUser);
      });

      test('copies with no changes produces equal object', () {
        final response = AuthResponse(accessToken: 'tok', user: testUser);
        final copy = response.copyWith();
        expect(copy, response);
      });
    });
  });
}
