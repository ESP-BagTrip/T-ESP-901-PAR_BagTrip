import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('ProfileHeaderCard', () {
    testWidgets('renders first name and initials from full name', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(name: 'Alice Doe', memberSince: '2024'),
        ),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('renders with single-part name', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(name: 'Alice', memberSince: '2023'),
        ),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders with empty name', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(name: '', memberSince: '2024'),
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
    });

    testWidgets('renders with multi-part name showing first name only', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(name: 'Bob Smith', memberSince: '2022'),
        ),
      );
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
