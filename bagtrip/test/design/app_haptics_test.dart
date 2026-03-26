import 'package:bagtrip/design/app_haptics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppHaptics', () {
    // On CI (macOS/Linux), AdaptivePlatform.isIOS returns false,
    // so all methods execute the no-op path and should not throw.

    test('light() does not throw', () async {
      await expectLater(AppHaptics.light(), completes);
    });

    test('medium() does not throw', () async {
      await expectLater(AppHaptics.medium(), completes);
    });

    test('success() does not throw', () async {
      await expectLater(AppHaptics.success(), completes);
    });

    test('error() does not throw', () async {
      await expectLater(AppHaptics.error(), completes);
    });
  });
}
