import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomTabBar', () {
    Widget buildSubject({
      NavigationTab activeTab = NavigationTab.trips,
      ValueChanged<NavigationTab>? onTabChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: BottomTabBar(
            activeTab: activeTab,
            onTabChanged: onTabChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders 3 tabs with correct labels', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Nouveau'), findsOneWidget);
      expect(find.text('Voyages'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('renders correct icons for each tab', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.luggage_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
    });

    testWidgets('highlights active tab with bold font weight', (tester) async {
      await tester.pumpWidget(buildSubject());

      final voyagesText = tester.widget<Text>(find.text('Voyages'));
      expect(voyagesText.style?.fontWeight, FontWeight.w600);

      // Non-active tabs should have w500
      final nouveauText = tester.widget<Text>(find.text('Nouveau'));
      expect(nouveauText.style?.fontWeight, FontWeight.w500);

      final profilText = tester.widget<Text>(find.text('Profil'));
      expect(profilText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('highlights planifier tab when it is active', (tester) async {
      await tester.pumpWidget(buildSubject(activeTab: NavigationTab.planifier));

      final nouveauText = tester.widget<Text>(find.text('Nouveau'));
      expect(nouveauText.style?.fontWeight, FontWeight.w600);

      final voyagesText = tester.widget<Text>(find.text('Voyages'));
      expect(voyagesText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets(
      'onTabChanged callback fires with NavigationTab.planifier on tap',
      (tester) async {
        NavigationTab? tappedTab;

        await tester.pumpWidget(
          buildSubject(onTabChanged: (tab) => tappedTab = tab),
        );

        await tester.tap(find.text('Nouveau'));
        await tester.pump();

        expect(tappedTab, NavigationTab.planifier);
      },
    );

    testWidgets(
      'onTabChanged callback fires with NavigationTab.profile on tap',
      (tester) async {
        NavigationTab? tappedTab;

        await tester.pumpWidget(
          buildSubject(onTabChanged: (tab) => tappedTab = tab),
        );

        await tester.tap(find.text('Profil'));
        await tester.pump();

        expect(tappedTab, NavigationTab.profile);
      },
    );

    testWidgets('onTabChanged callback fires with NavigationTab.trips on tap', (
      tester,
    ) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(
          activeTab: NavigationTab.planifier,
          onTabChanged: (tab) => tappedTab = tab,
        ),
      );

      await tester.tap(find.text('Voyages'));
      await tester.pump();

      expect(tappedTab, NavigationTab.trips);
    });
  });
}
