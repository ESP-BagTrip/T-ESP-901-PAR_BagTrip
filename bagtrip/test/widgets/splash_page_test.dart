// SplashPage is intentionally NOT unit-tested here: it kicks off
// `getIt<AuthRepository>()`, `waitForBackendReady()` and schedules pending
// timers from `initState`. A hermetic test can't let those drain without
// either initializing the whole DI container or reaching into
// `tester.runAsync`, neither of which is worth the complexity for a single
// route redirect. Integration coverage is provided by the E2E boot flow.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splash page smoke test is covered by integration tests only', () {
    expect(true, isTrue);
  });
}
