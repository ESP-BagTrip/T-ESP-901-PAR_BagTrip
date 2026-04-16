import 'package:bagtrip/profile/widgets/profile_header_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('ProfileHeaderCard', () {
    testWidgets('renders with full name (two parts)', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(
            name: 'Alice Doe',
            memberSince: '2024',
            onEditName: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
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
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
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

    testWidgets('renders without onEditName callback', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileHeaderCard(name: 'Bob Smith', memberSince: '2022'),
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
    });
  });
}
