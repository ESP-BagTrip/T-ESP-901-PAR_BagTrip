import 'package:bagtrip/design/widgets/review/activity_panel_card.dart';
import 'package:bagtrip/design/widgets/item_status_chip.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows secondary left accent when validated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityPanelCard(
            title: 'Musée',
            description: '',
            categoryLabel: 'CULTURE',
            validationStatus: ValidationStatus.validated,
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ActivityPanelCard),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == ColorName.secondary,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides left accent when not validated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityPanelCard(
            title: 'Musée',
            description: '',
            categoryLabel: 'CULTURE',
            validationStatus: ValidationStatus.suggested,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == ColorName.secondary,
      ),
      findsNothing,
    );
  });

  testWidgets('renders title, description and meta without status chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityPanelCard(
            title: 'Musée du Louvre',
            description: 'Visite guidée\nDeuxième ligne\nTroisième ligne',
            categoryLabel: 'CULTURE',
            timeLabel: '10:00 — 12:00',
            location: 'Paris',
          ),
        ),
      ),
    );

    expect(find.text('Musée du Louvre'), findsOneWidget);
    expect(find.textContaining('Visite guidée'), findsOneWidget);
    expect(find.textContaining('10:00'), findsOneWidget);
    expect(find.textContaining('Paris'), findsOneWidget);
    expect(find.byType(ItemStatusChip), findsNothing);
  });
}
