import 'package:bagtrip/components/bottom_tab_bar.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: BottomTabBar(
            activeTab: activeTab,
            onTabChanged: onTabChanged ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders 3 navigation destinations', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      final widget = tester.widget<NavigationBar>(navBar);
      expect(widget.destinations.length, 3);
    });

    testWidgets('renders correct icons for each tab', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.luggage_outlined), findsWidgets);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
    });

    testWidgets('selected index matches active tab', (tester) async {
      await tester.pumpWidget(buildSubject(activeTab: NavigationTab.planifier));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('selected index is 1 for trips tab', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });

    testWidgets('selected index is 2 for profile tab', (tester) async {
      await tester.pumpWidget(buildSubject(activeTab: NavigationTab.profile));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('onDestinationSelected triggers onTabChanged', (tester) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(onTabChanged: (tab) => tappedTab = tab),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navBar.onDestinationSelected?.call(0);

      expect(tappedTab, NavigationTab.planifier);
    });

    testWidgets('onDestinationSelected fires profile for index 2', (
      tester,
    ) async {
      NavigationTab? tappedTab;

      await tester.pumpWidget(
        buildSubject(onTabChanged: (tab) => tappedTab = tab),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      navBar.onDestinationSelected?.call(2);

      expect(tappedTab, NavigationTab.profile);
    });
  });
}
