@Tags(['golden'])
library;

import 'package:bagtrip/design/widgets/status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  group('StatusBadge goldens', () {
    for (final type in StatusType.values) {
      testWidgets('${type.name} variant', (tester) async {
        await setGoldenSize(tester);
        await tester.pumpWidget(goldenWrapper(StatusBadge(type: type)));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(StatusBadge),
          matchesGoldenFile('goldens/status_badge_${type.name}.png'),
        );
      });
    }
  });
}
