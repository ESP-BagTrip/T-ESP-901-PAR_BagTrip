import 'package:bagtrip/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'user-1',
          'email': 'alice@example.com',
          'fullName': 'Alice Smith',
          'phone': '+33612345678',
          'stripeCustomerId': 'cus_abc123',
          'isProfileCompleted': true,
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
          'plan': 'PREMIUM',
          'aiGenerationsRemaining': 5,
          'planExpiresAt': '2025-01-15T00:00:00.000',
        };

        final user = User.fromJson(json);

        expect(user.id, 'user-1');
        expect(user.email, 'alice@example.com');
        expect(user.fullName, 'Alice Smith');
        expect(user.phone, '+33612345678');
        expect(user.stripeCustomerId, 'cus_abc123');
        expect(user.isProfileCompleted, true);
        expect(user.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(user.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
        expect(user.plan, 'PREMIUM');
        expect(user.aiGenerationsRemaining, 5);
        expect(user.planExpiresAt, DateTime.parse('2025-01-15T00:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'user-2',
          'email': 'bob@example.com',
        };

        final user = User.fromJson(json);

        expect(user.id, 'user-2');
        expect(user.email, 'bob@example.com');
        expect(user.fullName, isNull);
        expect(user.phone, isNull);
        expect(user.stripeCustomerId, isNull);
        expect(user.isProfileCompleted, false);
        expect(user.createdAt, isNull);
        expect(user.updatedAt, isNull);
        expect(user.plan, 'FREE');
        expect(user.aiGenerationsRemaining, isNull);
        expect(user.planExpiresAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final user = User(
          id: 'user-3',
          email: 'carol@example.com',
          fullName: 'Carol Jones',
          phone: '+1234567890',
          stripeCustomerId: 'cus_xyz',
          isProfileCompleted: true,
          createdAt: DateTime.parse('2024-01-15T10:30:00.000'),
          updatedAt: DateTime.parse('2024-02-20T14:00:00.000'),
          plan: 'ADMIN',
          aiGenerationsRemaining: 100,
          planExpiresAt: DateTime.parse('2025-12-31T23:59:59.000'),
        );

        final json = user.toJson();
        final restored = User.fromJson(json);

        expect(restored, user);
      });

      test('serializes all keys', () {
        final user = const User(id: 'u1', email: 'test@test.com');

        final json = user.toJson();

        expect(json['id'], 'u1');
        expect(json['email'], 'test@test.com');
        expect(json['plan'], 'FREE');
        expect(json['isProfileCompleted'], false);
        expect(json.containsKey('fullName'), true);
        expect(json.containsKey('phone'), true);
      });
    });

    group('getters', () {
      test('isFree returns true when plan is FREE', () {
        final user = const User(id: '1', email: 'a@b.com');
        expect(user.isFree, true);
        expect(user.isPremium, false);
        expect(user.isAdmin, false);
      });

      test('isPremium returns true when plan is PREMIUM', () {
        final user = const User(id: '1', email: 'a@b.com', plan: 'PREMIUM');
        expect(user.isFree, false);
        expect(user.isPremium, true);
        expect(user.isAdmin, false);
      });

      test('isPremium returns true when plan is ADMIN', () {
        final user = const User(id: '1', email: 'a@b.com', plan: 'ADMIN');
        expect(user.isFree, false);
        expect(user.isPremium, true);
        expect(user.isAdmin, true);
      });

      test('isAdmin returns true only for ADMIN plan', () {
        final admin = const User(id: '1', email: 'a@b.com', plan: 'ADMIN');
        final premium = const User(id: '2', email: 'b@b.com', plan: 'PREMIUM');
        final free = const User(id: '3', email: 'c@b.com');

        expect(admin.isAdmin, true);
        expect(premium.isAdmin, false);
        expect(free.isAdmin, false);
      });
    });

    group('equality', () {
      test('two users with same fields are equal', () {
        final u1 = const User(id: '1', email: 'a@b.com');
        final u2 = const User(id: '1', email: 'a@b.com');
        expect(u1, u2);
      });

      test('two users with different fields are not equal', () {
        final u1 = const User(id: '1', email: 'a@b.com');
        final u2 = const User(id: '2', email: 'a@b.com');
        expect(u1, isNot(u2));
      });

      test('hashCode is consistent with equality', () {
        final u1 = const User(id: '1', email: 'a@b.com');
        final u2 = const User(id: '1', email: 'a@b.com');
        expect(u1.hashCode, u2.hashCode);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final user = const User(id: '1', email: 'old@test.com');
        final updated = user.copyWith(email: 'new@test.com', plan: 'PREMIUM');

        expect(updated.id, '1');
        expect(updated.email, 'new@test.com');
        expect(updated.plan, 'PREMIUM');
      });

      test('copies with no changes produces equal object', () {
        final user = const User(id: '1', email: 'a@b.com', fullName: 'Test');
        final copy = user.copyWith();
        expect(copy, user);
      });

      test('can set optional fields', () {
        final user = const User(id: '1', email: 'a@b.com');
        final updated = user.copyWith(
          fullName: 'John Doe',
          phone: '+33600000000',
          isProfileCompleted: true,
        );

        expect(updated.fullName, 'John Doe');
        expect(updated.phone, '+33600000000');
        expect(updated.isProfileCompleted, true);
      });
    });
  });
}
