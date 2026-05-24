import 'package:bagtrip/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.fromApi', () {
    test('maps known backend values', () {
      expect(UserRole.fromApi('OWNER'), UserRole.owner);
      expect(UserRole.fromApi('EDITOR'), UserRole.editor);
      expect(UserRole.fromApi('VIEWER'), UserRole.viewer);
    });

    test('null resolves to owner (API omits role for owned trips)', () {
      expect(UserRole.fromApi(null), UserRole.owner);
    });

    test('unknown value fails safe to the least-privileged viewer', () {
      expect(UserRole.fromApi('SUPER_ADMIN'), UserRole.viewer);
      expect(UserRole.fromApi(''), UserRole.viewer);
    });

    test('apiValue round-trips through fromApi', () {
      for (final r in UserRole.values) {
        expect(UserRole.fromApi(r.apiValue), r);
      }
    });
  });
}
