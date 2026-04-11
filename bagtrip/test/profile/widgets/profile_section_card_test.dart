import 'package:bagtrip/profile/widgets/profile_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('ProfileSectionCard', () {
    testWidgets('renders without onTap', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 800,
          height: 400,
          child: ProfileSectionCard(child: Text('content')),
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileSectionCard), findsOneWidget);
    });

    testWidgets('renders with onTap handler', (tester) async {
      await pumpLocalized(
        tester,
        SizedBox(
          width: 800,
          height: 400,
          child: ProfileSectionCard(
            onTap: () {},
            child: const Text('tappable'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProfileSectionCard), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
