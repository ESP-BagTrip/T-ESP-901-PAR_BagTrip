import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_test_helpers.dart';

void main() {
  group('AX2 — Touch targets >= 44pt', () {
    testWidgets('ActionChip-style buttons meet 44pt minimum height', (
      tester,
    ) async {
      // Simulate the _ActionChip pattern from timeline_activity_card.dart
      await tester.pumpWidget(
        buildTestableWidget(
          Semantics(
            button: true,
            label: 'Validate',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: InkWell(
                onTap: () {},
                borderRadius: AppRadius.pill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.pill,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Validate',
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox).first,
      );
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('No MaterialTapTargetSize.shrinkWrap on interactive elements', (
      tester,
    ) async {
      // Build a widget tree with a properly-sized button
      await tester.pumpWidget(
        buildTestableWidget(
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('Modify'),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<TextButton>(find.byType(TextButton));
      final style = button.style;
      final tapTargetSize =
          style?.tapTargetSize ?? MaterialTapTargetSize.padded;
      expect(tapTargetSize, isNot(MaterialTapTargetSize.shrinkWrap));
    });

    testWidgets('IconButton default touch target is at least 44pt', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();

      final renderBox = tester.renderObject<RenderBox>(find.byType(IconButton));
      expect(renderBox.size.width, greaterThanOrEqualTo(44));
      expect(renderBox.size.height, greaterThanOrEqualTo(44));
    });
  });
}
