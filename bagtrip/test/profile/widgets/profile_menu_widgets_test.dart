import 'package:bagtrip/profile/widgets/profile_delete_account_tile.dart';
import 'package:bagtrip/profile/widgets/profile_menu_group_card.dart';
import 'package:bagtrip/profile/widgets/profile_menu_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('ProfileMenuGroupCard', () {
    testWidgets('renders children with dividers between rows', (tester) async {
      await pumpLocalized(
        tester,
        ProfileMenuGroupCard(
          children: [
            ProfileMenuRow(
              icon: Icons.person_outline,
              title: 'Item 1',
              iconColor: Colors.teal,
              onTap: () {},
            ),
            ProfileMenuRow(
              icon: Icons.settings_outlined,
              title: 'Item 2',
              iconColor: Colors.grey,
              onTap: () {},
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('ProfileDeleteAccountTile', () {
    testWidgets('renders destructive labels and icon', (tester) async {
      var tapped = false;
      await pumpLocalized(
        tester,
        ProfileDeleteAccountTile(onTap: () => tapped = true),
      );
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Delete my account'), findsOneWidget);
      expect(find.text('Irreversible action'), findsOneWidget);

      await tester.tap(find.byType(ProfileDeleteAccountTile));
      expect(tapped, isTrue);
    });
  });
}
