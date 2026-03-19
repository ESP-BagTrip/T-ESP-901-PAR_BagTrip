import 'package:bagtrip/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'user-abc-456',
        'email': 'marie.dupont@example.com',
        'fullName': 'Marie Dupont',
        'phone': '+33612345678',
        'stripeCustomerId': 'cus_stripe_abc123',
        'isProfileCompleted': true,
        'createdAt': '2024-01-15T10:30:00.000',
        'updatedAt': '2024-06-20T16:45:00.000',
        'plan': 'PREMIUM',
        'aiGenerationsRemaining': 42,
        'planExpiresAt': '2025-01-15T23:59:59.000',
      };

      final first = User.fromJson(json);
      final serialized = first.toJson();
      final second = User.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'user-abc-456');
      expect(second.email, 'marie.dupont@example.com');
      expect(second.fullName, 'Marie Dupont');
      expect(second.phone, '+33612345678');
      expect(second.stripeCustomerId, 'cus_stripe_abc123');
      expect(second.isProfileCompleted, true);
      expect(second.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-06-20T16:45:00.000'));
      expect(second.plan, 'PREMIUM');
      expect(second.aiGenerationsRemaining, 42);
      expect(second.planExpiresAt, DateTime.parse('2025-01-15T23:59:59.000'));
    });

    test('roundtrip with minimal fields preserves defaults', () {
      final json = <String, dynamic>{
        'id': 'user-minimal',
        'email': 'minimal@test.com',
      };

      final first = User.fromJson(json);
      final serialized = first.toJson();
      final second = User.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'user-minimal');
      expect(second.email, 'minimal@test.com');
      expect(second.fullName, isNull);
      expect(second.phone, isNull);
      expect(second.stripeCustomerId, isNull);
      expect(second.isProfileCompleted, false);
      expect(second.plan, 'FREE');
      expect(second.aiGenerationsRemaining, isNull);
      expect(second.planExpiresAt, isNull);
    });

    test('roundtrip preserves each plan type', () {
      for (final plan in ['FREE', 'PREMIUM', 'ADMIN']) {
        final user = User(
          id: 'user-$plan',
          email: '$plan@test.com',
          plan: plan,
        );
        final json = user.toJson();
        final restored = User.fromJson(json);
        expect(
          restored.plan,
          plan,
          reason: 'Plan $plan should survive roundtrip',
        );
        expect(restored, user);
      }
    });

    test('roundtrip with all nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'user-nulls',
        'email': 'nulls@test.com',
        'fullName': null,
        'phone': null,
        'stripeCustomerId': null,
        'createdAt': null,
        'updatedAt': null,
        'aiGenerationsRemaining': null,
        'planExpiresAt': null,
      };

      final first = User.fromJson(json);
      final serialized = first.toJson();
      final second = User.fromJson(serialized);

      expect(second, first);
    });

    test('computed getters are consistent after roundtrip', () {
      final premiumUser = User.fromJson({
        'id': 'u1',
        'email': 'premium@test.com',
        'plan': 'PREMIUM',
      });
      final restored = User.fromJson(premiumUser.toJson());

      expect(restored.isFree, false);
      expect(restored.isPremium, true);
      expect(restored.isAdmin, false);

      final adminUser = User.fromJson({
        'id': 'u2',
        'email': 'admin@test.com',
        'plan': 'ADMIN',
      });
      final restoredAdmin = User.fromJson(adminUser.toJson());

      expect(restoredAdmin.isFree, false);
      expect(restoredAdmin.isPremium, true);
      expect(restoredAdmin.isAdmin, true);
    });
  });
}
