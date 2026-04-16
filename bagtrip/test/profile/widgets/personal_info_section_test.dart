import 'package:bagtrip/profile/widgets/personal_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('PersonalInfoSection', () {
    testWidgets('renders with full user info and edit callbacks', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 600,
          child: PersonalInfoSection(
            name: 'Alice Doe',
            email: 'alice@example.com',
            phone: '+33 6 12 34 56 78',
            onEditName: () {},
            onEditPhone: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PersonalInfoSection), findsOneWidget);
    });

    testWidgets('renders without edit callbacks', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 600,
          child: PersonalInfoSection(
            name: 'Bob',
            email: 'bob@example.com',
            phone: '—',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PersonalInfoSection), findsOneWidget);
    });

    testWidgets('renders with empty values', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 600,
          child: PersonalInfoSection(name: '', email: '', phone: ''),
        ),
      );
      await tester.pump();
      expect(find.byType(PersonalInfoSection), findsOneWidget);
    });
  });
}
