import 'package:bagtrip/baggage/widgets/baggage_progress_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('BaggageProgressHeader', () {
    testWidgets('renders with empty counts', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 200,
          child: BaggageProgressHeader(packedCount: 0, totalCount: 0),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageProgressHeader), findsOneWidget);
    });

    testWidgets('renders with 50% progress', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 200,
          child: BaggageProgressHeader(packedCount: 5, totalCount: 10),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageProgressHeader), findsOneWidget);
    });

    testWidgets('renders with 100% progress', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 200,
          child: BaggageProgressHeader(packedCount: 8, totalCount: 8),
        ),
      );
      await tester.pump();
      expect(find.byType(BaggageProgressHeader), findsOneWidget);
    });
  });
}
