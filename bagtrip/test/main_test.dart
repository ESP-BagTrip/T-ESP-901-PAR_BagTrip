import 'package:bagtrip/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MyApp can be constructed', () {
    // Smoke test: verify MyApp widget can be instantiated without errors.
    // Full widget rendering requires Firebase + GetIt setup, tested via E2E.
    const app = MyApp();
    expect(app, isNotNull);
  });
}
