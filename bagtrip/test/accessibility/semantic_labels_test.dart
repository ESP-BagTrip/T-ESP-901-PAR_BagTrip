import 'dart:ui' show SemanticsFlag;

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/optimized_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_test_helpers.dart';

void main() {
  group('AX1 — Semantic labels', () {
    testWidgets(
      'OptimizedImage has SemanticsFlag.isImage when label provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const OptimizedImage.tripCover(
              'https://example.com/image.jpg',
              semanticLabel: 'Cover photo of Paris',
            ),
          ),
        );
        await tester.pump();

        final semantics = tester.getSemantics(find.byType(OptimizedImage));
        expect(semantics.label, contains('Cover photo of Paris'));
        // ignore: deprecated_member_use
        expect(semantics.hasFlag(SemanticsFlag.isImage), isTrue);
      },
    );

    testWidgets('OptimizedImage has empty label when no semanticLabel', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const OptimizedImage.activityImage('https://example.com/image.jpg'),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(OptimizedImage));
      expect(semantics.label, '');
      // ignore: deprecated_member_use
      expect(semantics.hasFlag(SemanticsFlag.isImage), isTrue);
    });

    testWidgets('ElegantEmptyState uses MergeSemantics', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ElegantEmptyState(
            icon: Icons.event_outlined,
            title: 'No activities',
            subtitle: 'Add some activities',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MergeSemantics), findsOneWidget);
    });

    testWidgets('ElegantEmptyState halo is excluded from semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ElegantEmptyState(
            icon: Icons.event_outlined,
            title: 'No activities',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At least one ExcludeSemantics from ElegantEmptyState's halo
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });
  });
}
